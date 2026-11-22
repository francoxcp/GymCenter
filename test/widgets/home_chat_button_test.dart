import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlab/features/chat/chat_service.dart';
import 'package:gymlab/features/chat/widgets/chat_header_button.dart';

void main() {
  testWidgets('ChatHeaderButton muestra no leídos y navega a /chat',
      (tester) async {
    ChatService.unread.value = 3;
    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (_, __) =>
              const Scaffold(body: Center(child: ChatHeaderButton()))),
      GoRoute(
          path: '/chat',
          builder: (_, __) => const Scaffold(body: Text('CHAT'))),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('3'), findsOneWidget);
    expect(find.byTooltip('Chat con tu entrenador, 3 sin leer'), findsOneWidget);

    ChatService.unread.value = 0;
    await tester.pump();
    expect(find.text('3'), findsNothing);

    await tester.tap(find.byType(ChatHeaderButton));
    await tester.pumpAndSettle();
    expect(find.text('CHAT'), findsOneWidget);
  });
}
