import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chamos_fitness_center/features/workouts/widgets/record_celebration.dart';
import 'package:chamos_fitness_center/shared/widgets/install_guide_sheet.dart';

void main() {
  test('cada plataforma tiene 3 pasos de instalación', () {
    for (final p in InstallPlatform.values) {
      expect(installSteps(p).length, 3);
    }
    expect(installSteps(InstallPlatform.ios).first.$2, 'Toca Compartir');
  });

  testWidgets('la celebración de récord muestra el peso y se cierra', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => showRecordCelebration(ctx,
              exerciseName: 'Press banca', weightLabel: '135 lbs', previousLabel: '125 lbs'),
          child: const Text('go'),
        ),
      ),
    ));
    await t.tap(find.text('go'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('NUEVO RÉCORD'), findsOneWidget);
    expect(find.text('135 lbs'), findsOneWidget);
    expect(find.text('Antes: 125 lbs'), findsOneWidget);
    await t.tap(find.text('Seguir'));
    await t.pumpAndSettle();
    expect(find.text('NUEVO RÉCORD'), findsNothing);
    // El cierre automático programado no debe fallar tras cerrarse
    await t.pump(const Duration(seconds: 5));
  });
}
