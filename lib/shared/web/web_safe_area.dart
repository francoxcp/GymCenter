import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Agrega a [mq] las zonas seguras del celular ([insets] en px lógicos:
/// arriba, derecha, abajo, izquierda) cuando Flutter no las informa.
///
/// En la PWA instalada del iPhone la app se dibuja bajo el notch / isla
/// dinámica y la barra de inicio (viewport-fit=cover), pero Flutter web deja
/// `MediaQuery.padding` en 0. Con esto, AppBar, SafeArea y la barra de
/// pestañas las respetan como en una app nativa. Si Flutter ya trae valores
/// (app nativa o una versión futura de Flutter), no se toca nada.
MediaQueryData withWebSafeArea(MediaQueryData mq, List<double> insets) {
  if (insets.length != 4 || mq.viewPadding != EdgeInsets.zero) return mq;
  final safe = EdgeInsets.fromLTRB(insets[3], insets[0], insets[1], insets[2]);
  if (safe == EdgeInsets.zero) return mq;
  return mq.copyWith(
    viewPadding: safe,
    // Con el teclado abierto, la barra de inicio queda tapada: no se suma
    padding: EdgeInsets.fromLTRB(
      safe.left,
      safe.top,
      safe.right,
      math.max(0, safe.bottom - mq.viewInsets.bottom),
    ),
  );
}
