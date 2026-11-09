import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/appearance_provider.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/preferences_provider.dart';
import '../../../shared/services/security_service.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/services/data_export_service.dart';
import '../../../shared/services/web_push_service.dart';
import '../../../shared/widgets/install_app_banner.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/navigation/safe_pop.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PreferencesProvider>(context, listen: false)
          .loadPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final preferencesProvider = Provider.of<PreferencesProvider>(context);
    final prefs = preferencesProvider.preferences;
    final l10n = AppL10n.of(context);

    // Si no hay preferencias todavía, mostrar loading
    if (prefs == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: AppL10n.of(context).backTooltip,
            onPressed: () => context.popOrGo('/profile'),
          ),
          title: Text(l10n.settings),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: 8,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: ShimmerCard(height: 80),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: AppL10n.of(context).backTooltip,
          onPressed: () => context.popOrGo('/profile'),
        ),
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Notificaciones
          _buildSectionTitle(l10n.sectionNotifications),
          if (kIsWeb && WebPushService().support == 'ios-needs-install')
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: InstallAppBanner(forNotifications: true),
            ),
          _buildSwitchTile(
            title: l10n.notifications,
            subtitle: l10n.isEn
                ? 'Workout reminder and messages from your trainer'
                : 'Recordatorio de entreno y mensajes de tu entrenador',
            icon: Icons.notifications_outlined,
            value: prefs.notificationsEnabled,
            onChanged: (value) async {
              final ok = await preferencesProvider.toggleNotifications(value);
              if (!ok && value && context.mounted) {
                AppSnackbar.error(
                  context,
                  kIsWeb &&
                          WebPushService().support == 'ios-needs-install'
                      ? (l10n.isEn
                          ? 'On iPhone, add the app to your Home Screen first.'
                          : 'En iPhone, primero agrega la app a tu pantalla de inicio.')
                      : l10n.notifPermissionDenied,
                );
              }
            },
          ),
          if (prefs.notificationsEnabled) ...[
            ...[
              _buildOptionTile(
                title: l10n.reminderTime,
                subtitle: () {
                  final t = preferencesProvider.workoutReminderTime;
                  final period = t.period == DayPeriod.am ? 'AM' : 'PM';
                  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
                  final m = t.minute.toString().padLeft(2, '0');
                  return '$h:$m $period';
                }(),
                icon: Icons.schedule_outlined,
                onTap: () async {
                  final current = preferencesProvider.workoutReminderTime;
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: current,
                    helpText: l10n.workoutReminderTime,
                    builder: (context, child) => Localizations.override(
                      context: context,
                      locale: const Locale('en', 'US'),
                      child: MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(alwaysUse24HourFormat: false),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                                  tertiaryContainer: AppColors.primaryText,
                                  onTertiaryContainer: Colors.black,
                                ),
                          ),
                          child: child!,
                        ),
                      ),
                    ),
                  );
                  if (picked != null) {
                    await preferencesProvider.updateWorkoutReminderTime(picked);
                    if (context.mounted) {
                      final period =
                          picked.period == DayPeriod.am ? 'AM' : 'PM';
                      final h =
                          picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                      final m = picked.minute.toString().padLeft(2, '0');
                      AppSnackbar.success(
                          context, l10n.reminderScheduled('$h', m, period));
                    }
                  }
                },
              ),
            ],
          ],
          const SizedBox(height: 24),

          // Apariencia y accesibilidad
          _buildSectionTitle(l10n.isEn ? 'Appearance' : 'Apariencia'),
          Consumer<AppearanceProvider>(
            builder: (context, look, _) => Column(children: [
              _buildSwitchTile(
                title: l10n.isEn ? 'Light mode' : 'Modo claro',
                subtitle: l10n.isEn
                    ? 'Easier to read outdoors or in bright light'
                    : 'Más fácil de leer al aire libre o con mucha luz',
                icon: Icons.light_mode_outlined,
                value: look.light,
                onChanged: (v) => look.setLight(v),
              ),
              _buildOptionTile(
                title: l10n.isEn ? 'Text size' : 'Tamaño del texto',
                subtitle:
                    AppearanceProvider.scales[look.textScale] ?? 'Normal',
                icon: Icons.text_fields,
                onTap: () => _showTextScaleSelector(look),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Cerrar sesión
          _buildDangerButton(
            l10n.logout,
            Icons.logout,
            () => _confirmLogout(authProvider, l10n),
          ),
          const SizedBox(height: 24),
          // Avanzado: lo que casi nunca se toca
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              iconColor: AppColors.textSecondary,
              collapsedIconColor: AppColors.textSecondary,
              title: Text(l10n.isEn ? 'Advanced' : 'Avanzado',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700)),
              subtitle: Text(
                  l10n.isEn
                      ? 'Language, privacy, your data, legal'
                      : 'Idioma, privacidad, tus datos, legal',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              children: [
                if (prefs.notificationsEnabled) ...[
            _buildOptionTile(
              title: l10n.testNotification,
              subtitle: l10n.testNotificationSubtitle,
              icon: Icons.notifications_active_outlined,
              onTap: () async {
                final svc = NotificationService();
                await svc.initialize();
                final granted = await svc.requestPermissions();
                if (!context.mounted) return;
                if (!granted) {
                  AppSnackbar.error(context, l10n.notifPermissionDenied);
                  return;
                }
                await svc.showNotification(
                  id: 999,
                  title: l10n.workoutTimeTitle,
                  body: l10n.workoutTimeBody,
                  payload: 'workout_reminder',
                );
                if (context.mounted) {
                  AppSnackbar.success(context, l10n.notificationSent);
                }
              },
            ),
  
                ],
          // Idioma
          _buildSectionTitle(l10n.sectionLanguage),
          _buildOptionTile(
            title: l10n.appLanguage,
            subtitle: prefs.language == 'es' ? 'Español' : 'English',
            icon: Icons.language,
            onTap: () => _showLanguageSelector(
                preferencesProvider, prefs.language, l10n),
          ),
          const SizedBox(height: 24),

          _buildOptionTile(
            title: l10n.privacy,
            subtitle: l10n.privacySubtitle,
            icon: Icons.privacy_tip_outlined,
            onTap: () => context.push('/privacy-settings'),
          ),
          _buildOptionTile(
            title: l10n.exportMyData,
            subtitle: l10n.exportMyDataSubtitle,
            icon: Icons.download_outlined,
            onTap: () => _exportUserData(),
          ),
          // Información
          _buildSectionTitle(l10n.sectionInformation),
          _buildOptionTile(
            title: l10n.termsAndConditions,
            subtitle: l10n.termsSubtitle,
            icon: Icons.description_outlined,
            onTap: () => context.push('/terms-and-conditions'),
          ),
          _buildOptionTile(
            title: l10n.privacyPolicy,
            subtitle: l10n.privacyPolicySubtitle,
            icon: Icons.policy_outlined,
            onTap: () => context.push('/privacy-policy'),
          ),
          _buildOptionTile(
            title: l10n.about,
            subtitle: l10n.version,
            icon: Icons.info_outline,
            onTap: () => _showAboutDialog(l10n),
          ),
          const SizedBox(height: 24),

          // Eliminar cuenta
          _buildDangerButton(
            l10n.deleteAccount,
            Icons.delete_forever,
            () => _confirmDeleteAccount(l10n),
            isDestructive: true,
          ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showTextScaleSelector(AppearanceProvider look) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            for (final e in AppearanceProvider.scales.entries)
              ListTile(
                minVerticalPadding: 14,
                leading: Icon(
                  look.textScale == e.key
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: AppColors.primaryText,
                ),
                title: Text(e.value,
                    style: TextStyle(
                        fontSize: 16 * e.key, color: AppColors.textPrimary)),
                onTap: () {
                  look.setTextScale(e.key);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryText, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
            activeThumbColor: AppColors.primaryText,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryText, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerButton(
    String text,
    IconData icon,
    VoidCallback onPressed, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : AppColors.textSecondary;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector(
      PreferencesProvider provider, String currentLanguage, AppL10n l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.selectLanguage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildLanguageOption(
                'es', 'Español', '🇪🇸', currentLanguage, provider),
            _buildLanguageOption(
                'en', 'English', '🇺🇸', currentLanguage, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    String languageCode,
    String language,
    String flag,
    String currentLanguage,
    PreferencesProvider provider,
  ) {
    final isSelected = currentLanguage == languageCode;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(
        language,
        style: TextStyle(
          color: isSelected ? AppColors.primaryText : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing:
          isSelected ? Icon(Icons.check, color: AppColors.primaryText) : null,
      onTap: () {
        provider.changeLanguage(languageCode);
        Navigator.pop(context);
      },
    );
  }

  void _showAboutDialog(AppL10n l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Row(
          children: [
            Icon(Icons.fitness_center,
                color: AppColors.primaryText, size: 32),
            const SizedBox(width: 12),
            Text(l10n.appBrand,
                style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(
          l10n.aboutContent,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.close,
              style: TextStyle(color: AppColors.primaryText),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportUserData() async {
    final l10n = AppL10n.of(context);
    try {
      AppSnackbar.info(context, l10n.preparingExport);
      await DataExportService().exportUserData(context);
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, l10n.errorExportingData(e.toString()));
      }
    }
  }

  void _confirmLogout(AuthProvider authProvider, AppL10n l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          l10n.confirmLogoutTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.confirmLogoutBody,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.logout();
              if (context.mounted) context.go('/login');
            },
            child: Text(
              l10n.logout,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(AppL10n l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          l10n.confirmDeleteTitle,
          style: TextStyle(color: Colors.red),
        ),
        content: Text(
          l10n.confirmDeleteBody,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPasswordConfirmDialog(l10n);
            },
            child: Text(
              l10n.delete,
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Diálogo para cambiar contraseña
  // Diálogo para confirmar eliminación con contraseña
  void _showPasswordConfirmDialog(AppL10n l10n) {
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text(
            l10n.confirmDeletePasswordTitle,
            style: TextStyle(color: Colors.red),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.confirmDeletePasswordBody,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.password,
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
 tooltip: 'Ocultar contraseña',
                    icon: Icon(obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => obscurePassword = !obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (passwordController.text.isEmpty) {
                        AppSnackbar.error(context, l10n.enterPassword);
                        return;
                      }

                      setState(() => isLoading = true);

                      final securityService = SecurityService();
                      final result = await securityService.deleteAccount(
                        password: passwordController.text,
                      );

                      setState(() => isLoading = false);

                      if (context.mounted) {
                        Navigator.pop(context);

                        if (result['success']) {
                          // Redirigir al login
                          context.go('/login');
                          AppSnackbar.success(
                              context, l10n.serviceMessage(result['message']));
                        } else {
                          AppSnackbar.error(
                              context, l10n.serviceMessage(result['message']));
                        }
                      }
                    },
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : Text(l10n.deleteAccount),
            ),
          ],
        ),
      ),
    ).then((_) {
      passwordController.dispose();
    });
  }
}
