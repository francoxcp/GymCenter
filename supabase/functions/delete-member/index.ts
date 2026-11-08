// Edge Function: delete-member
// El DUEÑO elimina por completo a un usuario: su cuenta de acceso (auth) y,
// en cascada, su perfil y todos sus datos. Antes la app solo borraba el
// perfil (public.users) y la persona podía seguir iniciando sesión.
//
// Seguridad: verificación JWT ACTIVADA (por defecto); el rol de dueño se
// comprueba en la base de datos. Nadie puede eliminarse a sí mismo por aquí.
//
// Desplegar:  supabase functions deploy delete-member

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
    .select('role, org_id')
    .eq('id', caller.user.id)
    .maybeSingle();
  if (callerRow?.role !== 'admin' || !callerRow.org_id) return json({ error: 'not_allowed' }, 403);

  let body: { user_id?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'invalid_body' }, 400);
  }
  const userId = body.user_id ?? '';
  if (!/^[0-9a-f-]{36}$/i.test(userId)) return json({ error: 'invalid_user' }, 400);
  if (userId === caller.user.id) return json({ error: 'cannot_delete_self' }, 400);

  // Multi-cliente: solo usuarios de la misma organización
  const { data: target } = await admin
    .from('users')
    .select('org_id, role')
    .eq('id', userId)
    .maybeSingle();
  if (!target || target.org_id !== callerRow.org_id) return json({ error: 'not_allowed' }, 403);
  // Nunca borrar a otro dueño ni a un administrador de la plataforma
  const { data: platform } = await admin
    .from('platform_admins')
    .select('user_id')
    .eq('user_id', userId)
    .maybeSingle();
  if (target.role === 'admin' || platform) return json({ error: 'not_allowed' }, 403);

  // Cliente suspendido por la plataforma: sin gestión de socios
  const { data: orgRow } = await admin
    .from('organizations')
    .select('status')
    .eq('id', callerRow.org_id)
    .maybeSingle();
  if (orgRow?.status !== 'active') return json({ error: 'organization_suspended' }, 403);

  // Los socios de un entrenador eliminado quedan sin entrenador (ON DELETE SET NULL)
  const { error } = await admin.auth.admin.deleteUser(userId);
  if (error) {
    // Si no existe la cuenta de acceso, borrar al menos el perfil huérfano
    if ((error.message ?? '').toLowerCase().includes('not found')) {
      await admin.from('users').delete().eq('id', userId);
      return json({ deleted: true, orphan: true });
    }
    console.error('deleteUser error', error);
    return json({ error: 'delete_failed' }, 500);
  }
  // Por si el perfil no tenía la clave foránea con cascada
  await admin.from('users').delete().eq('id', userId);
  return json({ deleted: true });
});
