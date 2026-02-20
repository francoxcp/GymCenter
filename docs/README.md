# 📂 Database - Chamos Fitness Center

Esta carpeta contiene todos los scripts SQL necesarios para configurar la base de datos en Supabase.

## 📋 Archivos Disponibles

### 1. **supabase_schema.sql** ⭐ EJECUTAR PRIMERO
Crea todas las tablas principales del sistema:

**Tablas incluidas:**
- `meal_plans` - Planes alimenticios
- `workouts` - Rutinas de entrenamiento
- `users` - Usuarios (vinculado con auth.users)
- `exercises` - Ejercicios de cada rutina
- `workout_sessions` - Historial de entrenamientos completados
- `body_measurements` - Medidas corporales de usuarios
- `user_preferences` - Preferencias y configuración
- `achievements` - Logros disponibles
- `user_achievements` - Logros desbloqueados por usuarios

**Características:**
- ✅ Índices optimizados para rendimiento
- ✅ Triggers automáticos (updated_at, exercise_count)
- ✅ Función `handle_new_user()` para crear usuarios automáticamente
- ✅ Datos SEED de ejemplo (planes, rutinas, ejercicios, logros)

---

### 2. **fix_rls_recursion.sql** ⭐ EJECUTAR SEGUNDO
Corrige el problema de **recursión infinita** en las políticas RLS y añade tablas adicionales.

**¿Qué hace?**
- ✅ Crea función helper `is_admin()` sin recursión
- ✅ Elimina todas las políticas problemáticas anteriores
- ✅ Crea políticas RLS correctas para todas las tablas
- ✅ Añade tablas adicionales requeridas por la app

**Tablas adicionales creadas:**
- `workout_progress` - Progreso incompleto de entrenamientos
- `workout_ratings` - Valoraciones de usuarios sobre workouts
- `user_goals` - Metas personales de usuarios

**Políticas RLS para:**
- users
- workouts
- exercises
- meal_plans
- workout_progress
- workout_ratings
- user_goals

---

### 3. **storage_policies.sql** ⭐ EJECUTAR TERCERO
Configura los buckets de almacenamiento y sus políticas de acceso.

**Buckets creados:**
- `profile-photos` (público) - Fotos de perfil
- `exercise-videos` (público) - Videos de ejercicios
- `exercise-thumbnails` (público) - Miniaturas de ejercicios

**Políticas:**
- Usuarios pueden subir/editar/eliminar sus propias fotos de perfil
- Solo admins pueden gestionar videos y thumbnails de ejercicios
- Todos pueden ver contenido público

---

### 4. **delete_account_function.sql** ⭐ EJECUTAR CUARTO (Opcional)
Función para eliminar cuentas de usuario de forma segura.

**Función:** `delete_user_account(user_id UUID)`

**Elimina en orden:**
1. Logros del usuario
2. Medidas corporales
3. Sesiones de entrenamiento
4. Preferencias
5. Registro en tabla users
6. Cuenta de autenticación (auth.users)

**Uso desde Flutter:**
```dart
await Supabase.instance.client.rpc(
  'delete_user_account',
  params: {'user_id': userId},
);
```

---

## 🚀 Orden de Ejecución

Ejecuta los scripts en Supabase SQL Editor en este orden:

```bash
1. supabase_schema.sql          # Crea todas las tablas base
2. fix_rls_recursion.sql        # Configura RLS sin recursión + tablas extra
3. storage_policies.sql         # Configura almacenamiento de archivos
4. delete_account_function.sql  # Función para eliminar cuentas (opcional)
```

## 📊 Diagrama de Relaciones

```
auth.users (Supabase Auth)
    ↓
users ←──────────────────┐
    ↓                    │
    ├── assigned_workout_id → workouts
    │                         └── exercises
    ├── assigned_meal_plan_id → meal_plans
    │
    ├── workout_sessions (historial)
    ├── workout_progress (progreso incompleto)
    ├── workout_ratings (valoraciones)
    ├── body_measurements (medidas)
    ├── user_preferences (configuración)
    ├── user_goals (metas)
    └── user_achievements → achievements
```

## 🔒 Políticas de Seguridad (RLS)

### Roles:
- **admin** - Entrenadores (acceso completo)
- **user** - Usuarios normales (acceso limitado)

### Reglas generales:
- ✅ Todos pueden VER workouts, exercises, meal_plans (catálogo público)
- ✅ Solo ADMINS pueden crear/editar/eliminar workouts, exercises, meal_plans
- ✅ Usuarios solo ven/editan su propia información
- ✅ Admins pueden ver todos los usuarios (para asignar rutinas/dietas)

---

## ✅ Verificación

Después de ejecutar todos los scripts, verifica que todo esté correcto:

```sql
-- Ver todas las tablas creadas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Ver todas las políticas RLS
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies
ORDER BY tablename, policyname;

-- Verificar que no hay recursión infinita (debe ejecutarse sin errores)
SELECT * FROM workouts LIMIT 1;
SELECT * FROM users LIMIT 1;
```

---

## 🐛 Solución de Problemas

### Error: "infinite recursion detected in policy"
- ✅ **Solución:** Ejecuta `fix_rls_recursion.sql` completo
- Este error ocurre cuando las políticas RLS consultan la misma tabla que están protegiendo

### Error: "relation does not exist"
- ✅ **Solución:** Primero ejecuta `supabase_schema.sql`
- Las tablas deben existir antes de crear políticas

### Pantalla negra después del login
- ✅ **Solución:** Ejecuta `fix_rls_recursion.sql`
- Causado por recursión infinita en políticas RLS

---

## 📝 Mantenimiento

### Agregar nueva tabla:
1. Añade `CREATE TABLE` en `supabase_schema.sql`
2. Añade políticas RLS en `fix_rls_recursion.sql` usando `is_admin()`

### Modificar políticas:
1. Edita `fix_rls_recursion.sql`
2. Re-ejecuta el script completo (elimina políticas antiguas automáticamente)

---

## 📚 Documentación Adicional

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Policies](https://www.postgresql.org/docs/current/sql-createpolicy.html)
- [Supabase Storage](https://supabase.com/docs/guides/storage)

---

**Última actualización:** Febrero 2026
**Versión:** 2.0 - Consolidado y optimizado
