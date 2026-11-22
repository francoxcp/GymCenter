# Alimentación tica — plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pestaña "Comida" para el socio con plan diario ajustado a su cuerpo y opciones ticas a elegir por comida; el chat pasa a la cabecera de Hoy.

**Architecture:** Cálculo y recetario en Dart puro (`lib/features/nutrition/`), sin red. Las respuestas del cuestionario se guardan en 3 columnas nuevas de `public.users` y en el dispositivo. La elección diaria vive solo en `SharedPreferences`.

**Tech Stack:** Flutter (provider, go_router), Supabase, shared_preferences, flutter_test, Playwright.

**Spec:** `docs/superpowers/specs/2026-11-22-alimentacion-design.md`

## Global Constraints

- Textos en español; tono directo, sin relleno ni emojis.
- Tema de `lib/core/`: un solo acento (`AppColors.primary`), espaciado múltiplos de 8, sin sombras suaves en todo; tokens nuevos se agregan en `lib/core/theme/app_theme.dart`.
- Aviso fijo visible en la pantalla: "Guía orientativa; no reemplaza a un nutricionista."
- Aviso a menores de 18: "A tu edad, consulta con un nutricionista y tu encargado antes de cambiar tu alimentación".
- Precios con prefijo "~₡" y nota "Precios aprox. nov 2026".
- Exclusiones válidas: `dairy`, `egg`, `seafood`, `red_meat`, `pork`.
- Cada cambio de BD: script idempotente en `database/` + revisión `supabase-reviewer` + guía en el PR.
- Antes de cerrar: `flutter analyze --no-fatal-infos` sin errores, `flutter test` en verde, captura Playwright 390×844.

## Review Focus

1. Socio con datos incompletos (edad, estatura o sexo nulos) → la pestaña muestra el cuestionario, nunca un cálculo con nulos. (Task 5)
2. Socio que excluye todo (lácteos, huevo, mariscos, carne roja, cerdo) → cada tiempo muestra lo que quede y "Pocas opciones con tus restricciones"; nunca lista vacía sin explicación. (Task 2, Task 6)
3. Pesos extremos (40 kg y 150 kg) → porciones dentro de 0,6–1,8× y proteína ≤ 220 g; sin cantidades absurdas. (Task 1, Task 2)
4. 3 comidas al día a las 11:00 → no existe merienda; la pantalla abre en la siguiente comida que sí existe (almuerzo). (Task 6)
5. Sin conexión al guardar el cuestionario → se guarda en el dispositivo y el plan se muestra igual. (Task 3)

---

### Task 1: Calculadora de objetivos diarios

**Files:**
- Create: `lib/features/nutrition/models/nutrition_profile.dart`
- Create: `lib/features/nutrition/services/nutrition_calculator.dart`
- Test: `test/services/nutrition_calculator_test.dart`

**Interfaces:**
- Produces:
  - `enum NutritionGoal { maintain, gain, cut }`
  - `enum ActivityLevel { sedentary, standing, physical }` con `String get db` (`'sedentary'|'standing'|'physical'`) y `static ActivityLevel? fromDb(String?)`
  - `enum MealSlot { breakfast, snackAm, lunch, snackPm, dinner }` con `String get label` ("Desayuno", "Merienda", "Almuerzo", "Merienda", "Cena")
  - `class NutritionProfile { double weightKg; int heightCm; int age; String sex; NutritionGoal goal; ActivityLevel activity; int trainingDays; int mealsPerDay; Set<String> avoid; bool get isMinor => age < 18; }`
  - `class MealTarget { MealSlot slot; int kcal; int proteinG; }`
  - `class DailyTargets { int kcal; int proteinG; int fatG; int carbG; List<MealTarget> meals; }`
  - `NutritionGoal goalFromLabel(String? label)` — 'Perder peso'→cut, 'Ganar músculo'→gain, resto/null→maintain
  - `String goalToLabel(NutritionGoal g, {String? current})` — cut→'Perder peso', gain→'Ganar músculo', maintain→ `current == 'Mejorar salud' ? 'Mejorar salud' : 'Mantener peso'`
  - `List<MealSlot> slotsFor(int mealsPerDay)`
  - `DailyTargets computeTargets(NutritionProfile p)`

