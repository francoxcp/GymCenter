import '../models/nutrition_profile.dart';
import '../services/portions.dart';
import 'foods.dart';

/// Un alimento del plato y qué parte de las porciones de su grupo cubre
/// (p. ej. en el casado, el arroz cubre ½ de las harinas y los frijoles ½).
class Component {
  final String foodId;
  final FoodGroup group;
  final double share;
  const Component(this.foodId, this.group, [this.share = 1]);
}

/// Un plato armado. Las cantidades salen de las porciones de cada socio.
class MealOption {
  final String id;
  final String name;
  final Set<MealSlot> slots;
  final List<Component> components;

  /// Listo en 10 minutos o menos.
  final bool quick;

  const MealOption({
    required this.id,
    required this.name,
    required this.slots,
    required this.components,
    this.quick = false,
  });

  /// Exclusiones (lácteos, huevo…) que contiene.
  Set<String> get tags => {
        for (final c in components) ...?kFoods[c.foodId]?.tags,
      };
}

const _h = FoodGroup.harina;
const _p = FoodGroup.proteina;
const _g = FoodGroup.grasa;
const _f = FoodGroup.fruta;
const _v = FoodGroup.vegetal;

const _b = {MealSlot.breakfast};
const _l = {MealSlot.lunch};
const _d = {MealSlot.dinner};
const _s = {MealSlot.snackPm};
const _am = {MealSlot.snackAm};

