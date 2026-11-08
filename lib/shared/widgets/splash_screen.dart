import 'package:flutter/material.dart';

import '../../core/constants/brand.dart';

/// Pantalla de carga mientras se restaura la sesión guardada.
/// Usa los colores de la plataforma (no depende del tema elegido).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Semantics(
          label: 'Cargando ${Brand.platformName}',
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset('assets/icons/app_icon.png', width: 112, height: 112),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: Color(0xFFFFEB00),
                backgroundColor: Color(0xFF262626),
              ),
            ),
            const SizedBox(height: 18),
            Text(Brand.platformName.toUpperCase(),
                style: const TextStyle(
                    color: Color(0xFFB0B0B0), letterSpacing: 3, fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}