- [ ] **Step 1: Write the failing tests**

```dart
test('hombre 78 kg 175 cm 29 a, sentado, 3 días, subir masa, 4 comidas', () {
  final t = computeTargets(p(weight: 78, height: 175, age: 29, sex: 'male',
      goal: NutritionGoal.gain, act: ActivityLevel.sedentary, days: 3, meals: 4));
  expect(t.kcal, 2500);          // 1733,75 × 1,305 × 1,10 = 2488,7 → 2500
  expect(t.proteinG, 140);       // 1,8 × 78
  expect(t.fatG, 69);            // 25 % de 2500 / 9
  expect(t.carbG, 330);          // (2500 − 560 − 621) / 4
  expect(t.meals.map((m) => m.slot), [MealSlot.breakfast, MealSlot.lunch, MealSlot.snackPm, MealSlot.dinner]);
  expect(t.meals.map((m) => m.kcal), [625, 875, 250, 750]);
});
test('mujer en déficit respeta el piso (reposo × 1,1, redondeo hacia arriba)', () {
  final t = computeTargets(p(weight: 60, height: 160, age: 30, sex: 'female',
      goal: NutritionGoal.cut, act: ActivityLevel.sedentary, days: 0, meals: 3));
  expect(t.kcal, 1450);          // piso 1417,9 → techo a 50
  expect(t.proteinG, 120);       // 2,0 × 60
});
test('menor de 18: cut se trata como mantener y gain como ×1,05', () {
  final base = p(weight: 60, height: 170, age: 16, sex: 'male', act: ActivityLevel.standing, days: 3, meals: 4);
  expect(computeTargets(base.copyWith(goal: NutritionGoal.cut)).kcal,
         computeTargets(base.copyWith(goal: NutritionGoal.maintain)).kcal);
  final m = computeTargets(base.copyWith(goal: NutritionGoal.maintain)).kcal;
  expect(computeTargets(base.copyWith(goal: NutritionGoal.gain)).kcal, closeTo(m * 1.05, 50));
});
test('sexo other usa el promedio (−78)', ...);         // kcal entre las de male y female
test('factor de actividad tope 1,9 y días máx. 6', ...); // physical + 7 días == physical + 6 días
test('pesos extremos: proteína ≤ 220 g y grasa ≥ 0,6 g/kg', ...); // 40 kg y 150 kg
test('reparto 3/4/5 comidas', () {
  expect(slotsFor(3), [MealSlot.breakfast, MealSlot.lunch, MealSlot.dinner]);
  expect(slotsFor(5), MealSlot.values);
  // 5 → 25/10/30/10/25 ; la proteína se reparte igual
});
test('goalFromLabel / goalToLabel conservan Mejorar salud', () {
  expect(goalFromLabel('Mejorar salud'), NutritionGoal.maintain);
  expect(goalToLabel(NutritionGoal.maintain, current: 'Mejorar salud'), 'Mejorar salud');
  expect(goalToLabel(NutritionGoal.cut), 'Perder peso');
});
```

- [ ] **Step 2: Run and see them fail** — `flutter test test/services/nutrition_calculator_test.dart` → FAIL (no existe el archivo).
- [ ] **Step 3: Implement** según la spec (sección Cálculo): Mifflin-St Jeor (`other` = −78), actividad base 1,20/1,375/1,55 + 0,035 × min(días, 6), tope 1,9; objetivo ×1,00/×1,10/×0,80 (menores: cut→maintain, gain ×1,05); piso = max(reposo × 1,1, male 1500 / resto 1200); kcal redondeadas a 50, y si el redondeo queda bajo el piso, techo a 50; proteína g/kg 1,6/1,8/2,0 tope 220; grasa 25 % con mínimo 0,6 g/kg; carbohidratos el resto. Reparto: 3 → 30/40/30; 4 → 25/35/10/30 (merienda = `snackPm`); 5 → 25/10/30/10/25.
- [ ] **Step 4: Run tests** → PASS.
- [ ] **Step 5: Commit** `feat(nutrition): calculadora de objetivos diarios`.

