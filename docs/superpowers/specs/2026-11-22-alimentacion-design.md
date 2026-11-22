# Alimentación tica para el socio — diseño

Fecha: 2026-11-22 · Estado: borrador para aprobación

## Intención

El socio quiere saber **qué comer para su objetivo** sin gastar de más. La app
le muestra un plan diario **ajustado a su cuerpo** (calorías y proteína propias)
y, en cada comida, **varias opciones con comida de Costa Rica** que se consigue
en cualquier pulpería, feria o súper, con precio aproximado. El socio **elige**
qué desayunar, almorzar, merendar y cenar; ninguna opción es obligatoria.

Para hacer espacio, el **chat del socio deja de ser pestaña** y pasa a un botón
en la cabecera de la pantalla Hoy.

## Objetivos

1. Tres planes según el objetivo: **mantener peso**, **subir masa muscular**,
   **bajar grasa manteniendo el músculo**.
2. Porciones calculadas para cada socio (peso, estatura, edad, sexo, actividad,
   días de entreno, objetivo).
3. 8–10 opciones por tiempo de comida, todas ticas y de presupuesto estándar,
   con precio aproximado en colones.
4. Interfaz fácil: abrir la pestaña y ver de inmediato "tu día" con las opciones
   de la siguiente comida; elegir con un toque.
5. Cuestionario corto la primera vez, explicando qué se pide y por qué.

## No-objetivos (v1)

- Registrar lo que comió cada día o contar calorías consumidas.
- Planes asignados o editados por el entrenador/dueño.
- Recetario editable desde la base de datos.
- Generación con IA.
- Sección de alimentación para entrenadores/dueños (sus pestañas no cambian).

## Anti-objetivos (sería un fracaso aunque funcione)

- Comida cara, importada o "fitness" de Instagram (quinoa, salmón, whey).
- Déficits extremos o promesas médicas. Siempre aviso: "Guía orientativa; no
  reemplaza a un nutricionista. Si tienes una condición médica, consulta".
- Que parezca hecho con IA (ver Dirección visual).

## Enfoques considerados

| Enfoque | Ventaja | Costo | Decisión |
|---|---|---|---|
| **1. Recetario dentro de la app** (Dart const) + cálculo local | Sin internet, inmediato, gratis, valores revisados | Cambiar platos = nueva versión | **Elegido por el dueño** |
| 2. Recetario en Supabase editable | Flexible | Pantallas de edición, validación de nutrientes, RLS | Descartado |
| 3. Generación con IA | Variedad infinita | Costo por uso, inventa cantidades, no garantiza comida tica/barata | Descartado |

## Decisiones del dueño

- Opción B: plan **ajustado a cada socio**.
- Cuestionario de 3 pasos (abajo) basta.
- Variedad: el socio **elige** entre opciones en cada comida.
- Recetario dentro de la app (enfoque 1).

## Navegación

- Socio **con entrenador**: `Hoy · Progreso · Comida · Perfil` (antes Chat en el
  lugar de Comida).
- Socio **sin entrenador**: `Hoy · Progreso · Comida · Perfil` (gana la pestaña).
- Chat del socio: botón con icono de conversación en la cabecera de **Hoy**, con
  el contador de no leídos (`ChatService.unread`). Solo visible si tiene
  entrenador. La ruta `/chat`, los enlaces de notificaciones push y la
  redirección `/chats → /chat` siguen igual.
- Ruta nueva `/comida` (pestaña). Entrenadores y dueños no la ven en su barra;
  si escriben la URL, la ven igual (no hay datos sensibles), sin cambios en el
  router salvo registrar la ruta.

## Cuestionario (primera vez que abre Comida, o "Ajustar mi plan")

Paso 1 — **Confirma tus datos**: peso, estatura, edad, sexo (ya existen en
`users`; se muestran con botón Editar) y objetivo (3 opciones). Texto: "Con esto
calculamos cuánta energía gasta tu cuerpo" / "Define si comes un poco más, igual
o un poco menos".

Paso 2 — **Actividad fuera del gym**: Trabajo sentado · De pie / camino mucho ·
Trabajo físico. Texto: "Un trabajo físico gasta mucho más que uno de oficina".

