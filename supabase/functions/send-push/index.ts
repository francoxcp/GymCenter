// Edge Function: send-push
// Envía las notificaciones Web Push de la versión web (PWA):
//   • Recordatorio diario de entrenamiento a la hora elegida por el usuario.
//   • Aviso del reporte semanal los domingos a partir de las 9:00.
// La invoca pg_cron cada 15 minutos (ver database/web_pwa_migration.sql).
//
// Secrets necesarios (supabase secrets set ...):
//   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_SUBJECT (mailto:...),
//   CRON_SECRET
// SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY los inyecta Supabase.
//
// Desplegar con:  supabase functions deploy send-push --no-verify-jwt

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
  const secret = Deno.env.get('CRON_SECRET');
  const authHeader = req.headers.get('Authorization') ?? '';
  if (!secret || authHeader !== `Bearer ${secret}`) {
    return new Response('Unauthorized', { status: 401 });
  }

  webpush.setVapidDetails(
    Deno.env.get('VAPID_SUBJECT') ?? 'mailto:admin@example.com',
    Deno.env.get('VAPID_PUBLIC_KEY')!,
    Deno.env.get('VAPID_PRIVATE_KEY')!,
  );

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } },
  );

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

  if (deadSubs.length > 0) {
    await supabase.from('push_subscriptions').delete().in('id', deadSubs);
  }

  return Response.json({ sent, removed: deadSubs.length });
});
