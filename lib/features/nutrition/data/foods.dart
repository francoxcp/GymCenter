/// Alimentos del recetario: valores por 100 g ya listos para comer (la
/// proteína animal, pesada cocinada).
///
/// Nutrientes: Tabla de Composición de Alimentos de Centroamérica (INCAP) y
/// USDA FoodData Central, redondeados. Cada alimento indica a qué grupo del
/// sistema de intercambio pertenece y cuántos gramos son una porción
/// (p. ej. 1 harina = ⅓ taza de arroz; 1 proteína = 30 g de pollo cocido).
/// Precios aproximados en colones por kg (MEIC/CNP, nov 2026): no se muestran.
library;

import '../services/portions.dart';

/// Exclusiones que el socio puede marcar.
const kAvoidOptions = <String, String>{
  'dairy': 'Lácteos',
  'egg': 'Huevo',
  'seafood': 'Mariscos y pescado',
  'red_meat': 'Carne roja',
  'pork': 'Cerdo',
};

/// Fecha de los precios de referencia.
const kPricesAsOf = 'nov 2026';

class Food {
  final String id;
  final String name;
  final double kcal100;
  final double protein100;
  final double carb100;
  final double fat100;

  /// Grupo de intercambio y gramos de una porción.
  final FoodGroup group;
  final double portionGrams;

  /// Medida casera: nombre en singular y plural, y gramos por unidad.
  /// Sin medida, la cantidad se muestra en gramos.
  final String? unit;
  final String? unitPlural;
  final double? unitGrams;

  final double priceCrcPerKg;
  final Set<String> tags;

  const Food({
    required this.id,
    required this.name,
    required this.kcal100,
    required this.protein100,
    required this.carb100,
    required this.fat100,
    required this.group,
    required this.portionGrams,
    this.unit,
    this.unitPlural,
    this.unitGrams,
    required this.priceCrcPerKg,
    this.tags = const {},
  });
}

const _h = FoodGroup.harina;
const _p = FoodGroup.proteina;
const _g = FoodGroup.grasa;
const _f = FoodGroup.fruta;
const _v = FoodGroup.vegetal;

