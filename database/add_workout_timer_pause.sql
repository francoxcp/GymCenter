-- Migración: agregar columna para segundos acumulados de pausa
-- Ejecutar en Supabase SQL Editor

ALTER TABLE workout_progress
  ADD COLUMN IF NOT EXISTS accumulated_seconds INTEGER NOT NULL DEFAULT 0;
