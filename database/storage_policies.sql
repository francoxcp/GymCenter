-- ============================================
-- POLÍTICAS DE SEGURIDAD PARA SUPABASE STORAGE
-- GYMLAB
-- ============================================
-- Ejecutar DESPUÉS de supabase_rls_policies.sql

-- Crear buckets de storage si no existen
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('profile-photos', 'profile-photos', true),
  ('exercise-videos', 'exercise-videos', true),
  ('exercise-thumbnails', 'exercise-thumbnails', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- ELIMINAR POLÍTICAS EXISTENTES
-- ============================================

DROP POLICY IF EXISTS "Users can upload own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Profile photos are publicly accessible" ON storage.objects;

DROP POLICY IF EXISTS "Admins can upload exercise videos" ON storage.objects;
DROP POLICY IF EXISTS "Admins can update exercise videos" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete exercise videos" ON storage.objects;
DROP POLICY IF EXISTS "Exercise videos are publicly accessible" ON storage.objects;

DROP POLICY IF EXISTS "Admins can upload exercise thumbnails" ON storage.objects;
DROP POLICY IF EXISTS "Admins can update exercise thumbnails" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete exercise thumbnails" ON storage.objects;
DROP POLICY IF EXISTS "Exercise thumbnails are publicly accessible" ON storage.objects;

-- ============================================
-- POLÍTICAS PARA PROFILE-PHOTOS
-- ============================================

-- Los usuarios pueden subir/actualizar/eliminar sus propias fotos
CREATE POLICY "Users can upload own profile photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'profile-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update own profile photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'profile-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own profile photos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'profile-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Profile photos are publicly accessible"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile-photos');

-- ============================================
-- POLÍTICAS PARA EXERCISE-VIDEOS
-- ============================================

-- Solo entrenadores (admins) pueden subir videos
CREATE POLICY "Admins can upload exercise videos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'exercise-videos' AND
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() AND users.role = 'admin'
  )
);

CREATE POLICY "Admins can update exercise videos"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'exercise-videos' AND
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() AND users.role = 'admin'
  )
);

CREATE POLICY "Admins can delete exercise videos"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'exercise-videos' AND
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() AND users.role = 'admin'
  )
);

CREATE POLICY "Exercise videos are publicly accessible"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'exercise-videos');

-- ============================================
-- POLÍTICAS PARA EXERCISE-THUMBNAILS
-- ============================================

CREATE POLICY "Admins can upload exercise thumbnails"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'exercise-thumbnails' AND
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() AND users.role = 'admin'
  )
);

CREATE POLICY "Exercise thumbnails are publicly accessible"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'exercise-thumbnails');

-- ============================================
-- VERIFICACIÓN
-- ============================================

/*
📝 INSTRUCCIONES:

1. Ejecutar este archivo en Supabase Dashboard > SQL Editor
2. Verificar buckets creados en Storage
3. Probar subida de archivos desde la app

🔒 NOTAS DE SEGURIDAD:

- profile-photos: Solo el dueño puede subir/actualizar/eliminar
- exercise-videos: Solo admins pueden gestionar
- Todos los buckets son públicos para lectura (necesario para mostrar contenido)
*/
