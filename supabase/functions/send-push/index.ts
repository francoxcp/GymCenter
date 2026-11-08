// Edge Function: send-push
// Envía las notificaciones Web Push de la versión web (PWA):
//   • Recordatorio diario de entrenamiento a la hora elegida por el usuario.
//   • Aviso del reporte semanal los domingos a partir de las 9:00.
//   • Bandeja push_outbox: comentarios, entrenos terminados y vencimientos
//     de membresía (ver database/ux_feed_membership_migration.sql).
// La invoca pg_cron cada 15 minutos (ver database/web_pwa_migration.sql).
//
// No necesita secrets manuales: lee la configuración de la tabla
// public.push_config (cron_secret y claves VAPID). Si las claves VAPID no
// existen, las genera en la primera ejecución y las guarda ahí.
// SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY los inyecta Supabase.
// Opcional: VAPID_SUBJECT (mailto:...) como secret.
//
// Desplegar con verificación JWT DESACTIVADA (la protege cron_secret):
//   supabase functions deploy send-push --no-verify-jwt

import { createClient } from 'npm:@supabase/supabase-js@2';
import webpush from 'npm:web-push@3.6.7';

type Prefs = {
  user_id: string;
  notifications_enabled: boolean | null;
  workout_reminders: boolean | null;
  progress_reports: boolean | null;
  reminder_time: string | null;
  timezone: string | null;
  language: string | null;
  last_reminder_sent_on: string | null;
  last_report_sent_on: string | null;
};

type Sub = { id: string; user_id: string; endpoint: string; p256dh: string; auth: string };

const REMINDER_WINDOW_MIN = 60; // tolera retrasos del cron
const REPORT_HOUR = 9;

function localParts(timeZone: string, now: Date) {
  let tz = timeZone;
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: tz });
  } catch {
    tz = 'America/Costa_Rica';
  }
  const fmt = new Intl.DateTimeFormat('en-US', {
    timeZone: tz,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    weekday: 'short',
    hour12: false,
  });
  const parts = Object.fromEntries(fmt.formatToParts(now).map((p) => [p.type, p.value]));
  const hour = Number(parts.hour) % 24;
  return {
    date: `${parts.year}-${parts.month}-${parts.day}`,
    minutes: hour * 60 + Number(parts.minute),
    hour,
    isSunday: parts.weekday === 'Sun',
  };
}

function timeToMinutes(t: string | null): number {
  const [h, m] = (t ?? '18:00:00').split(':').map(Number);
  return (h || 0) * 60 + (m || 0);
}

