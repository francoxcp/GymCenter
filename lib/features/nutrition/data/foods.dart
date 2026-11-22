/// Alimentos del recetario: valores por 100 g ya listos para comer.
///
/// Nutrientes: Tabla de Composición de Alimentos de Centroamérica (INCAP) y
/// USDA FoodData Central, redondeados. Precios aproximados en colones por kg
/// del alimento listo (monitoreos MEIC/CNP y supermercados, noviembre 2026).
/// Son una guía: varían por zona y temporada.
library;

/// Exclusiones que el socio puede marcar.
const kAvoidOptions = <String, String>{
  'dairy': 'Lácteos',
  'egg': 'Huevo',
  'seafood': 'Mariscos y pescado',
  'red_meat': 'Carne roja',
  'pork': 'Cerdo',
};

/// Fecha de los precios, para mostrar junto a ellos.
const kPricesAsOf = 'nov 2026';

class Food {
  final String id;
  final String name;
  final double kcal100;
  final double protein100;
  final double carb100;
  final double fat100;

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
    this.unit,
    this.unitPlural,
    this.unitGrams,
    required this.priceCrcPerKg,
    this.tags = const {},
  });
}

const _foods = <Food>[
  Food(id: 'gallo_pinto', name: 'gallo pinto', kcal100: 150, protein100: 5.5, carb100: 26, fat100: 2.5,
      unit: 'taza de gallo pinto', unitPlural: 'tazas de gallo pinto', unitGrams: 160, priceCrcPerKg: 700),
  Food(id: 'arroz', name: 'arroz', kcal100: 130, protein100: 2.7, carb100: 28, fat100: 0.3,
      unit: 'taza de arroz', unitPlural: 'tazas de arroz', unitGrams: 160, priceCrcPerKg: 400),
  Food(id: 'frijoles', name: 'frijoles', kcal100: 132, protein100: 8.9, carb100: 23.7, fat100: 0.5,
      unit: 'taza de frijoles', unitPlural: 'tazas de frijoles', unitGrams: 170, priceCrcPerKg: 600),
  Food(id: 'huevo', name: 'huevo', kcal100: 143, protein100: 12.6, carb100: 0.7, fat100: 9.5,
      unit: 'huevo', unitPlural: 'huevos', unitGrams: 50, priceCrcPerKg: 1700, tags: {'egg'}),
  Food(id: 'tortilla', name: 'tortilla de maíz', kcal100: 218, protein100: 5.7, carb100: 44.6, fat100: 2.9,
      unit: 'tortilla', unitPlural: 'tortillas', unitGrams: 30, priceCrcPerKg: 1500),
  Food(id: 'pan', name: 'pan integral', kcal100: 247, protein100: 13, carb100: 41, fat100: 3.4,
      unit: 'rebanada de pan integral', unitPlural: 'rebanadas de pan integral', unitGrams: 28, priceCrcPerKg: 2200),
  Food(id: 'queso', name: 'queso tierno', kcal100: 300, protein100: 20, carb100: 3, fat100: 24,
      priceCrcPerKg: 4500, tags: {'dairy'}),
  Food(id: 'natilla', name: 'natilla', kcal100: 200, protein100: 3, carb100: 4, fat100: 19,
      priceCrcPerKg: 2800, tags: {'dairy'}),
  Food(id: 'leche', name: 'leche semidescremada', kcal100: 50, protein100: 3.4, carb100: 4.9, fat100: 1.9,
      unit: 'taza de leche', unitPlural: 'tazas de leche', unitGrams: 240, priceCrcPerKg: 1000, tags: {'dairy'}),
  Food(id: 'yogur', name: 'yogur natural', kcal100: 63, protein100: 5.3, carb100: 7, fat100: 1.6,
      priceCrcPerKg: 2000, tags: {'dairy'}),
  Food(id: 'avena', name: 'avena en hojuelas', kcal100: 389, protein100: 16.9, carb100: 66, fat100: 6.9,
      unit: 'cucharada de avena', unitPlural: 'cucharadas de avena', unitGrams: 10, priceCrcPerKg: 2000),
  Food(id: 'banano', name: 'banano', kcal100: 89, protein100: 1.1, carb100: 23, fat100: 0.3,
      unit: 'banano', unitPlural: 'bananos', unitGrams: 120, priceCrcPerKg: 600),
  Food(id: 'platano', name: 'plátano maduro', kcal100: 140, protein100: 1.3, carb100: 33, fat100: 0.4,
      unit: 'plátano maduro', unitPlural: 'plátanos maduros', unitGrams: 200, priceCrcPerKg: 820),
  Food(id: 'aguacate', name: 'aguacate', kcal100: 160, protein100: 2, carb100: 8.5, fat100: 14.7,
      priceCrcPerKg: 2000),
  Food(id: 'papaya', name: 'papaya', kcal100: 43, protein100: 0.5, carb100: 11, fat100: 0.3,
      priceCrcPerKg: 700),
  Food(id: 'pina', name: 'piña', kcal100: 50, protein100: 0.5, carb100: 13, fat100: 0.1,
      priceCrcPerKg: 700),
  Food(id: 'granola', name: 'granola', kcal100: 470, protein100: 10, carb100: 64, fat100: 20,
      priceCrcPerKg: 4000),
  Food(id: 'mani', name: 'maní sin sal', kcal100: 567, protein100: 25.8, carb100: 16, fat100: 49,
      priceCrcPerKg: 4000),
  Food(id: 'pollo', name: 'pechuga de pollo', kcal100: 165, protein100: 31, carb100: 0, fat100: 3.6,
      priceCrcPerKg: 6000),
  Food(id: 'res', name: 'carne de res', kcal100: 217, protein100: 26, carb100: 0, fat100: 12,
      priceCrcPerKg: 8000, tags: {'red_meat'}),
  Food(id: 'molida', name: 'carne molida', kcal100: 250, protein100: 26, carb100: 0, fat100: 15,
      priceCrcPerKg: 6000, tags: {'red_meat'}),
  Food(id: 'cerdo', name: 'chuleta de cerdo', kcal100: 242, protein100: 27, carb100: 0, fat100: 14,
      priceCrcPerKg: 6000, tags: {'pork'}),
  Food(id: 'atun', name: 'atún en agua', kcal100: 116, protein100: 25.5, carb100: 0, fat100: 0.8,
      unit: 'lata de atún', unitPlural: 'latas de atún', unitGrams: 120, priceCrcPerKg: 5800, tags: {'seafood'}),
  Food(id: 'tilapia', name: 'tilapia', kcal100: 128, protein100: 26, carb100: 0, fat100: 2.7,
      priceCrcPerKg: 5500, tags: {'seafood'}),
  Food(id: 'papa', name: 'papa', kcal100: 87, protein100: 1.9, carb100: 20, fat100: 0.1,
      priceCrcPerKg: 900),
  Food(id: 'yuca', name: 'yuca', kcal100: 160, protein100: 1.4, carb100: 38, fat100: 0.3,
      priceCrcPerKg: 800),
  Food(id: 'chayote', name: 'chayote', kcal100: 24, protein100: 0.6, carb100: 5, fat100: 0.5,
      priceCrcPerKg: 700),
  Food(id: 'vainica', name: 'vainica', kcal100: 35, protein100: 1.9, carb100: 7.9, fat100: 0.3,
      priceCrcPerKg: 1200),
  Food(id: 'ensalada', name: 'ensalada de repollo y tomate', kcal100: 20, protein100: 1, carb100: 4, fat100: 0.2,
      priceCrcPerKg: 1000),
  Food(id: 'aceite', name: 'aceite', kcal100: 884, protein100: 0, carb100: 0, fat100: 100,
      unit: 'cucharadita de aceite', unitPlural: 'cucharaditas de aceite', unitGrams: 5, priceCrcPerKg: 2500),
  Food(id: 'galletas', name: 'galletas de soda', kcal100: 420, protein100: 9, carb100: 72, fat100: 10,
      unit: 'paquetito de galletas de soda', unitPlural: 'paquetitos de galletas de soda', unitGrams: 26,
      priceCrcPerKg: 4000),
];

/// Alimentos por id.
final Map<String, Food> kFoods = {for (final f in _foods) f.id: f};
