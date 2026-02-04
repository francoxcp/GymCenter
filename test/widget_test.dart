import 'package:flutter_test/flutter_test.dart';
import 'package:chamos_fitness_center/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app loads to login screen
    expect(find.text('CHAMOS'), findsOneWidget);
    expect(find.text('FITNESS CENTER'), findsOneWidget);
  });
}
