import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chamos_fitness_center/core/theme/app_theme.dart';
import 'package:chamos_fitness_center/shared/widgets/primary_button.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('PrimaryButton should render correctly',
        (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Test Button',
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      // Verify button is rendered
      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Tap the button
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      // Verify callback was called
      expect(wasPressed, true);
    });

    testWidgets('PrimaryButton should handle disabled state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Disabled Button',
              onPressed: null,
            ),
          ),
        ),
      );

      // Verify button is rendered
      expect(find.text('Disabled Button'), findsOneWidget);

      // Verify button is disabled
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('PrimaryButton should show loading state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Loading Button',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading Button'), findsNothing);
    });
  });

  group('Theme Tests', () {
    test('AppColors should have all required colors defined', () {
      expect(AppColors.primary, isA<Color>());
      expect(AppColors.background, isA<Color>());
      expect(AppColors.surface, isA<Color>());
      expect(AppColors.cardBackground, isA<Color>());
      expect(AppColors.textPrimary, isA<Color>());
      expect(AppColors.textSecondary, isA<Color>());
      expect(AppColors.success, isA<Color>());
    });

    test('AppColors should use correct color values', () {
      expect(AppColors.primary.value, 0xFFFFEB00); // Yellow Chamos
      expect(AppColors.background.value, 0xFF0A0A0A); // Black
      expect(AppColors.surface.value, 0xFF1A1A1A); // Dark gray
      expect(AppColors.cardBackground.value, 0xFF1E1E1E); // Lighter dark gray
      expect(AppColors.textPrimary.value, 0xFFFFFFFF); // White
    });
  });
}
