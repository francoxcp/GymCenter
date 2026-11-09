import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/features/chat/chat_service.dart';
import 'package:gymlab/features/chat/chat_thread.dart';
import 'package:gymlab/shared/navigation/role_tabs.dart';

ChatMessage _m(String id, String body, int minute,
        {String sender = 'm', SendState state = SendState.sent}) =>
    ChatMessage(
      id: id,
      memberId: 'm',
      trainerId: 't',
      senderId: sender,
      body: body,
      createdAt: DateTime(2026, 11, 9, 10, minute),
      state: state,
    );

void main() {
  group('mergeMessage', () {
    test('el mensaje confirmado reemplaza al borrador', () {
      final list = [_m('a', 'hola', 1), _m('local-1', 'qué tal', 2, state: SendState.sending)];
      final out = mergeMessage(list, _m('b', 'qué tal', 2));
      expect(out.map((x) => x.id), ['a', 'b']);
      expect(out.last.state, SendState.sent);
    });

    test('no duplica si llega dos veces (tiempo real + respuesta)', () {
      final list = [_m('a', 'hola', 1)];
      expect(mergeMessage(list, _m('a', 'hola', 1)).length, 1);
    });

    test('ordena por hora', () {
      final out = mergeMessage([_m('b', 'dos', 5)], _m('a', 'uno', 1, sender: 't'));
      expect(out.map((x) => x.body), ['uno', 'dos']);
    });

    test('actualiza el visto', () {
      final read = ChatMessage.fromJson({
        'id': 'a', 'member_id': 'm', 'trainer_id': 't', 'sender_id': 'm',
        'body': 'hola', 'created_at': '2026-11-09T16:01:00Z',
        'read_at': '2026-11-09T16:02:00Z',
      });
      final out = mergeMessage([_m('a', 'hola', 1)], read);
      expect(out.single.readAt, isNotNull);
    });
  });

  test('etiquetas de día', () {
    final now = DateTime(2026, 11, 9, 12); // lunes
    expect(dayLabel(DateTime(2026, 11, 9, 8), now: now), 'Hoy');
    expect(dayLabel(DateTime(2026, 11, 8, 8), now: now), 'Ayer');
    expect(dayLabel(DateTime(2026, 11, 5, 8), now: now), 'Jueves');
    expect(dayLabel(DateTime(2026, 10, 1), now: now), '1/10');
  });

  test('el socio con entrenador tiene pestaña Chat', () {
    final tabs = tabsFor(NavRole.member, hasTrainer: true);
    expect(tabs.map((t) => t.path), ['/home', '/progress', '/chat', '/profile']);
    expect(tabIndexFor(tabs, '/chat'), 2);
    expect(tabsFor(NavRole.member).any((t) => t.path == '/chat'), isFalse);
    expect(trainerTabs.map((t) => t.path), contains('/chats'));
  });
}
