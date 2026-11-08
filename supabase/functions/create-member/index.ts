// Edge Function: create-member
// Permite que un ENTRENADOR o el DUEÑO den de alta un socio nuevo.
// - El entrenador: el socio queda asignado a él.
// - El dueño: puede indicar trainer_id (o dejarlo sin entrenador).
// El socio recibe una contraseña temporal que puede cambiar en la app.
//
// Seguridad: requiere el JWT del usuario que llama (verificación JWT ACTIVADA,
// la opción por defecto). El rol se comprueba en la base de datos, no se
// confía en lo que envía la app.
//
// Desplegar:  supabase functions deploy create-member

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

  // ¿Quién llama?
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
  // Multi-cliente: el socio nuevo entra a la organización de quien lo crea
  const orgId = callerRow?.org_id as string | null;
  if (!orgId) return json({ error: 'no_organization' }, 403);

  let body: { name?: string; email?: string; password?: string; trainer_id?: string | null };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'invalid_body' }, 400);
  }

  const name = (body.name ?? '').trim();
  const email = (body.email ?? '').trim().toLowerCase();
  const password = body.password ?? '';
  if (name.length < 2 || name.length > 80) return json({ error: 'invalid_name' }, 400);
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return json({ error: 'invalid_email' }, 400);
  if (password.length < 8) return json({ error: 'weak_password' }, 400);

  // Entrenador: siempre él mismo. Dueño: el que indique (o ninguno).
  let trainerId: string | null = role === 'trainer' ? callerRow!.id : (body.trainer_id ?? null);
  if (role === 'admin' && trainerId) {
    const { data: t } = await admin
      .from('users')
      .select('id, role, org_id')
      .eq('id', trainerId)
      .maybeSingle();
    if (!t || (t.role !== 'trainer' && t.role !== 'admin') || t.org_id !== orgId) trainerId = null;
  }

  const { data: created, error: createErr } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { name },
    // Registro de quién dio de alta la cuenta (no lo puede modificar el usuario)
    app_metadata: { created_by: callerRow!.id, created_by_role: role },
  });
  if (createErr || !created?.user) {
    const msg = (createErr?.message ?? '').toLowerCase();
    if (msg.includes('already') || msg.includes('registered') || msg.includes('exists')) {
      return json({ error: 'email_exists' }, 409);
    }
    console.error('createUser error', createErr);
    return json({ error: 'create_failed' }, 500);
  }

  // El trigger handle_new_user ya creó la fila en public.users
  await admin
    .from('users')
    .update({ org_id: orgId, trainer_id: trainerId })
    .eq('id', created.user.id);

  return json({ id: created.user.id, email, name, trainer_id: trainerId });
});