/// Recetario por porciones: comida tica, preparaciones bajas en grasa
/// (plancha, horno, vapor, freidora de aire) y proteína pesada cocinada.
const List<MealOption> kMealCatalog = [
  // ── Desayuno: harina + proteína + grasa ──
  MealOption(id: 'tortiricas_huevo_jamon', name: 'Tortiricas con huevo, jamón de pavo, hongos y cebollino',
      quick: true, slots: _b, components: [
    Component('tortirica', _h), Component('huevo', _p, .6), Component('jamon', _p, .4), Component('aceite', _g),
  ]),
  MealOption(id: 'pinto_huevos_rancheros', name: 'Gallo pinto con huevos en salsa ranchera y queso', slots: _b,
      components: [
    Component('gallo_pinto', _h), Component('huevo', _p, .6), Component('queso', _p, .4), Component('aceite', _g),
  ]),
  MealOption(id: 'tostada_aguacate_huevos', name: 'Tostada integral con aguacate y huevos', quick: true, slots: _b,
      components: [
    Component('pan', _h), Component('huevo', _p), Component('aguacate', _g),
  ]),
  MealOption(id: 'tortilla_huevo_queso', name: 'Tortilla casera con huevo y queso', quick: true, slots: _b,
      components: [
    Component('tortilla', _h), Component('huevo', _p, .6), Component('queso', _p, .4), Component('aceite', _g),
  ]),
  MealOption(id: 'revueltos_tomate', name: 'Huevos revueltos con tomate y cebollino, con tortilla', quick: true,
      slots: _b, components: [
    Component('tortilla', _h), Component('huevo', _p), Component('aceite', _g),
  ]),
  MealOption(id: 'emparedado_pavo_queso', name: 'Emparedado integral de pavo, queso, tomate y aguacate', quick: true,
      slots: _b, components: [
    Component('pan', _h), Component('jamon', _p, .5), Component('queso', _p, .5), Component('aguacate', _g),
  ]),
  MealOption(id: 'avena_yogur_mani', name: 'Avena con yogur griego y maní', quick: true, slots: _b, components: [
    Component('avena', _h), Component('yogur', _p), Component('mani', _g),
  ]),
  MealOption(id: 'pancakes_avena', name: 'Pancakes de avena con huevo y yogur griego', slots: _b, components: [
    Component('avena', _h), Component('huevo', _p, .5), Component('yogur', _p, .5), Component('aceite', _g),
  ]),
  MealOption(id: 'maduro_huevo_queso', name: 'Plátano maduro al horno con huevo y queso', slots: _b, components: [
    Component('platano', _h), Component('huevo', _p, .6), Component('queso', _p, .4), Component('aceite', _g),
  ]),
  MealOption(id: 'galletas_atun_aguacate', name: 'Galletas integrales con atún y aguacate', quick: true, slots: _b,
      components: [
    Component('galletas', _h), Component('atun', _p), Component('aguacate', _g),
  ]),
  MealOption(id: 'pinto_pollo', name: 'Gallo pinto con pollo desmenuzado y aguacate', slots: _b, components: [
    Component('gallo_pinto', _h), Component('pollo', _p), Component('aguacate', _g),
  ]),

  MealOption(id: 'tortilla_pollo_aguacate', name: 'Tortilla casera con pollo desmenuzado y aguacate', quick: true,
      slots: _b, components: [
    Component('tortilla', _h), Component('pollo', _p), Component('aguacate', _g),
  ]),

  // ── Almuerzo: harinas + proteína + vegetal + grasa ──
  MealOption(id: 'casado_pollo', name: 'Casado medido de pollo a la plancha', slots: _l, components: [
    Component('arroz', _h, .5), Component('frijoles', _h, .5), Component('pollo', _p),
    Component('ensalada', _v), Component('aceite', _g),
  ]),
  MealOption(id: 'casado_res', name: 'Casado medido de bistec a la plancha', slots: _l, components: [
    Component('arroz', _h, .5), Component('frijoles', _h, .5), Component('res', _p),
    Component('ensalada', _v), Component('aceite', _g),
  ]),
  MealOption(id: 'pasta_atun', name: 'Pasta integral en salsa de tomate natural con atún', slots: _l, components: [
    Component('pasta', _h), Component('atun', _p), Component('vegetales', _v), Component('aceite', _g),
  ]),
  MealOption(id: 'papas_fajitas', name: 'Papas en freidora de aire con fajitas de res', slots: _l, components: [
    Component('papa', _h), Component('res', _p), Component('ensalada', _v), Component('aceite', _g),
  ]),
  MealOption(id: 'lentejas_pollo', name: 'Lentejas con arroz y pollo mechado', slots: _l, components: [
    Component('lentejas', _h, .5), Component('arroz', _h, .5), Component('pollo', _p), Component('ensalada', _v), Component('aceite', _g),
  ]),
  MealOption(id: 'garbanzos_carne', name: 'Garbanzos con arroz y carne en trocitos', slots: _l, components: [
    Component('garbanzos', _h, .5), Component('arroz', _h, .5), Component('res', _p), Component('ensalada', _v), Component('aceite', _g),
  ]),
  MealOption(id: 'arroz_pollo', name: 'Arroz con pollo y vegetales', slots: _l, components: [
    Component('arroz', _h), Component('pollo', _p), Component('vegetales', _v), Component('aceite', _g),
  ]),
  MealOption(id: 'pescado_camote', name: 'Pescado al horno con camote', slots: _l, components: [
    Component('camote', _h), Component('pescado', _p), Component('ensalada', _v), Component('aceite', _g),
  ]),
  MealOption(id: 'picadillo_papa', name: 'Picadillo de papa con carne molida y arroz', slots: _l, components: [
    Component('papa', _h, .5), Component('arroz', _h, .5), Component('molida', _p),
    Component('chayote', _v), Component('aceite', _g),
  ]),
  MealOption(id: 'olla_carne', name: 'Olla de carne', slots: _l, components: [
    Component('papa', _h, .5), Component('yuca', _h, .5), Component('res', _p),
    Component('chayote', _v), Component('aceite', _g),
  ]),
  MealOption(id: 'chuleta_cerdo', name: 'Lomo de cerdo a la plancha con arroz y frijoles', slots: _l, components: [
    Component('arroz', _h, .5), Component('frijoles', _h, .5), Component('cerdo', _p),
    Component('ensalada', _v), Component('aceite', _g),
  ]),
  MealOption(id: 'arroz_frijoles_huevo', name: 'Arroz, frijoles y maduro con huevo y queso (sin carne)', slots: _l,
      components: [
    Component('arroz', _h, .4), Component('frijoles', _h, .3), Component('platano', _h, .3),
    Component('huevo', _p, .4),
    Component('queso', _p, .6), Component('ensalada', _v), Component('aceite', _g),
  ]),

  // ── Merienda de la tarde: harina + proteína (+ fruta) ──
  MealOption(id: 'galletas_queso', name: 'Galletas integrales con queso y jamón de pavo', quick: true, slots: _s,
      components: [
    Component('galletas', _h), Component('queso', _p, .4), Component('jamon', _p, .6),
  ]),
  MealOption(id: 'tortilla_queso', name: 'Tortilla casera con queso y pollo desmenuzado', quick: true, slots: _s,
      components: [
    Component('tortilla', _h), Component('queso', _p, .4), Component('pollo', _p, .6),
  ]),
  MealOption(id: 'yogur_granola', name: 'Yogur griego con granola', quick: true, slots: _s, components: [
    Component('granola', _h), Component('yogur', _p),
  ]),
  MealOption(id: 'pancakes_merienda', name: 'Pancakes de avena con huevo', slots: _s, components: [
    Component('avena', _h), Component('huevo', _p),
  ]),
  MealOption(id: 'tortilla_harina_jamon', name: 'Tortilla de harina con queso y jamón de pavo', quick: true, slots: _s,
      components: [
    Component('tortilla_harina', _h), Component('queso', _p, .5), Component('jamon', _p, .5),
  ]),
  MealOption(id: 'pan_atun', name: 'Pan integral con atún', quick: true, slots: _s, components: [
    Component('pan', _h), Component('atun', _p),
  ]),
  MealOption(id: 'huevos_galletas', name: 'Huevos duros con galletas integrales', quick: true, slots: _s,
      components: [
    Component('galletas', _h), Component('huevo', _p),
  ]),
  MealOption(id: 'tostada_pavo', name: 'Tostada integral con jamón de pavo', quick: true, slots: _s, components: [
    Component('pan', _h), Component('jamon', _p),
  ]),

  MealOption(id: 'galletas_pollo', name: 'Galletas integrales con pollo mechado', quick: true, slots: _s,
      components: [
    Component('galletas', _h), Component('pollo', _p),
  ]),

  // ── Cena: harina + proteína + vegetal + grasa ──
  MealOption(id: 'galletas_pollo_aguacate', name: 'Galletas integrales con pollo mechado y aguacate', quick: true,
      slots: _d, components: [
    Component('galletas', _h), Component('pollo', _p), Component('ensalada', _v), Component('aguacate', _g),
  ]),
  MealOption(id: 'emparedado_pollo', name: 'Emparedado integral de pollo con lechuga y tomate', quick: true, slots: _d,
      components: [
    Component('pan', _h), Component('pollo', _p, .7), Component('queso', _p, .3),
    Component('ensalada', _v), Component('aguacate', _g),
  ]),
  MealOption(id: 'burrito_pollo', name: 'Burrito de pollo con vegetales', slots: _d, components: [
    Component('tortilla_harina', _h), Component('pollo', _p), Component('ensalada', _v), Component('aceite', _g),
  ]),
  MealOption(id: 'galletas_atun_huevo', name: 'Galletas con atún, huevo duro y aguacate', quick: true, slots: _d,
      components: [
    Component('galletas', _h), Component('atun', _p, .7), Component('huevo', _p, .3),
    Component('ensalada', _v), Component('aguacate', _g),
  ]),
  MealOption(id: 'garbanzos_pollo', name: 'Garbanzos con pollo mechado y aguacate', slots: _d, components: [
    Component('garbanzos', _h), Component('pollo', _p), Component('ensalada', _v), Component('aguacate', _g),
  ]),
  MealOption(id: 'ceviche', name: 'Ceviche de pescado con galletas', slots: _d, components: [
    Component('galletas', _h), Component('pescado', _p), Component('ensalada', _v), Component('aguacate', _g),
  ]),
  MealOption(id: 'chalupas', name: 'Tortillas con frijoles molidos y carne molida', slots: _d, components: [
    Component('tortilla', _h, .5), Component('frijoles', _h, .5), Component('molida', _p),
    Component('ensalada', _v), Component('aceite', _g),
  ]),
  MealOption(id: 'tortiricas_pollo', name: 'Tortiricas con pollo asado y ensalada', quick: true, slots: _d,
      components: [
    Component('tortirica', _h), Component('pollo', _p), Component('ensalada', _v), Component('aceite', _g),
  ]),
  MealOption(id: 'huevos_vainica', name: 'Huevos revueltos con vainica y tortilla', quick: true, slots: _d,
      components: [
    Component('tortilla', _h), Component('huevo', _p, .6), Component('queso', _p, .4),
    Component('vainica', _v), Component('aceite', _g),
  ]),
  MealOption(id: 'tostitos_guacamole', name: 'Tostitos con carne molida, guacamole y pico de gallo', slots: _d,
      components: [
    Component('tostitos', _h), Component('molida', _p), Component('ensalada', _v), Component('aguacate', _g),
  ]),
  MealOption(id: 'pollo_camote', name: 'Pollo a la plancha con camote y vainicas', slots: _d, components: [
    Component('camote', _h), Component('pollo', _p), Component('vainica', _v), Component('aceite', _g),
  ]),

  // ── Merienda de la mañana: fruta ──
  MealOption(id: 'fruta_manzana', name: 'Manzana', quick: true, slots: _am, components: [Component('manzana', _f)]),
  MealOption(id: 'fruta_mandarina', name: 'Mandarina', quick: true, slots: _am,
      components: [Component('mandarina', _f)]),
  MealOption(id: 'fruta_guayaba', name: 'Guayaba', quick: true, slots: _am, components: [Component('guayaba', _f)]),
  MealOption(id: 'fruta_papaya', name: 'Papaya', quick: true, slots: _am, components: [Component('papaya', _f)]),
  MealOption(id: 'fruta_pina', name: 'Piña', quick: true, slots: _am, components: [Component('pina', _f)]),
  MealOption(id: 'fruta_banano', name: 'Banano', quick: true, slots: _am, components: [Component('banano', _f)]),
  MealOption(id: 'fruta_sandia', name: 'Sandía', quick: true, slots: _am, components: [Component('sandia', _f)]),
];
