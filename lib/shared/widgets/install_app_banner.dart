import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../web/web_bridge.dart';
import 'install_guide_sheet.dart';

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
  // Al cerrarlo vuelve a aparecer a los 14 días (no se pierde para siempre).
  static const _kSnoozed = 'install_banner_snoozed_until';
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
    final until = prefs.getInt(_kSnoozed) ?? 0;
    setState(() =>
        _dismissed = DateTime.now().millisecondsSinceEpoch < until);
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _kSnoozed,
        DateTime.now()
            .add(const Duration(days: 14))
            .millisecondsSinceEpoch);
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
    final inApp = WebBridge.isInAppBrowser;
    final isEn = AppL10n.of(context).isEn;

    final title = widget.forNotifications
        ? (isEn ? 'Install the app to get notifications' : 'Instala la app para recibir notificaciones')
        : (isEn ? 'Install GYMLAB' : 'Instala GYMLAB');

    final body = inApp
        ? (isEn
            ? 'Open this link in Safari or Chrome to install it.'
            : 'Abre este enlace en Safari o Chrome para instalarla.')
        : isIOS
        ? (isEn
            ? 'Three taps and it opens full screen like a normal app.'
            : 'Son tres toques y abre a pantalla completa como una app normal.')
        : (isEn
            ? 'Add it to your home screen for quick, full-screen access.'
            : 'Agrégala a tu pantalla de inicio para abrirla rápido y a pantalla completa.');

    return Container(
      margin: EdgeInsets.only(bottom: widget.forNotifications ? 0 : 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryText.withValues(alpha: 0.35)),
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
              color: AppColors.primaryText,
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
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: (!isIOS && !inApp && _canPrompt)
                          ? _install
                          : () => showInstallGuide(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text((!isIOS && !inApp && _canPrompt)
                          ? (isEn ? 'Install' : 'Instalar')
                          : (isEn ? 'Show me how' : 'Ver cómo')),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!widget.forNotifications)
            IconButton(
              tooltip: isEn ? 'Dismiss' : 'Cerrar',
              icon: Icon(Icons.close, size: 18, color: AppColors.textSecondary),
              onPressed: _dismiss,
            ),
        ],
      ),
    );
  }
}
