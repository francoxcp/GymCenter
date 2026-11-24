import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/features/nutrition/screens/nutrition_screen.dart';
import 'package:gymlab/features/nutrition/services/nutrition_calculator.dart';

NutritionProfile _p({int age = 29, Set<String> avoid = const {}}) =>
    NutritionProfile(
      weightKg: 78,
      heightCm: 175,
      age: age,
      sex: 'male',
      goal: NutritionGoal.gain,
      activity: ActivityLevel.sedentary,
      trainingDays: 3,
      mealsPerDay: 4,
      avoid: avoid,
    );

Future<void> _pump(WidgetTester tester, NutritionProfile? p,
    {Map<MealSlot, String>? choices,
    void Function(MealSlot, String?)? onChoose,
    VoidCallback? onAdjust}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  await tester.pumpWidget(MaterialApp(
    home: NutritionPlanView(
      profile: p,
      choices: choices ?? const {},
      now: DateTime(2026, 11, 22, 7),
      onChoose: onChoose ?? (_, __) {},
      onAdjust: onAdjust ?? () {},
    ),
  ));
}

void main() {
  testWidgets('sin perfil invita al cuestionario', (tester) async {
    var adjusted = false;
    await _pump(tester, null, onAdjust: () => adjusted = true);
    await tester.tap(find.text('Armar mi plan'));
    expect(adjusted, isTrue);
  });

  testWidgets('con perfil: kcal y proteína, comidas, precios y aviso',
      (tester) async {
    await _pump(tester, _p());
    expect(find.text('2 500'), findsOneWidget);
    expect(find.text('140 g'), findsOneWidget);
    expect(find.text('COMIDA · SUBIR MASA'), findsOneWidget);
    for (final l in ['Desayuno', 'Almuerzo', 'Merienda', 'Cena']) {
      expect(find.text(l), findsWidgets);
    }
    expect(find.text('Tostada integral con aguacate y huevos'), findsOneWidget);
    // Porciones de la comida y consejos de la nutricionista
    expect(find.textContaining('harina'), findsWidgets);
    expect(find.textContaining('proteínas'), findsWidgets);
    expect(find.textContaining('2 L de agua', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('Camina 10–15 minutos', skipOffstage: false),
        findsOneWidget);
    expect(find.textContaining('₡', skipOffstage: false), findsNothing);
    expect(
        find.textContaining('Guía orientativa; no reemplaza a un nutricionista',
            skipOffstage: false),
        findsOneWidget);
    expect(find.textContaining('Precios', skipOffstage: false), findsNothing);
  });

  testWidgets('con todas las exclusiones avisa que hay pocas opciones',
      (tester) async {
    await _pump(tester,
        _p(avoid: {'dairy', 'egg', 'seafood', 'red_meat', 'pork'}));
    expect(find.text('Pocas opciones con tus restricciones'), findsOneWidget);
  });

  testWidgets('menor de 18 ve el aviso', (tester) async {
    await _pump(tester, _p(age: 16));
    expect(
        find.textContaining('consulta con un nutricionista y tu encargado',
            skipOffstage: false),
        findsOneWidget);
  });

  testWidgets('Elegir marca la opción y el pie suma el día', (tester) async {
    MealSlot? slot;
    String? id;
    await _pump(tester, _p(), onChoose: (s, i) {
      slot = s;
      id = i;
    });
    expect(find.textContaining('Tu día: 0 de 4 comidas elegidas'),
        findsOneWidget);
    await tester.tap(find.text('Tostada integral con aguacate y huevos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('pan integral'), findsWidgets);
    await tester.ensureVisible(find.text('Elegir').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir').first);
    await tester.pumpAndSettle();
    expect(slot, MealSlot.breakfast);
    expect(id, 'tostada_aguacate_huevos');
    expect(find.textContaining('Tu día: 1 de 4 comidas elegidas'),
        findsOneWidget);
    expect(find.textContaining('₡'), findsNothing);
    expect(find.text('Elegido'), findsOneWidget);
  });

  testWidgets('cambiar de comida muestra sus opciones', (tester) async {
    await _pump(tester, _p());
    await tester.tap(find.text('Almuerzo'));
    await tester.pumpAndSettle();
    expect(find.text('Casado medido de pollo a la plancha'), findsOneWidget);
  });
}
