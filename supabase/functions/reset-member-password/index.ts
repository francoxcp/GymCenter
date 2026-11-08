// Edge Function: reset-member-password
// El DUEÑO (a cualquier socio o entrenador) o el ENTRENADOR (solo a sus
// socios) asignan una contraseña temporal. También ACTIVA la cuenta si el
// correo no estaba confirmado.
//
// Existe porque el correo gratuito de Supabase solo envía a los correos del
// equipo del proyecto: "Olvidé mi contraseña" no les llega a los socios.
//
// Seguridad: verificación JWT ACTIVADA (por defecto); permisos comprobados en
// la base de datos. No se puede usar sobre el dueño ni sobre uno mismo.

import { createClient } from 'npm:@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    (Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SECRET_KEY'))!,
    { auth: { persistSession: false } },
  );

  const jwt = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '');
  const { data: caller, error: callerErr } = await admin.auth.getUser(jwt);
  if (callerErr || !caller?.user) return json({ error: 'not_authenticated' }, 401);

  const { data: callerRow } = await admin
    .from('users')
    .select('id, role, org_id')
    .eq('id', caller.user.id)
    .maybeSingle();
  const role = callerRow?.role;
  if (role !== 'admin' && role !== 'trainer') return json({ error: 'not_allowed' }, 403);

  let body: { user_id?: string; password?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'invalid_body' }, 400);
  }
  const userId = body.user_id ?? '';
  const password = body.password ?? '';
  if (!/^[0-9a-f-]{36}$/i.test(userId)) return json({ error: 'invalid_user' }, 400);
  if (userId === caller.user.id) return json({ error: 'not_allowed' }, 403);
  if (password.length < 8) return json({ error: 'weak_password' }, 400);

  const { data: target } = await admin
    .from('users')
    .select('id, role, trainer_id, org_id')
    .eq('id', userId)
    .maybeSingle();
  if (!target) return json({ error: 'invalid_user' }, 404);
  if (target.role === 'admin') return json({ error: 'not_allowed' }, 403);
  // Multi-cliente: solo usuarios de la misma organización
  if (!callerRow?.org_id || target.org_id !== callerRow.org_id) {
    return json({ error: 'not_allowed' }, 403);
  }
  // Cliente suspendido por la plataforma: sin gestión de socios
  const { data: orgRow } = await admin
    .from('organizations')
    .select('status')
    .eq('id', callerRow.org_id)
    .maybeSingle();
  if (orgRow?.status !== 'active') return json({ error: 'organization_suspended' }, 403);

  if (role === 'trainer' && (target.role !== 'user' || target.trainer_id !== caller.user.id)) {
    return json({ error: 'not_allowed' }, 403);
  }

  const { error } = await admin.auth.admin.updateUserById(userId, {
    password,
    email_confirm: true,
  });
  if (error) {
    console.error('updateUserById error', error);
    const msg = (error.message ?? '').toLowerCase();
    if (msg.includes('password')) return json({ error: 'weak_password' }, 400);
    return json({ error: 'reset_failed' }, 500);
  }
  return json({ ok: true });
});
