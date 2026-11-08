import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../web/web_bridge.dart';

/// Tarjeta que invita a instalar la PWA en la pantalla de inicio.
///
/// - iPhone/iPad: explica el paso "Compartir → Agregar a pantalla de inicio"
///   (Safari no permite instalar con un botón).
/// - Android/Chrome: muestra un botón "Instalar" que abre el diálogo nativo.
///
/// No se muestra fuera de la web ni cuando la app ya está instalada.
/// Con [forNotifications] el texto explica que en iPhone las notificaciones
/// solo funcionan con la app instalada, y no se puede descartar.
class InstallAppBanner extends StatefulWidget {
  final bool forNotifications;

  const InstallAppBanner({super.key, this.forNotifications = false});

  @override
  State<InstallAppBanner> createState() => _InstallAppBannerState();
}

class _InstallAppBannerState extends State<InstallAppBanner> {
  static const _kDismissed = 'install_banner_dismissed_v1';
  bool _dismissed = true; // oculto hasta comprobar preferencias
  bool _canPrompt = false;
  Timer? _recheck;

  bool get _eligible => kIsWeb && !WebBridge.isStandalone;

  @override
  void initState() {
    super.initState();
    if (!_eligible) return;
    _canPrompt = WebBridge.canPromptInstall;
    _loadDismissed();
    // El evento beforeinstallprompt de Chrome puede llegar unos segundos
    // después de cargar la página.
    _recheck = Timer.periodic(const Duration(seconds: 2), (t) {
      final can = WebBridge.canPromptInstall;
      if (can != _canPrompt && mounted) setState(() => _canPrompt = can);
      if (t.tick >= 5) t.cancel();
    });
  }

  Future<void> _loadDismissed() async {
    if (widget.forNotifications) {
      setState(() => _dismissed = false);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _dismissed = prefs.getBool(_kDismissed) ?? false);
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDismissed, true);
  }

  Future<void> _install() async {
    final accepted = await WebBridge.promptInstall();
    if (!mounted) return;
    setState(() => _canPrompt = WebBridge.canPromptInstall);
    if (accepted) setState(() => _dismissed = true);
  }

  @override
  void dispose() {
    _recheck?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_eligible || _dismissed) return const SizedBox.shrink();
    final isIOS = WebBridge.isIOS;
    // En Android sin el evento de instalación no hay nada útil que mostrar
    // (salvo en ajustes de notificaciones).
    if (!isIOS && !_canPrompt && !widget.forNotifications) {
      return const SizedBox.shrink();
    }
    final isEn = AppL10n.of(context).isEn;

    final title = widget.forNotifications
        ? (isEn ? 'Install the app to get notifications' : 'Instala la app para recibir notificaciones')
        : (isEn ? 'Install Chamos Fitness' : 'Instala Chamos Fitness');

    final body = isIOS
        ? (isEn
            ? 'In Safari tap Share, then "Add to Home Screen". It opens full screen like a normal app.'
            : 'En Safari toca Compartir y luego "Agregar a pantalla de inicio". Se abrirá a pantalla completa como una app normal.')
        : (isEn
            ? 'Add it to your home screen for quick, full-screen access.'
            : 'Agrégala a tu pantalla de inicio para abrirla rápido y a pantalla completa.');

    return Container(
      margin: EdgeInsets.only(bottom: widget.forNotifications ? 0 : 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIOS ? Icons.ios_share : Icons.install_mobile,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                if (!isIOS && _canPrompt) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: _install,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(isEn ? 'Install' : 'Instalar'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!widget.forNotifications)
            IconButton(
              tooltip: isEn ? 'Dismiss' : 'Cerrar',
              icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
              onPressed: _dismiss,
            ),
        ],
      ),
    );
  }
}
