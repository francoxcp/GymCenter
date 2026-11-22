import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/features/auth/models/user.dart';
import 'package:gymlab/features/nutrition/screens/nutrition_setup_screen.dart';
import 'package:gymlab/features/nutrition/services/nutrition_calculator.dart';

User _user({
  int? age = 29,
  int? height = 175,
  double? weight = 78,
  String? sex = 'male',
  String? activity = 'standing',
  int? meals = 4,
}) =>
    User(
      id: 'u1',
      email: 'a@b.c',
      name: 'Ana',
      role: 'user',
      goal: 'Ganar músculo',
      age: age,
      heightCm: height,
      weightKg: weight,
      sex: sex,
      activityLevel: activity,
      mealsPerDay: meals,
    );

Future<NutritionSetupResult?> _pump(WidgetTester tester, User u) async {
  NutritionSetupResult? result;
  await tester.binding.setSurfaceSize(const Size(390, 844));
  await tester.pumpWidget(MaterialApp(
    home: NutritionSetupForm(
      initial: NutritionSetupInitial.fromUser(u),
      onDone: (r) async => result = r,
    ),
  ));
  return result;
}

void main() {
  group('needsNutritionSetup', () {
    test('completo → false', () {
      expect(needsNutritionSetup(_user()), isFalse);
    });
    test('cualquier dato faltante → true', () {
      expect(needsNutritionSetup(_user(age: null)), isTrue);
      expect(needsNutritionSetup(_user(height: null)), isTrue);
      expect(needsNutritionSetup(_user(sex: null)), isTrue);
      expect(needsNutritionSetup(_user(weight: null)), isTrue);
      expect(needsNutritionSetup(_user(activity: null)), isTrue);
      expect(needsNutritionSetup(_user(meals: null)), isTrue);
    });
    test('peso de una medida reemplaza el de users', () {
      expect(needsNutritionSetup(_user(weight: null), latestWeight: 80),
          isFalse);
    });
  });

  testWidgets('paso 1 muestra los datos y explica por qué', (tester) async {
    await _pump(tester, _user());
    expect(find.text('Paso 1 de 3'), findsOneWidget);
    expect(find.text('78 kg'), findsOneWidget);
    expect(find.text('175 cm'), findsOneWidget);
    expect(find.text('Con esto calculamos cuánta energía gasta tu cuerpo.'),
        findsOneWidget);
    expect(
        find.text('Define si comes un poco más, igual o un poco menos.'),
        findsOneWidget);
    expect(find.text('Bajar grasa', skipOffstage: false), findsOneWidget);
  });

  testWidgets('un menor no ve Bajar grasa y ve el aviso', (tester) async {
    await _pump(tester, _user(age: 16));
    expect(find.text('Bajar grasa', skipOffstage: false), findsNothing);
    expect(
        find.textContaining('consulta con un nutricionista y tu encargado',
            skipOffstage: false),
        findsOneWidget);
  });

  testWidgets('paso 2 no avanza sin elegir actividad', (tester) async {
    await _pump(tester, _user(activity: null));
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 2 de 3'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 2 de 3'), findsOneWidget);
    await tester.tap(find.text('Trabajo físico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 3 de 3'), findsOneWidget);
  });

  testWidgets('sin sexo no avanza del paso 1', (tester) async {
    await _pump(tester, _user(sex: null));
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 3'), findsOneWidget);
  });

  testWidgets('Listo entrega lo elegido; peso sin tocar → weightChanged false',
      (tester) async {
    NutritionSetupResult? result;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(MaterialApp(
      home: NutritionSetupForm(
        initial: NutritionSetupInitial.fromUser(_user()),
        onDone: (r) async => result = r,
      ),
    ));
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Huevo'));
    await tester.tap(find.text('Cerdo'));
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.goal, NutritionGoal.gain);
    expect(result!.activity, ActivityLevel.standing);
    expect(result!.avoid, {'egg', 'pork'});
    expect(result!.mealsPerDay, 5);
    expect(result!.weightChanged, isFalse);
  });

  testWidgets('cambiar el peso marca weightChanged', (tester) async {
    NutritionSetupResult? result;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(MaterialApp(
      home: NutritionSetupForm(
        initial: NutritionSetupInitial.fromUser(_user()),
        onDone: (r) async => result = r,
      ),
    ));
    await tester.tap(find.byTooltip('Subir peso'));
    await tester.pumpAndSettle();
    expect(find.text('78.5 kg'), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    expect(result!.weightKg, 78.5);
    expect(result!.weightChanged, isTrue);
  });
}
