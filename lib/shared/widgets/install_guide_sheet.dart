import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../services/share_helper.dart';
import '../web/web_bridge.dart';

enum InstallPlatform { ios, android, inApp }

InstallPlatform currentInstallPlatform() => WebBridge.isInAppBrowser
    ? InstallPlatform.inApp
    : WebBridge.isIOS
        ? InstallPlatform.ios
        : InstallPlatform.android;

/// Pasos para instalar según dónde está abierta la app.
List<(IconData, String, String)> installSteps(InstallPlatform p) => switch (p) {
      InstallPlatform.ios => const [
          (Icons.ios_share, 'Toca Compartir',
              'El cuadrado con la flecha hacia arriba, abajo en Safari (arriba en iPad).'),
          (Icons.add_box_outlined, 'Agregar a pantalla de inicio',
              'Desliza la lista hacia abajo hasta encontrarlo.'),
          (Icons.check_circle_outline, 'Toca "Agregar"',
              'Arriba a la derecha. El ícono queda junto a tus otras apps.'),
        ],
      InstallPlatform.android => const [
          (Icons.more_vert, 'Abre el menú',
              'Los tres puntos arriba a la derecha de Chrome.'),
          (Icons.install_mobile, 'Instalar app',
              'También puede decir "Agregar a la pantalla principal".'),
          (Icons.check_circle_outline, 'Confirma',
              'El ícono aparece con tus otras apps y abre a pantalla completa.'),
        ],
      InstallPlatform.inApp => const [
          (Icons.more_horiz, 'Abre el menú de esta app',
              'Los tres puntos (···) arriba a la derecha.'),
          (Icons.open_in_browser, 'Abrir en el navegador',
              'En iPhone dice "Abrir en Safari"; en Android, "Abrir en Chrome".'),
          (Icons.ios_share, 'Instálala desde ahí',
              'Vuelve a tocar "Instalar la app" y sigue los pasos.'),
        ],
    };

/// Hoja con los pasos ilustrados. En Android con el aviso del sistema
/// disponible, instala directo.
Future<void> showInstallGuide(BuildContext context) async {
  if (WebBridge.canPromptInstall && !WebBridge.isIOS) {
    final ok = await WebBridge.promptInstall();
    if (ok) return;
  }
  if (!context.mounted) return;
  final platform = currentInstallPlatform();
  final steps = installSteps(platform);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                platform == InstallPlatform.inApp
                    ? 'Ábrela en tu navegador'
                    : 'Instala GymCenter',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
                platform == InstallPlatform.inApp
                    ? 'Desde Instagram, Facebook o TikTok no se puede instalar.'
                    : 'Queda como una app normal: abre a pantalla completa y te avisa.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.35)),
            const SizedBox(height: 20),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text('${i + 1}',
                          style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              height: 1)),
                    ),
                    Icon(steps[i].$1, color: AppColors.textPrimary, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(steps[i].$2,
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(steps[i].$3,
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.35)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (platform == InstallPlatform.inApp)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton.icon(
                  onPressed: () {
                    ShareHelper.copy(ctx, Uri.base.origin);
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('Copiar enlace para pegarlo en el navegador'),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: const Text('Entendido',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