const _foods = <Food>[
  // ── Harinas (1 porción ≈ 15 g de carbohidrato) ──
  Food(id: 'gallo_pinto', name: 'gallo pinto', kcal100: 150, protein100: 5.5, carb100: 26, fat100: 2.5,
      group: _h, portionGrams: 160 / 3,
      unit: 'taza de gallo pinto', unitPlural: 'tazas de gallo pinto', unitGrams: 160, priceCrcPerKg: 700),
  Food(id: 'arroz', name: 'arroz', kcal100: 130, protein100: 2.7, carb100: 28, fat100: 0.3,
      group: _h, portionGrams: 160 / 3,
      unit: 'taza de arroz', unitPlural: 'tazas de arroz', unitGrams: 160, priceCrcPerKg: 400),
  Food(id: 'frijoles', name: 'frijoles', kcal100: 132, protein100: 8.9, carb100: 23.7, fat100: 0.5,
      group: _h, portionGrams: 170 / 3,
      unit: 'taza de frijoles', unitPlural: 'tazas de frijoles', unitGrams: 170, priceCrcPerKg: 600),
  Food(id: 'tortilla', name: 'tortilla de maíz', kcal100: 218, protein100: 5.7, carb100: 44.6, fat100: 2.9,
      group: _h, portionGrams: 30,
      unit: 'tortilla casera pequeña', unitPlural: 'tortillas caseras pequeñas', unitGrams: 30, priceCrcPerKg: 1500),
  Food(id: 'tortirica', name: 'tortiricas', kcal100: 420, protein100: 7, carb100: 70, fat100: 12,
      group: _h, portionGrams: 24,
      unit: 'tortirica tradicional', unitPlural: 'tortiricas tradicionales', unitGrams: 12, priceCrcPerKg: 3500),
  Food(id: 'tortilla_harina', name: 'tortilla de harina', kcal100: 300, protein100: 8, carb100: 50, fat100: 8,
      group: _h, portionGrams: 22.5,
      unit: 'tortilla de harina mediana', unitPlural: 'tortillas de harina medianas', unitGrams: 45, priceCrcPerKg: 2500),
  Food(id: 'pan', name: 'pan integral', kcal100: 247, protein100: 13, carb100: 41, fat100: 3.4,
      group: _h, portionGrams: 28,
      unit: 'rebanada de pan integral', unitPlural: 'rebanadas de pan integral', unitGrams: 28, priceCrcPerKg: 2200),
  Food(id: 'galletas', name: 'galletas de soda integrales', kcal100: 420, protein100: 9, carb100: 72, fat100: 10,
      group: _h, portionGrams: 26,
      unit: 'paquetito de galletas de soda integrales', unitPlural: 'paquetitos de galletas de soda integrales',
      unitGrams: 26, priceCrcPerKg: 4000),
  Food(id: 'tostitos', name: 'tostitos horneados', kcal100: 440, protein100: 8, carb100: 72, fat100: 12,
      group: _h, portionGrams: 20, priceCrcPerKg: 5000),
  Food(id: 'platano', name: 'plátano maduro', kcal100: 122, protein100: 1.3, carb100: 32, fat100: 0.4,
      group: _h, portionGrams: 50,
      unit: 'plátano maduro', unitPlural: 'plátanos maduros', unitGrams: 200, priceCrcPerKg: 820),
  Food(id: 'papa', name: 'papa', kcal100: 87, protein100: 1.9, carb100: 20, fat100: 0.1,
      group: _h, portionGrams: 90, priceCrcPerKg: 900),
  Food(id: 'camote', name: 'camote', kcal100: 86, protein100: 1.6, carb100: 20, fat100: 0.1,
      group: _h, portionGrams: 80, priceCrcPerKg: 1100),
  Food(id: 'yuca', name: 'yuca', kcal100: 160, protein100: 1.4, carb100: 38, fat100: 0.3,
      group: _h, portionGrams: 50, priceCrcPerKg: 800),
  Food(id: 'pasta', name: 'pasta integral', kcal100: 124, protein100: 5.3, carb100: 26.5, fat100: 0.5,
      group: _h, portionGrams: 70,
      unit: 'taza de pasta integral', unitPlural: 'tazas de pasta integral', unitGrams: 140, priceCrcPerKg: 1500),
  Food(id: 'lentejas', name: 'lentejas', kcal100: 116, protein100: 9, carb100: 20, fat100: 0.4,
      group: _h, portionGrams: 70,
      unit: 'taza de lentejas', unitPlural: 'tazas de lentejas', unitGrams: 200, priceCrcPerKg: 1200),
  Food(id: 'garbanzos', name: 'garbanzos', kcal100: 164, protein100: 8.9, carb100: 27, fat100: 2.6,
      group: _h, portionGrams: 55,
      unit: 'taza de garbanzos', unitPlural: 'tazas de garbanzos', unitGrams: 165, priceCrcPerKg: 1600),
  Food(id: 'avena', name: 'avena en hojuelas', kcal100: 389, protein100: 16.9, carb100: 66, fat100: 6.9,
      group: _h, portionGrams: 20,
      unit: 'cucharada de avena', unitPlural: 'cucharadas de avena', unitGrams: 10, priceCrcPerKg: 2000),
  Food(id: 'granola', name: 'granola', kcal100: 470, protein100: 10, carb100: 64, fat100: 20,
      group: _h, portionGrams: 20, priceCrcPerKg: 4000),

  // ── Proteínas bajas en grasa (1 porción ≈ 7 g de proteína) ──
  Food(id: 'pollo', name: 'pechuga de pollo (cocida)', kcal100: 165, protein100: 31, carb100: 0, fat100: 3.6,
      group: _p, portionGrams: 30, priceCrcPerKg: 6000),
  Food(id: 'res', name: 'bistec de res (cocido)', kcal100: 200, protein100: 28, carb100: 0, fat100: 9,
      group: _p, portionGrams: 30, priceCrcPerKg: 8000, tags: {'red_meat'}),
  Food(id: 'molida', name: 'carne molida especial (cocida)', kcal100: 215, protein100: 26, carb100: 0, fat100: 12,
      group: _p, portionGrams: 30, priceCrcPerKg: 6000, tags: {'red_meat'}),
  Food(id: 'cerdo', name: 'lomo de cerdo (cocido)', kcal100: 200, protein100: 27, carb100: 0, fat100: 9,
      group: _p, portionGrams: 30, priceCrcPerKg: 6000, tags: {'pork'}),
  Food(id: 'pescado', name: 'pescado (cocido)', kcal100: 128, protein100: 26, carb100: 0, fat100: 2.7,
      group: _p, portionGrams: 30, priceCrcPerKg: 5500, tags: {'seafood'}),
  Food(id: 'atun', name: 'atún en agua', kcal100: 116, protein100: 25.5, carb100: 0, fat100: 0.8,
      group: _p, portionGrams: 30,
      unit: 'lata de atún (escurrido)', unitPlural: 'latas de atún (escurrido)', unitGrams: 120,
      priceCrcPerKg: 5800, tags: {'seafood'}),
  Food(id: 'huevo', name: 'huevo', kcal100: 143, protein100: 12.6, carb100: 0.7, fat100: 9.5,
      group: _p, portionGrams: 50,
      unit: 'huevo', unitPlural: 'huevos', unitGrams: 50, priceCrcPerKg: 1700, tags: {'egg'}),
  Food(id: 'queso', name: 'queso semiduro o tierno', kcal100: 290, protein100: 22, carb100: 3, fat100: 21,
      group: _p, portionGrams: 30, priceCrcPerKg: 4500, tags: {'dairy'}),
  Food(id: 'jamon', name: 'jamón de pavo', kcal100: 110, protein100: 18, carb100: 2, fat100: 3,
      group: _p, portionGrams: 20,
      unit: 'rebanada de jamón de pavo', unitPlural: 'rebanadas de jamón de pavo', unitGrams: 20, priceCrcPerKg: 6500),
  Food(id: 'yogur', name: 'yogur griego natural sin azúcar', kcal100: 60, protein100: 10, carb100: 4, fat100: 0.4,
      group: _p, portionGrams: 80,
      unit: 'taza de yogur griego natural', unitPlural: 'tazas de yogur griego natural', unitGrams: 240,
      priceCrcPerKg: 4000, tags: {'dairy'}),

  // ── Grasas (1 porción ≈ 5 g de grasa) ──
  Food(id: 'aceite', name: 'aceite', kcal100: 884, protein100: 0, carb100: 0, fat100: 100,
      group: _g, portionGrams: 5,
      unit: 'cucharadita de aceite para cocinar', unitPlural: 'cucharaditas de aceite para cocinar', unitGrams: 5,
      priceCrcPerKg: 2500),
  Food(id: 'aguacate', name: 'aguacate', kcal100: 160, protein100: 2, carb100: 8.5, fat100: 14.7,
      group: _g, portionGrams: 30,
      unit: 'cucharada de aguacate', unitPlural: 'cucharadas de aguacate', unitGrams: 15, priceCrcPerKg: 2000),
  Food(id: 'mani', name: 'maní sin sal', kcal100: 567, protein100: 25.8, carb100: 16, fat100: 49,
      group: _g, portionGrams: 10,
      unit: 'cucharada de maní', unitPlural: 'cucharadas de maní', unitGrams: 10, priceCrcPerKg: 4000),

  // ── Frutas (1 porción ≈ 15 g de carbohidrato) ──
  Food(id: 'fruta', name: 'fruta', kcal100: 55, protein100: 0.6, carb100: 14, fat100: 0.2,
      group: _f, portionGrams: 120,
      unit: 'fruta (manzana, pera, mandarina o guayaba)', unitPlural: 'frutas (manzana, pera, mandarina o guayaba)',
      unitGrams: 120, priceCrcPerKg: 1200),
  Food(id: 'manzana', name: 'manzana', kcal100: 52, protein100: 0.3, carb100: 14, fat100: 0.2,
      group: _f, portionGrams: 120, unit: 'manzana pequeña', unitPlural: 'manzanas pequeñas', unitGrams: 120,
      priceCrcPerKg: 1800),
  Food(id: 'mandarina', name: 'mandarina', kcal100: 53, protein100: 0.8, carb100: 13, fat100: 0.3,
      group: _f, portionGrams: 120, unit: 'mandarina', unitPlural: 'mandarinas', unitGrams: 120, priceCrcPerKg: 1000),
  Food(id: 'guayaba', name: 'guayaba', kcal100: 68, protein100: 2.6, carb100: 14, fat100: 1,
      group: _f, portionGrams: 100, unit: 'guayaba', unitPlural: 'guayabas', unitGrams: 100, priceCrcPerKg: 1200),
  Food(id: 'banano', name: 'banano', kcal100: 89, protein100: 1.1, carb100: 23, fat100: 0.3,
      group: _f, portionGrams: 60, unit: 'banano', unitPlural: 'bananos', unitGrams: 120, priceCrcPerKg: 600),
  Food(id: 'papaya', name: 'papaya', kcal100: 43, protein100: 0.5, carb100: 11, fat100: 0.3,
      group: _f, portionGrams: 140, unit: 'taza de papaya', unitPlural: 'tazas de papaya', unitGrams: 140,
      priceCrcPerKg: 700),
  Food(id: 'pina', name: 'piña', kcal100: 50, protein100: 0.5, carb100: 13, fat100: 0.1,
      group: _f, portionGrams: 120, unit: 'rebanada de piña', unitPlural: 'rebanadas de piña', unitGrams: 120,
      priceCrcPerKg: 700),
  Food(id: 'sandia', name: 'sandía', kcal100: 30, protein100: 0.6, carb100: 8, fat100: 0.2,
      group: _f, portionGrams: 200, unit: 'taza de sandía', unitPlural: 'tazas de sandía', unitGrams: 150,
      priceCrcPerKg: 600),

  // ── Vegetales (1 porción = 1 taza cruda o ½ taza cocida) ──
  Food(id: 'ensalada', name: 'ensalada verde', kcal100: 20, protein100: 1, carb100: 4, fat100: 0.2,
      group: _v, portionGrams: 100,
      unit: 'taza de ensalada verde (lechuga, tomate, pepino)', unitPlural: 'tazas de ensalada verde (lechuga, tomate, pepino)',
      unitGrams: 100, priceCrcPerKg: 1000),
  Food(id: 'vegetales', name: 'vegetales al vapor', kcal100: 35, protein100: 2, carb100: 7, fat100: 0.3,
      group: _v, portionGrams: 75,
      unit: 'taza de vegetales al vapor (brócoli, zanahoria, vainica)',
      unitPlural: 'tazas de vegetales al vapor (brócoli, zanahoria, vainica)', unitGrams: 150, priceCrcPerKg: 1200),
  Food(id: 'chayote', name: 'picadillo de chayote', kcal100: 30, protein100: 0.8, carb100: 6, fat100: 0.5,
      group: _v, portionGrams: 75,
      unit: 'taza de picadillo de chayote', unitPlural: 'tazas de picadillo de chayote', unitGrams: 150,
      priceCrcPerKg: 700),
  Food(id: 'vainica', name: 'vainicas', kcal100: 35, protein100: 1.9, carb100: 7.9, fat100: 0.3,
      group: _v, portionGrams: 62.5,
      unit: 'taza de vainicas', unitPlural: 'tazas de vainicas', unitGrams: 125, priceCrcPerKg: 1200),
];

/// Alimentos por id.
final Map<String, Food> kFoods = {for (final f in _foods) f.id: f};
