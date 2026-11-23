import '../models/nutrition_profile.dart';
import 'foods.dart';

/// Para qué sirve el ingrediente al ajustar porciones.
enum IngredientRole { protein, carb, fat, veg }

class Ingredient {
  final String foodId;
  final double grams;
  final IngredientRole role;
  const Ingredient(this.foodId, this.grams, this.role);
}

/// Una opción de comida, con cantidades base para una persona promedio.
class MealOption {
  final String id;
  final String name;
  final Set<MealSlot> slots;
  final List<Ingredient> ingredients;

  /// Lista en 10 minutos o menos.
  final bool quick;

  const MealOption({
    required this.id,
    required this.name,
    required this.slots,
    required this.ingredients,
    this.quick = false,
  });

  /// Exclusiones (lácteos, huevo…) que contiene.
  Set<String> get tags => {
        for (final i in ingredients) ...?kFoods[i.foodId]?.tags,
      };
}

const _p = IngredientRole.protein;
const _c = IngredientRole.carb;
const _f = IngredientRole.fat;
const _v = IngredientRole.veg;

const _b = {MealSlot.breakfast};
const _l = {MealSlot.lunch};
const _s = {MealSlot.snackAm, MealSlot.snackPm};
const _d = {MealSlot.dinner};

/// Recetario: comida tica, de pulpería o feria, presupuesto estándar.
const List<MealOption> kMealCatalog = [
  // ── Desayuno ──
  MealOption(id: 'pinto_huevo', name: 'Gallo pinto con huevo', quick: true,
      slots: {MealSlot.breakfast, MealSlot.dinner}, ingredients: [
    Ingredient('gallo_pinto', 160, _c),
    Ingredient('huevo', 100, _p),
    Ingredient('tortilla', 30, _c),
  ]),
  MealOption(id: 'avena_banano', name: 'Avena con leche y banano', quick: true, slots: _b, ingredients: [
    Ingredient('avena', 40, _c),
    Ingredient('leche', 240, _p),
    Ingredient('banano', 120, _c),
  ]),
  MealOption(id: 'tortilla_queso_huevo', name: 'Tortillas con queso tierno y huevo', quick: true,
      slots: _b, ingredients: [
    Ingredient('tortilla', 60, _c),
    Ingredient('queso', 40, _p),
    Ingredient('huevo', 50, _p),
  ]),
  MealOption(id: 'pan_huevo_aguacate', name: 'Pan integral con huevo y aguacate', quick: true,
      slots: _b, ingredients: [
    Ingredient('pan', 56, _c),
    Ingredient('huevo', 100, _p),
    Ingredient('aguacate', 50, _f),
  ]),
  MealOption(id: 'batido_avena', name: 'Batido de avena, leche, banano y maní', quick: true,
      slots: _b, ingredients: [
    Ingredient('avena', 40, _c),
    Ingredient('leche', 240, _p),
    Ingredient('banano', 120, _c),
    Ingredient('mani', 15, _f),
  ]),
  MealOption(id: 'pinto_natilla_maduro', name: 'Gallo pinto con natilla y maduro', slots: _b, ingredients: [
    Ingredient('gallo_pinto', 160, _c),
    Ingredient('natilla', 30, _f),
    Ingredient('platano', 100, _c),
    Ingredient('huevo', 50, _p),
  ]),
  MealOption(id: 'papaya_queso_huevo', name: 'Papaya con queso tierno y huevo duro', quick: true,
      slots: _b, ingredients: [
    Ingredient('papaya', 200, _v),
    Ingredient('queso', 40, _p),
    Ingredient('huevo', 50, _p),
    Ingredient('tortilla', 30, _c),
  ]),
  MealOption(id: 'yogur_granola', name: 'Yogur con granola y piña', quick: true, slots: _b, ingredients: [
    Ingredient('yogur', 200, _p),
    Ingredient('granola', 40, _c),
    Ingredient('pina', 100, _v),
  ]),
  MealOption(id: 'pinto_pollo', name: 'Gallo pinto con pollo desmenuzado y maduro', slots: _b, ingredients: [
    Ingredient('gallo_pinto', 160, _c),
    Ingredient('pollo', 60, _p),
    Ingredient('platano', 100, _c),
  ]),

  // ── Almuerzo ──
  MealOption(id: 'casado_pollo', name: 'Casado de pollo', slots: _l, ingredients: [
    Ingredient('arroz', 160, _c),
    Ingredient('frijoles', 85, _c),
    Ingredient('pollo', 100, _p),
    Ingredient('ensalada', 80, _v),
    Ingredient('platano', 100, _c),
  ]),
  MealOption(id: 'casado_res', name: 'Casado de res', slots: _l, ingredients: [
    Ingredient('arroz', 160, _c),
    Ingredient('frijoles', 85, _c),
    Ingredient('res', 100, _p),
    Ingredient('ensalada', 80, _v),
    Ingredient('platano', 100, _c),
  ]),
  MealOption(id: 'arroz_pollo', name: 'Arroz con pollo y ensalada', slots: _l, ingredients: [
    Ingredient('arroz', 200, _c),
    Ingredient('pollo', 90, _p),
    Ingredient('ensalada', 80, _v),
    Ingredient('aceite', 5, _f),
  ]),
  MealOption(id: 'olla_carne', name: 'Olla de carne', slots: _l, ingredients: [
    Ingredient('res', 100, _p),
    Ingredient('papa', 100, _c),
    Ingredient('yuca', 100, _c),
    Ingredient('chayote', 80, _v),
    Ingredient('arroz', 100, _c),
  ]),
  MealOption(id: 'picadillo_papa', name: 'Picadillo de papa con carne molida', slots: _l, ingredients: [
    Ingredient('molida', 80, _p),
    Ingredient('papa', 150, _c),
    Ingredient('arroz', 160, _c),
    Ingredient('tortilla', 30, _c),
  ]),
  MealOption(id: 'arroz_frijoles_atun', name: 'Arroz, frijoles y atún con ensalada', quick: true,
      slots: _l, ingredients: [
    Ingredient('arroz', 160, _c),
    Ingredient('frijoles', 85, _c),
    Ingredient('atun', 120, _p),
    Ingredient('ensalada', 80, _v),
  ]),
  MealOption(id: 'sopa_negra', name: 'Sopa negra con huevo', slots: _l, ingredients: [
    Ingredient('frijoles', 200, _c),
    Ingredient('huevo', 100, _p),
    Ingredient('arroz', 100, _c),
  ]),
  MealOption(id: 'tilapia_arroz', name: 'Tilapia con arroz y ensalada', slots: _l, ingredients: [
    Ingredient('tilapia', 120, _p),
    Ingredient('arroz', 160, _c),
    Ingredient('ensalada', 80, _v),
    Ingredient('aceite', 5, _f),
  ]),
  MealOption(id: 'arroz_frijoles_huevo_maduro', name: 'Arroz, frijoles, huevo y maduro', slots: _l, ingredients: [
    Ingredient('arroz', 160, _c),
    Ingredient('frijoles', 85, _c),
    Ingredient('huevo', 100, _p),
    Ingredient('platano', 100, _c),
  ]),
  MealOption(id: 'chuleta_cerdo', name: 'Chuleta de cerdo con arroz y frijoles', slots: _l, ingredients: [
    Ingredient('cerdo', 100, _p),
    Ingredient('arroz', 160, _c),
    Ingredient('frijoles', 85, _c),
    Ingredient('ensalada', 80, _v),
  ]),

  // ── Merienda ──
  MealOption(id: 'banano_mani', name: 'Banano con maní', quick: true, slots: _s, ingredients: [
    Ingredient('banano', 120, _c),
    Ingredient('mani', 25, _p),
  ]),
  MealOption(id: 'yogur_fruta', name: 'Yogur natural con piña', quick: true, slots: _s, ingredients: [
    Ingredient('yogur', 200, _p),
    Ingredient('pina', 100, _c),
  ]),
  MealOption(id: 'pan_atun', name: 'Pan integral con atún', quick: true, slots: _s, ingredients: [
    Ingredient('pan', 56, _c),
    Ingredient('atun', 60, _p),
  ]),
  MealOption(id: 'huevo_fruta', name: 'Huevos duros y banano', quick: true, slots: _s, ingredients: [
    Ingredient('huevo', 100, _p),
    Ingredient('banano', 120, _c),
  ]),
  MealOption(id: 'pinto_pequeno', name: 'Gallo pinto pequeño con tortilla', quick: true, slots: _s, ingredients: [
    Ingredient('gallo_pinto', 80, _c),
    Ingredient('tortilla', 30, _c),
    Ingredient('pollo', 30, _p),
  ]),
  MealOption(id: 'batido_leche_fruta', name: 'Batido de leche con fruta', quick: true, slots: _s, ingredients: [
    Ingredient('leche', 240, _p),
    Ingredient('papaya', 150, _c),
  ]),
  MealOption(id: 'galletas_queso', name: 'Galletas de soda con queso tierno', quick: true, slots: _s,
      ingredients: [
    Ingredient('galletas', 26, _c),
    Ingredient('queso', 30, _p),
  ]),

  // ── Cena ──
  MealOption(id: 'tortillas_pollo', name: 'Tortillas con pollo desmenuzado', quick: true, slots: _d,
      ingredients: [
    Ingredient('tortilla', 60, _c),
    Ingredient('pollo', 90, _p),
    Ingredient('ensalada', 80, _v),
  ]),
  MealOption(id: 'picadillo_chayote', name: 'Picadillo de chayote con carne molida', slots: _d, ingredients: [
    Ingredient('chayote', 150, _v),
    Ingredient('molida', 80, _p),
    Ingredient('arroz', 120, _c),
    Ingredient('tortilla', 30, _c),
  ]),
  MealOption(id: 'huevos_vainica', name: 'Huevos revueltos con vainica', quick: true, slots: _d, ingredients: [
    Ingredient('huevo', 150, _p),
    Ingredient('vainica', 100, _v),
    Ingredient('tortilla', 60, _c),
  ]),
  MealOption(id: 'ensalada_atun', name: 'Ensalada de atún con aguacate', quick: true, slots: _d, ingredients: [
    Ingredient('atun', 120, _p),
    Ingredient('aguacate', 50, _f),
    Ingredient('ensalada', 100, _v),
    Ingredient('galletas', 26, _c),
  ]),
  MealOption(id: 'pescado_yuca', name: 'Tilapia con yuca y ensalada', slots: _d, ingredients: [
    Ingredient('tilapia', 120, _p),
    Ingredient('yuca', 150, _c),
    Ingredient('ensalada', 80, _v),
  ]),
  MealOption(id: 'arroz_frijoles_queso', name: 'Arroz con frijoles y queso tierno', quick: true, slots: _d,
      ingredients: [
    Ingredient('arroz', 160, _c),
    Ingredient('frijoles', 85, _c),
    Ingredient('queso', 40, _p),
  ]),
  MealOption(id: 'pollo_papa_vainica', name: 'Pollo a la plancha con papa y vainica', slots: _d, ingredients: [
    Ingredient('pollo', 100, _p),
    Ingredient('papa', 150, _c),
    Ingredient('vainica', 80, _v),
    Ingredient('aceite', 5, _f),
  ]),
];
