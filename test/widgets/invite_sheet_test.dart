import 'package:gymlab/features/organization/widgets/invite_link_sheet.dart';
import 'package:gymlab/shared/widgets/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('hoja de invitación: código, botones y QR', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showInviteLinkSheet(
                context,
                token: 'AB12CD34EF',
                title: 'Enlace para socios',
                hint: 'Prueba',
                shareText: 'Únete',
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('AB12CD34EF'), findsOneWidget);
    expect(find.text('Enviar por WhatsApp'), findsOneWidget);
    expect(find.text('Copiar enlace'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);

    await tester.tap(find.text('Mostrar QR para escanear'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('pantalla de carga con la marca', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    expect(find.text('GYMLAB'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