Paso 3 — **Lo que no comes** (multi): Lácteos · Huevo · Mariscos y pescado ·
Carne roja · Cerdo. **Comidas al día**: 3 · 4 · 5. Texto: "Para no recomendarte
lo que no puedes o no quieres comer" / "Repartimos tu plan en esas comidas".

Mapeo del objetivo existente (`users.goal` del registro): `lose_weight → bajar
grasa`, `gain_muscle → subir masa`, `maintain` e `improve_health → mantener`.
Si el socio cambia el objetivo en el cuestionario, se guarda en `users.goal`
con el valor equivalente.

Días de entreno por semana: se leen de `user_workout_schedule` (días distintos
con rutina). Sin plan semanal: 3.

### Datos nuevos (Supabase)

Columnas en `public.users` (script idempotente `database/alimentacion_migration.sql`):
- `activity_level text check in ('sedentary','standing','physical')`
- `food_avoid text[] default '{}'` (valores: `dairy, egg, seafood, red_meat, pork`)
- `meals_per_day smallint check between 3 and 5`

RLS: las políticas actuales de `users` ya cubren que cada uno edite lo suyo y el
entrenador/dueño lea a sus socios. `users_guard` no toca estas columnas.
Plan sin conexión: las respuestas también se guardan en el dispositivo.

## Cálculo (lib/features/nutrition/services/nutrition_calculator.dart)

1. **Gasto en reposo** — Mifflin-St Jeor:
   hombre `10·kg + 6,25·cm − 5·edad + 5`; mujer `… − 161`; otro: promedio.
2. **Factor de actividad** = base por trabajo (sentado 1,20 · de pie 1,375 ·
   físico 1,55) + 0,035 × días de entreno (máx. 6), tope 1,9.
3. **Objetivo**: mantener ×1,00 · subir masa ×1,10 · bajar grasa ×0,80.
   Piso de seguridad: nunca menos de reposo × 1,1 ni de 1500 kcal (hombre) /
   1200 kcal (mujer/otro). Redondeo a 50 kcal.
4. **Proteína** (g/kg de peso): mantener 1,6 · subir 1,8 · bajar 2,0
   (ISSN 2017: 1,4–2,0 para quien entrena; más en déficit). Tope 220 g.
5. **Grasa**: 25 % de las kcal, mínimo 0,6 g/kg. **Carbohidratos**: el resto.
6. **Reparto por comidas** (kcal):
   3 → desayuno 30 · almuerzo 40 · cena 30;
   4 → 25 · 35 · merienda 10 · 30;
   5 → 25 · merienda AM 10 · 30 · merienda PM 10 · 25.
   La proteína se reparte igual que las kcal.

## Recetario (lib/features/nutrition/data/)

- `foods.dart`: alimentos con kcal, proteína, carbohidrato y grasa por 100 g,
  medida casera (`1 taza = 160 g de gallo pinto`, `1 huevo = 50 g`,
  `1 tortilla = 30 g`…), precio aproximado en colones por kg/unidad y etiquetas
  de exclusión (`dairy`, `egg`, `seafood`, `red_meat`, `pork`).
  Fuentes de nutrientes: Tabla de Composición de Alimentos de Centroamérica
  (INCAP) y USDA FoodData Central. Precios: monitoreos MEIC/CNP y referencias
  de supermercado, noviembre 2026; se muestran como "aprox." con la fecha.
- `meal_catalog.dart`: opciones por tiempo. Cada opción: nombre, tiempo(s)
  donde aplica, ingredientes con cantidad base, rol de cada ingrediente
  (`protein`, `carb`, `fat`, `veg`) y si es "rápida" (≤10 min).

Opciones propuestas (el builder completa a 8–10 por tiempo, siempre ticas y
baratas):
- **Desayuno**: gallo pinto con huevo · avena con banano y leche · tortilla con
  queso tierno y huevo · pan con huevo y aguacate · batido de avena, leche y
  banano · gallo pinto con natilla y plátano maduro · papaya con queso y huevo
  duro · yogur con granola y fruta · tamal de maíz con huevo (temporada) .
- **Almuerzo**: casado de pollo · casado de res · arroz con pollo y ensalada ·
  olla de carne · picadillo de papa con carne molida · arroz, frijoles y atún ·
  sopa negra con huevo · tilapia con arroz y ensalada · arroz con frijoles,
  huevo y maduro (sin carne).
