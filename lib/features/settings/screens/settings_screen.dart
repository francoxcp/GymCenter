import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/preferences_provider.dart';
import '../../../shared/services/security_service.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/services/data_export_service.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/app_snackbar.dart';

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
            onPressed: () => context.pop(),
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
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Notificaciones
          _buildSectionTitle(l10n.sectionNotifications),
          _buildSwitchTile(
            title: l10n.notifications,
            subtitle: l10n.notificationsSubtitle,
            icon: Icons.notifications_outlined,
            value: prefs.notificationsEnabled,
            onChanged: (value) async {
              await preferencesProvider.toggleNotifications(value);
            },
          ),
          if (prefs.notificationsEnabled) ...[
            _buildSwitchTile(
              title: l10n.workoutReminders,
              subtitle: l10n.workoutRemindersSubtitle,
              icon: Icons.alarm,
              value: prefs.workoutReminders,
              onChanged: (value) async {
                await preferencesProvider.toggleWorkoutReminders(value);
              },
            ),
            if (prefs.workoutReminders) ...[
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
                                  tertiaryContainer: AppColors.primary,
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
            _buildSwitchTile(
              title: l10n.progressReports,
              subtitle: l10n.progressReportsSubtitle,
              icon: Icons.bar_chart,
              value: prefs.progressReports,
              onChanged: (value) async {
                await preferencesProvider.toggleProgressReports(value);
              },
            ),
            const SizedBox(height: 8),
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
          const SizedBox(height: 24),

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

          // Cuenta
          _buildSectionTitle(l10n.sectionAccount),
          _buildOptionTile(
            title: l10n.changePassword,
            subtitle: l10n.changePasswordSubtitle,
            icon: Icons.lock_outline,
            onTap: () => _showChangePasswordDialog(l10n),
          ),
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
          const SizedBox(height: 24),

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

          // Cerrar sesión
          _buildDangerButton(
            l10n.logout,
            Icons.logout,
            () => _confirmLogout(authProvider, l10n),
          ),
          const SizedBox(height: 12),

          // Eliminar cuenta
          _buildDangerButton(
            l10n.deleteAccount,
            Icons.delete_forever,
            () => _confirmDeleteAccount(l10n),
            isDestructive: true,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
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
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
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
            activeColor: AppColors.primary,
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
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
          color: isSelected ? AppColors.primary : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing:
          isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
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
            const Icon(Icons.fitness_center,
                color: AppColors.primary, size: 32),
            const SizedBox(width: 12),
            Text(l10n.chamosFitness,
                style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          l10n.aboutContent,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.close,
              style: const TextStyle(color: AppColors.primary),
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
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.confirmLogoutBody,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              authProvider.logout();
              Navigator.pop(context);
              context.go('/login');
            },
            child: Text(
              l10n.logout,
              style: const TextStyle(color: Colors.red),
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
          style: const TextStyle(color: Colors.red),
        ),
        content: Text(
          l10n.confirmDeleteBody,
          style: const TextStyle(color: AppColors.textSecondary),
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
              style: const TextStyle(
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
  void _showChangePasswordDialog(AppL10n l10n) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          final hasContent = currentPasswordController.text.isNotEmpty ||
              newPasswordController.text.isNotEmpty ||
              confirmPasswordController.text.isNotEmpty;
          if (!hasContent) {
            Navigator.of(context).pop();
            return;
          }
          showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.discardChangesTitle),
              content: Text(l10n.discardPasswordBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(l10n.exitLabel),
                ),
              ],
            ),
          ).then((shouldPop) {
            if (shouldPop == true && context.mounted) {
              Navigator.of(context).pop();
            }
          });
        },
        child: StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: Text(l10n.changePasswordTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrent,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.currentPassword,
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => obscureCurrent = !obscureCurrent),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.newPassword,
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => obscureNew = !obscureNew),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.confirmPassword,
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => obscureConfirm = !obscureConfirm),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.passwordHint,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (newPasswordController.text !=
                            confirmPasswordController.text) {
                          AppSnackbar.error(context, l10n.passwordsDontMatch);
                          return;
                        }

                        setState(() => isLoading = true);

                        final securityService = SecurityService();
                        final result = await securityService.changePassword(
                          currentPassword: currentPasswordController.text,
                          newPassword: newPasswordController.text,
                        );

                        setState(() => isLoading = false);

                        if (context.mounted) {
                          Navigator.pop(context);
                          if (result['success']) {
                            AppSnackbar.success(context,
                                l10n.serviceMessage(result['message']));
                          } else {
                            AppSnackbar.error(context,
                                l10n.serviceMessage(result['message']));
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.change),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }

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
            style: const TextStyle(color: Colors.red),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.confirmDeletePasswordBody,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.password,
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
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
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
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