### Task 2: Alimentos, recetario y escalado

**Files:**
- Create: `lib/features/nutrition/data/foods.dart`
- Create: `lib/features/nutrition/data/meal_catalog.dart`
- Create: `lib/features/nutrition/services/meal_scaler.dart`
- Test: `test/services/meal_catalog_test.dart`

**Interfaces:**
- Consumes: `MealSlot`, `MealTarget` (Task 1).
- Produces:
  - `class Food { String id; String name; double kcal100, protein100, carb100, fat100; String? unitName; double? unitGrams; double priceCrcPerKg; Set<String> tags; }` y `const Map<String, Food> kFoods`
  - `enum IngredientRole { protein, carb, fat, veg }`
  - `class Ingredient { String foodId; double grams; IngredientRole role; }`
  - `class MealOption { String id; String name; Set<MealSlot> slots; List<Ingredient> ingredients; bool quick; }` y `const List<MealOption> kMealCatalog`
  - `class ScaledItem { Food food; double grams; String label; }` (label tipo "1½ taza gallo pinto", "3 huevos", "90 g pollo")
  - `class ScaledOption { MealOption option; List<ScaledItem> items; int kcal; int proteinG; int priceCrc; }`
  - `List<MealOption> optionsFor(MealSlot slot, Set<String> avoid)` — `snackAm` y `snackPm` comparten las opciones de merienda
  - `ScaledOption scaleOption(MealOption o, MealTarget t)`

- [ ] **Step 1: Write the failing tests**

```dart
test('todo ingrediente existe en kFoods y cada opción tiene kcal base > 0', ...);
test('ids de opciones únicos', ...);
test('8 a 10 opciones por desayuno, almuerzo y cena; ≥ 7 meriendas', ...);
test('sin exclusiones, ningún tiempo queda con < 3 opciones', ...);
test('excluir huevo quita gallo pinto con huevo del desayuno', () {
  expect(optionsFor(MealSlot.breakfast, {'egg'}).any((o) => o.id == 'pinto_huevo'), isFalse);
});
test('excluir todo deja al menos 1 opción por tiempo', () {
  for (final s in MealSlot.values) {
    expect(optionsFor(s, {'dairy','egg','seafood','red_meat','pork'}), isNotEmpty);
  }
});
test('escalado acerca las kcal al objetivo (±15 %) dentro de 0,6–1,8×', () {
  final o = kMealCatalog.firstWhere((o) => o.id == 'pinto_huevo');
  final s = scaleOption(o, MealTarget(MealSlot.breakfast, 650, 40));
  expect(s.kcal, inInclusiveRange(552, 748));
});
test('proteína baja sube primero el ingrediente protein', () {
  // avena con banano a 600 kcal / 40 g: proteinG ≥ 32 (80 %)
});
test('objetivo enorme (1400 kcal) se limita a 1,8× la base', ...);
test('etiquetas en medidas caseras: unidades en medios, gramos múltiplos de 10', ...);
test('precio = suma de gramos × precio/kg, entero', ...);
```