- **Merienda**: banano con maní · yogur natural · pan con atún · huevo duro y
  fruta · gallo pinto pequeño · batido de leche con fruta de temporada ·
  galletas de soda con queso.
- **Cena**: tortillas con pollo desmenuzado · picadillo de chayote con carne
  molida · huevos revueltos con vainica · ensalada de atún con aguacate ·
  pescado con yuca · arroz con frijoles y queso.

**Escalado**: la opción se calcula con sus cantidades base; factor = kcal objetivo
de esa comida / kcal base, limitado a 0,6–1,8. Si la proteína queda por debajo
de 80 % del objetivo de esa comida, se sube primero el ingrediente `protein`
(hasta el límite) y se baja el `carb` para compensar kcal. Las cantidades se
redondean a medidas caseras (medias unidades, ¼ de taza, 10 g).

**Filtro**: se ocultan las opciones con ingredientes excluidos. Si un tiempo
queda con menos de 3 opciones, se muestran igual las que haya y un texto
"Pocas opciones con tus restricciones".

## Pantalla Comida

Dirección visual: **la pizarra de una soda**. Fondo oscuro del tema, un solo
acento (el `AppColors.primary` actual), números grandes como protagonistas.
Tipografía del tema con escala marcada; espaciado en múltiplos de 8; tarjetas
planas con separadores en vez de sombras; sin emojis ni iconos decorativos.
Detalle memorable: el precio de cada opción en grande al estilo pizarra (`₡900`).

```
COMIDA · SUBIR MASA                     [Ajustar]
2 650 kcal        155 g proteína
──────────────────────────────────────────────
[Desayuno] Almuerzo  Merienda  Cena      ← chips
650 kcal · 40 g proteína · elige una
┌───────────────────────────────────────────┐
│ Gallo pinto con huevo            ₡900     │
│ 1 taza pinto · 3 huevos · 1 tortilla      │
│ 41 g proteína · 640 kcal     [ Elegir ]   │
├───────────────────────────────────────────┤
│ Avena con banano y leche         ₡600     │
│ …                                          │
└───────────────────────────────────────────┘
Tu día: 1 de 4 comidas elegidas · ~₡3 100
Guía orientativa; no reemplaza a un nutricionista.
```

- Abre en el chip de la **siguiente comida según la hora** (antes de 10:00
  desayuno, 10–12 merienda AM, 12–15 almuerzo, 15–18 merienda, después cena).
- Tocar una opción la despliega con ingredientes y cantidades; "Elegir" la
  marca para hoy (guardado solo en el dispositivo, se reinicia cada día). El
  pie suma kcal, proteína y costo de lo elegido.
- "Ajustar" reabre el cuestionario.
- Si cambia el peso (Medidas), el plan se recalcula al abrir.
- Estado vacío (datos incompletos): invita al cuestionario con una línea, sin
  texto de relleno.

## Pruebas

- Unitarias: cálculo (casos hombre/mujer/otro, pisos de seguridad, topes),
  reparto por comidas, escalado y redondeo, filtro de exclusiones, coherencia
  del catálogo (todo ingrediente existe, kcal base > 0, ≥3 opciones por tiempo
  sin exclusiones).
- Widget: cuestionario de 3 pasos y pantalla con opciones.
- Navegación: socio con y sin entrenador ve `Comida`; el botón de chat aparece
  solo con entrenador y lleva a `/chat`.
- Visual: Playwright 390×844 (cuestionario, pantalla, opción desplegada).

## Otros cambios

- `CLAUDE.md`: reemplazar "No hay planes de alimentación (eliminados)" por "Hay
  una guía de alimentación con recetario fijo en la app (`features/nutrition`);
  no hay planes asignados por el entrenador".
- PR con guía para ejecutar `database/alimentacion_migration.sql`.

## Lo que queda al builder

- Valores exactos de nutrientes, medidas caseras y precios de cada alimento.
- Completar el catálogo hasta 8–10 opciones por tiempo con los criterios dados.
- Detalle de animaciones (elegir una opción debe sentirse satisfactorio, breve).
