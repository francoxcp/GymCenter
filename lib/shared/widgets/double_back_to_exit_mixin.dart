import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/l10n/app_l10n.dart';
import 'app_snackbar.dart';

/// Mixin que agrega la lógica de "pulsa atrás dos veces para salir"
/// a cualquier pantalla raíz (home, admin, workouts, etc.)
mixin DoubleBackToExitMixin<T extends StatefulWidget> on State<T> {
  DateTime? _lastBackPress;

  /// Llama esto desde onPopInvokedWithResult para manejar el doble-atrás.
  void handleDoubleBackToExit(bool didPop) {
    if (didPop) return;
    final now = DateTime.now();
    const twoSeconds = Duration(seconds: 2);
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > twoSeconds) {
      _lastBackPress = now;
      AppSnackbar.info(context, AppL10n.of(context).pressBackToExit);
    } else {
      SystemNavigator.pop();
    }
  }
}