- [ ] **Step 2: Run and see them fail.**
- [ ] **Step 3: Implement**
  - `foods.dart`: valores por 100 g de INCAP/USDA; medidas caseras (gallo pinto 1 taza = 160 g, huevo = 50 g, tortilla de maíz = 30 g, rebanada de pan = 28 g, banano = 120 g, plátano maduro ½ = 100 g, aguacate ¼ = 50 g, taza leche = 240 g, avena ½ taza = 40 g); precios aprox. nov 2026 por kg (arroz ~₡800, frijoles ~₡1.400, huevo ~₡1.700, pechuga ~₡4.700, plátano ~₡820…). Comentario de cabecera con fuentes y fecha.
  - `meal_catalog.dart`: opciones de la spec (Desayuno 9, Almuerzo 9, Merienda 7, Cena 6 + completar a 8). Ids snake_case (`pinto_huevo`, `avena_banano`, `casado_pollo`…). Garantizar ≥ 1 opción sin `dairy/egg/seafood/red_meat/pork` en cada tiempo (p. ej. arroz con frijoles y maduro; banano con maní; tortillas con pollo; arroz con pollo).
  - `meal_scaler.dart`: factor = clamp(t.kcal / kcalBase, 0,6, 1,8); si proteína < 80 % de `t.proteinG`, subir `protein` hasta 1,8× de su base y bajar `carb` para compensar kcal; redondear unidades a 0,5 y gramos a 10; recalcular kcal/proteína/precio con las cantidades redondeadas.
- [ ] **Step 4: Run tests** → PASS.
- [ ] **Step 5: Commit** `feat(nutrition): recetario tico y escalado de porciones`.

### Task 3: Datos del socio (BD + modelo + guardado)

**Files:**
- Create: `database/alimentacion_migration.sql`
- Modify: `lib/features/auth/models/user.dart` (campos, `fromJson`, `toJson`, `copyWith`)
- Modify: `lib/features/auth/providers/auth_provider.dart` (método nuevo)
- Create: `lib/features/nutrition/services/nutrition_prefs.dart`
- Test: `test/models/user_test.dart` (ampliar), `test/services/nutrition_prefs_test.dart`

**Interfaces:**
- Consumes: `ActivityLevel`, `NutritionGoal`, `goalToLabel` (Task 1).
- Produces:
  - `User.activityLevel` (`String?`), `User.foodAvoid` (`List<String>`, default `[]`), `User.mealsPerDay` (`int?`); JSON `activity_level`, `food_avoid`, `meals_per_day`
  - `Future<void> AuthProvider.saveNutritionProfile({required double weightKg, required int heightCm, required int age, required String sex, required NutritionGoal goal, required ActivityLevel activity, required Set<String> avoid, required int mealsPerDay, required bool weightChanged})` — actualiza `users` (incluye `goal` vía `goalToLabel(goal, current: user.goal)`), y si `weightChanged` inserta en `body_measurements` `{user_id, date: hoy, weight}`; actualiza `_currentUser` y guarda copia local; si falla la red, guarda local y no lanza.
  - `class NutritionPrefs { static Future<void> save(String userId, Map<String, dynamic> data); static Future<Map<String, dynamic>?> load(String userId); }` (clave `nutrition_profile_<userId>`)

- [ ] **Step 1: SQL** — columnas `activity_level text check (activity_level in ('sedentary','standing','physical'))`, `food_avoid text[] not null default '{}'`, `meals_per_day smallint check (meals_per_day between 3 and 5)`; `add column if not exists`; `drop constraint if exists` antes de cada `add constraint`; envuelto en `begin; … commit;`.
- [ ] **Step 2: Revisión** — agente `supabase-reviewer` sobre el script; corregir lo que reporte.
- [ ] **Step 3: Aplicar** con `mcp__Supabase__apply_migration` (nombre `alimentacion`); si el MCP no conecta, dejar la guía en el PR.
- [ ] **Step 4: Failing tests** — `User.fromJson` lee los 3 campos (y `food_avoid` nulo → `[]`); `toJson` los escribe; `NutritionPrefs` guarda y recupera (SharedPreferences mock).
- [ ] **Step 5: Implement** modelo, `NutritionPrefs` y `saveNutritionProfile`.
- [ ] **Step 6: Run tests** → PASS. **Commit** `feat(nutrition): perfil alimentario del socio`.

### Task 4: Navegación — pestaña Comida y chat en Hoy

