---
description: Crea una migración SQL de Supabase con su guía de aplicación y PR
---
Cambio pedido: $ARGUMENTS

1. Crea una rama `db/<nombre-corto>`.
2. Escribe `database/<nombre>.sql` idempotente, con RLS para las tablas nuevas según los roles dueño/entrenador/socio.
3. Pide revisión al subagente `supabase-reviewer` y corrige lo grave/medio.
4. Abre un PR cuya descripción incluya la guía paso a paso para el dueño: abrir Supabase → SQL Editor → pegar el script → ejecutar → cómo comprobar que funcionó.
