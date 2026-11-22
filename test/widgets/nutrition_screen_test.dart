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
    expect(find.text('Gallo pinto con huevo'), findsOneWidget);
    expect(find.textContaining('~₡'), findsWidgets);
    expect(
        find.textContaining('Guía orientativa; no reemplaza a un nutricionista',
            skipOffstage: false),
        findsOneWidget);
    expect(find.textContaining('Precios aprox. nov 2026', skipOffstage: false),
        findsOneWidget);
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
    await tester.tap(find.text('Gallo pinto con huevo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('huevos'), findsWidgets);
    await tester.tap(find.text('Elegir').first);
    await tester.pumpAndSettle();
    expect(slot, MealSlot.breakfast);
    expect(id, 'pinto_huevo');
    expect(find.textContaining('Tu día: 1 de 4 comidas elegidas'),
        findsOneWidget);
    expect(find.text('Elegido'), findsOneWidget);
  });

  testWidgets('cambiar de comida muestra sus opciones', (tester) async {
    await _pump(tester, _p());
    await tester.tap(find.text('Almuerzo'));
    await tester.pumpAndSettle();
    expect(find.text('Casado de pollo'), findsOneWidget);
  });
}