**Files:**
- Modify: `lib/shared/navigation/role_tabs.dart`
- Modify: `lib/config/router/app_router.dart` (ruta `/comida` dentro del `ShellRoute`, placeholder `NutritionScreen` de Task 6 o `SizedBox` temporal)
- Modify: `lib/features/home/screens/home_screen.dart:173-205` (cabecera)
- Test: `test/models/chat_test.dart` (actualizar), `test/widgets/home_chat_button_test.dart`

**Interfaces:**
- Produces: `NavTabSpec _nutritionTab` (path `/comida`, label "Comida", iconos `Icons.restaurant_outlined` / `Icons.restaurant`, prefixes `['/comida']`); `class ChatHeaderButton extends StatelessWidget` en `lib/features/chat/widgets/chat_header_button.dart` (escucha `ChatService.unread`, muestra número si > 0, `context.push('/chat')`).

- [ ] **Step 1: Failing tests**

```dart
test('socio con y sin entrenador tienen Comida en lugar de Chat', () {
  expect(tabsFor(NavRole.member, hasTrainer: true).map((t) => t.path),
         ['/home', '/progress', '/comida', '/profile']);
  expect(tabsFor(NavRole.member).map((t) => t.path),
         ['/home', '/progress', '/comida', '/profile']);
  expect(trainerTabs.map((t) => t.path), contains('/chats'));
});
testWidgets('ChatHeaderButton muestra no leídos y navega a /chat', ...);
```

- [ ] **Step 2: Run, see fail. Step 3: Implement** — `memberTabs` y `memberWithTrainerTabs` iguales con `_nutritionTab` en la posición 2; eliminar `_memberChatTab`. En la cabecera de Hoy, a la derecha del saludo, `ChatHeaderButton` solo si `currentUser.trainerId != null`. Mantener `/chat` y la redirección `/chats → /chat`.
- [ ] **Step 4: Run tests** → PASS. **Commit** `feat(nav): pestaña Comida; chat del socio en la cabecera de Hoy`.

### Task 5: Cuestionario de 3 pasos

**Files:**
- Create: `lib/features/nutrition/screens/nutrition_setup_screen.dart`
- Test: `test/widgets/nutrition_setup_test.dart`

**Interfaces:**
- Consumes: `AuthProvider.saveNutritionProfile`, `BodyMeasurementProvider.latestOf(MeasureField.weight)`, `goalFromLabel`, `ActivityLevel`.
- Produces: `NutritionSetupScreen({bool editing = false})`; al terminar hace `Navigator.pop(context, true)`.
- Helper puro (mismo archivo, testeable): `bool needsNutritionSetup(User u)` → true si falta `age`, `heightCm`, `sex`, peso (users o medida), `activityLevel` o `mealsPerDay`.

- [ ] **Step 1: Failing tests** — `needsNutritionSetup` con cada campo nulo → true; completo → false. Widget: paso 1 muestra los datos actuales y los textos "Con esto calculamos cuánta energía gasta tu cuerpo" y "Define si comes un poco más, igual o un poco menos"; un menor no ve "Bajar grasa"; "Siguiente" deshabilitado en paso 2 sin elegir actividad; paso 3 permite multi-selección y 3/4/5 (default 4); "Listo" llama a `saveNutritionProfile` con `weightChanged` = (peso editado ≠ inicial).
- [ ] **Step 2: Run, see fail. Step 3: Implement** con los textos exactos de la spec (sección Cuestionario). Peso inicial = medida más reciente o `users.weight_kg`. Editar datos del paso 1 en línea (stepper +/−, sin abrir otra pantalla). Botón grande inferior "Siguiente"/"Listo"; indicador "Paso N de 3".
- [ ] **Step 4: Run tests** → PASS. **Commit** `feat(nutrition): cuestionario de 3 pasos`.

### Task 6: Pantalla Comida

**Files:**
- Create: `lib/features/nutrition/providers/nutrition_provider.dart`
- Create: `lib/features/nutrition/services/meal_choice_store.dart`
- Create: `lib/features/nutrition/screens/nutrition_screen.dart`
- Create: `lib/features/nutrition/widgets/meal_option_tile.dart`
- Modify: `lib/main.dart` (registrar `NutritionProvider`), `lib/config/router/app_router.dart` (`/comida` → `NutritionScreen`)
- Test: `test/services/meal_choice_store_test.dart`, `test/widgets/nutrition_screen_test.dart`