Deno.serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    (Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SECRET_KEY'))!,
    { auth: { persistSession: false } },
  );

  const { data: cfg, error: cfgErr } = await supabase
    .from('push_config')
    .select('cron_secret, vapid_public, vapid_private')
    .eq('id', 1)
    .maybeSingle();
  if (cfgErr || !cfg) {
    return new Response('push_config no encontrado: ejecuta web_pwa_migration.sql', { status: 500 });
  }

  const authHeader = req.headers.get('Authorization') ?? '';
  if (!cfg.cron_secret || authHeader !== `Bearer ${cfg.cron_secret}`) {
    return new Response('Unauthorized', { status: 401 });
  }

  // Primera ejecución: generar y guardar las claves VAPID.
  let vapidPublic = cfg.vapid_public as string | null;
  let vapidPrivate = cfg.vapid_private as string | null;
  if (!vapidPublic || !vapidPrivate) {
    const keys = webpush.generateVAPIDKeys();
    vapidPublic = keys.publicKey;
    vapidPrivate = keys.privateKey;
    const { error: saveErr } = await supabase
      .from('push_config')
      .update({ vapid_public: vapidPublic, vapid_private: vapidPrivate, updated_at: new Date().toISOString() })
      .eq('id', 1);
    if (saveErr) return new Response(saveErr.message, { status: 500 });
  }

  webpush.setVapidDetails(
    Deno.env.get('VAPID_SUBJECT') ?? 'mailto:franco10perez@live.com',
    vapidPublic,
    vapidPrivate,
  );

  const cleanNow = new Date();
  // ── Limpieza de comprobantes (libera espacio del plan gratuito) ───────
  // Rechazados: a los 90 días. Aprobados: al año (son prueba de pago).
  // El registro del pago se conserva; solo se borra el archivo.
  if (cleanNow.getUTCHours() === 9 && cleanNow.getUTCMinutes() < 15) {
    try {
      const days = (n: number) => new Date(cleanNow.getTime() - n * 86400000).toISOString();
      const pick = async (status: string, olderThan: string) => {
        const { data } = await supabase
          .from('org_payments')
          .select('id, receipt_path')
          .eq('status', status)
          .is('receipt_deleted_at', null)
          .lt('reviewed_at', olderThan)
          .limit(100);
        return (data ?? []) as { id: string; receipt_path: string }[];
      };
      const old = [...(await pick('rejected', days(90))), ...(await pick('approved', days(365)))];
      if (old.length > 0) {
        const { error: rmErr } = await supabase.storage
          .from('payment-receipts')
          .remove(old.map((o) => o.receipt_path));
        if (!rmErr) {
          await supabase
            .from('org_payments')
            .update({ receipt_deleted_at: cleanNow.toISOString() })
            .in('id', old.map((o) => o.id));
        } else {
          console.error('cleanup receipts', rmErr.message);
        }
      }
    } catch (e) {
      console.error('cleanup receipts failed', e);
    }
  }

  const { data: subs, error: subsErr } = await supabase
    .from('push_subscriptions')
    .select('id, user_id, endpoint, p256dh, auth');
  if (subsErr) return new Response(subsErr.message, { status: 500 });
  if (!subs || subs.length === 0) return Response.json({ sent: 0 });

  const byUser = new Map<string, Sub[]>();
  for (const s of subs as Sub[]) {
    byUser.set(s.user_id, [...(byUser.get(s.user_id) ?? []), s]);
  }

  const { data: prefsRows, error: prefsErr } = await supabase
    .from('user_preferences')
    .select(
      'user_id, notifications_enabled, workout_reminders, progress_reports, reminder_time, timezone, language, last_reminder_sent_on, last_report_sent_on',
    )
    .in('user_id', [...byUser.keys()])
    .eq('notifications_enabled', true);
  if (prefsErr) return new Response(prefsErr.message, { status: 500 });

  const now = new Date();
  let sent = 0;
  const deadSubs: string[] = [];

  async function pushTo(userSubs: Sub[], payload: Record<string, string>) {
    for (const s of userSubs) {
      try {
        await webpush.sendNotification(
          { endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } },
          JSON.stringify(payload),
          { TTL: 60 * 60 },
        );
        sent++;
      } catch (e) {
        const status = (e as { statusCode?: number }).statusCode;
        if (status === 404 || status === 410) deadSubs.push(s.id);
        else console.error('push error', status, (e as Error).message);
      }
    }
  }

  for (const p of (prefsRows ?? []) as Prefs[]) {
    const userSubs = byUser.get(p.user_id) ?? [];
    if (userSubs.length === 0) continue;
    const en = p.language === 'en';
    const local = localParts(p.timezone ?? 'America/Costa_Rica', now);

    // ── Recordatorio diario ──────────────────────────────────────────────
    const reminderAt = timeToMinutes(p.reminder_time);
    const diff = local.minutes - reminderAt;
    if (
      p.workout_reminders !== false &&
      diff >= 0 &&
      diff < REMINDER_WINDOW_MIN &&
      p.last_reminder_sent_on !== local.date
    ) {
      let title = en ? '💪 Time to train' : '💪 Hora de entrenar';
      let body = en
        ? "Don't forget today's workout. Your body will thank you!"
        : '¡No olvides tu rutina de hoy! Tu cuerpo te lo agradecerá.';

      const { data: last } = await supabase
        .from('workout_sessions')
        .select('completed_at')
        .eq('user_id', p.user_id)
        .order('completed_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (!last) {
        title = en ? 'Start today! 💪' : '¡Empieza hoy! 💪';
        body = en
          ? 'Ready for your first session?'
          : '¿Listo para tu primera sesión? ¡Tu cuerpo te lo agradecerá!';
      } else if (last.completed_at) {
        const days = Math.floor((now.getTime() - new Date(last.completed_at).getTime()) / 86400000);
        if (days >= 2) {
          title = en ? 'Everything OK? 💪' : '¿Todo bien? 💪';
          body = en
            ? `It's been ${days} days since your last workout. Today is a great day to get back!`
            : `Llevas ${days} días sin entrenar. ¡Hoy es un buen día para retomar!`;
        }
      }

      await pushTo(userSubs, { title, body, tag: 'workout_reminder', url: '/today-workout' });
      await supabase
        .from('user_preferences')
        .update({ last_reminder_sent_on: local.date })
        .eq('user_id', p.user_id);
    }

    // ── Reporte semanal (domingo) ────────────────────────────────────────
    if (
      p.progress_reports !== false &&
      local.isSunday &&
      local.hour >= REPORT_HOUR &&
      p.last_report_sent_on !== local.date
    ) {
      await pushTo(userSubs, {
        title: en ? '📊 Weekly report' : '📊 Reporte semanal',
        body: en
          ? 'Open the app to see your summary for this week.'
          : 'Abre la app para ver tu resumen de esta semana.',
        tag: 'progress_report',
        url: '/progress',
      });
      await supabase
        .from('user_preferences')
        .update({ last_report_sent_on: local.date })
        .eq('user_id', p.user_id);
    }
  }

  // ── Bandeja de avisos (comentarios, entrenos, membresías) ─────────────
  const enabledUsers = new Set(((prefsRows ?? []) as Prefs[]).map((p) => p.user_id));
  const { data: outbox } = await supabase
    .from('push_outbox')
    .select('id, user_id, title, body, url, tag')
    .is('sent_at', null)
    .gte('created_at', new Date(now.getTime() - 2 * 86400000).toISOString())
    .order('created_at')
    .limit(500);
  const doneIds: number[] = [];
  for (const m of (outbox ?? []) as {
    id: number; user_id: string; title: string; body: string; url: string; tag: string;
  }[]) {
    const userSubs = byUser.get(m.user_id) ?? [];
    if (userSubs.length > 0 && enabledUsers.has(m.user_id)) {
      await pushTo(userSubs, { title: m.title, body: m.body, tag: `${m.tag}-${m.id}`, url: m.url });
    }
    doneIds.push(m.id);
  }
  if (doneIds.length > 0) {
    await supabase.from('push_outbox').update({ sent_at: now.toISOString() }).in('id', doneIds);
  }

  if (deadSubs.length > 0) {
    await supabase.from('push_subscriptions').delete().in('id', deadSubs);
  }

  return Response.json({ sent, removed: deadSubs.length });
});
