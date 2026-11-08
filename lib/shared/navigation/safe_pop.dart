import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// En web el usuario puede recargar la página o abrir una URL directamente,
/// y entonces no hay pantalla anterior a la que volver: `context.pop()`
/// lanzaría un error. [popOrGo] vuelve atrás si se puede y, si no, navega a
/// [fallback].
extension SafePop on BuildContext {
  void popOrGo(String fallback) {
    if (canPop()) {
      pop();
    } else {
      go(fallback);
    }
  }
}