**Interfaces:**
- Consumes: Tasks 1–5.
- Produces:
  - `NutritionProvider` (ChangeNotifier): `Future<void> load(User u, double? latestWeight)` (lee días de entreno: `select day_of_week from user_workout_schedule where user_id = u.id`, días distintos; sin red o vacío → 3), `NutritionProfile? profile`, `DailyTargets? targets`.
  - `MealSlot defaultSlot(DateTime now, List<MealSlot> slots)` — <10 desayuno, 10–12 snackAm, 12–15 almuerzo, 15–18 snackPm, ≥18 cena; si no existe en `slots`, la siguiente que exista; si ninguna posterior, la última.
  - `class MealChoiceStore { static Future<Map<MealSlot, String>> today(String userId, {DateTime? now}); static Future<void> choose(String userId, MealSlot s, String optionId, {DateTime? now}); }` — clave por fecha `meal_choice_<userId>_<yyyy-mm-dd>`; otro día → vacío.

- [ ] **Step 1: Failing tests**

```dart
test('defaultSlot con 3 comidas a las 11:00 → almuerzo', () {
  expect(defaultSlot(DateTime(2026,11,22,11), slotsFor(3)), MealSlot.lunch);
});
test('defaultSlot a las 21:00 → cena', ...);
test('MealChoiceStore se reinicia al cambiar de día', ...);
testWidgets('sin datos completos muestra invitación al cuestionario', ...);
testWidgets('con perfil: kcal y proteína en grande, chips por comida, opciones con ~₡ y aviso', ...);
testWidgets('con todas las exclusiones muestra "Pocas opciones con tus restricciones"', ...);
testWidgets('menor de 18 ve el aviso de nutricionista y encargado', ...);
testWidgets('Elegir marca la opción y el pie suma kcal, proteína y costo', ...);
```

- [ ] **Step 2: Run, see fail. Step 3: Implement** la pantalla de la spec (sección Pantalla Comida, maqueta incluida): cabecera "COMIDA · <OBJETIVO>" + botón "Ajustar" (abre `NutritionSetupScreen(editing: true)` y recarga); números kcal/proteína grandes; chips de `slotsFor(meals)`; lista de `optionsFor` escaladas; tile expandible con ingredientes; "Elegir" con animación breve (escala + check, ≤ 250 ms); pie "Tu día: N de M comidas elegidas · ~₡X"; aviso fijo; "Precios aprox. nov 2026". Si `needsNutritionSetup`, estado vacío con botón "Armar mi plan" que abre el cuestionario.
- [ ] **Step 4: Run tests** → PASS.
- [ ] **Step 5: Visual** — build web, servir, Playwright 390×844 con un socio de prueba: cuestionario (3 pasos), pantalla, opción desplegada, botón de chat en Hoy. Datos de prueba creados y borrados al final.
- [ ] **Step 6: Commit** `feat(nutrition): pantalla Comida con opciones ajustadas`.

### Task 7: Cierre

**Files:**
- Modify: `CLAUDE.md` (sección Dominio)

- [ ] **Step 1:** Reemplazar "Foco: rutinas y ejercicios por semana. **No hay** planes de alimentación (eliminados)." por "Foco: rutinas y ejercicios por semana. Hay una guía de alimentación con recetario fijo en la app (`features/nutrition`); no hay planes asignados por el entrenador."; agregar `nutrition` a la lista de dominios.
- [ ] **Step 2:** `flutter analyze --no-fatal-infos` (0 errores) y `flutter test` (todo verde).
- [ ] **Step 3:** Commit, push a `claude/ecstatic-curie-gi8kq3` y PR contra `main` con guía de `database/alimentacion_migration.sql` (indicar si ya se aplicó).
