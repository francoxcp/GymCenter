import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/shared/web/web_safe_area.dart';

void main() {
  const base = MediaQueryData(size: Size(393, 852));
  // iPhone 15 Pro: isla dinámica arriba y barra de inicio abajo
  const iphone = [59.0, 0.0, 34.0, 0.0];

  test('agrega las zonas seguras del iPhone', () {
    final mq = withWebSafeArea(base, iphone);
    expect(mq.padding, const EdgeInsets.fromLTRB(0, 59, 0, 34));
    expect(mq.viewPadding, const EdgeInsets.fromLTRB(0, 59, 0, 34));
  });

  test('con el teclado abierto no suma la barra de inicio', () {
    final mq = withWebSafeArea(
        base.copyWith(viewInsets: const EdgeInsets.only(bottom: 300)), iphone);
    expect(mq.padding.bottom, 0);
    expect(mq.padding.top, 59);
  });

  test('horizontal: laterales', () {
    final mq = withWebSafeArea(base, const [0, 59, 21, 59]);
    expect(mq.padding, const EdgeInsets.fromLTRB(59, 0, 59, 21));
  });

  test('Android / escritorio (sin zonas) no cambia nada', () {
    expect(withWebSafeArea(base, const [0, 0, 0, 0]), same(base));
  });

  test('si Flutter ya las informa, no se duplican', () {
    final native = base.copyWith(
        viewPadding: const EdgeInsets.only(top: 47),
        padding: const EdgeInsets.only(top: 47));
    expect(withWebSafeArea(native, iphone), same(native));
  });
}
