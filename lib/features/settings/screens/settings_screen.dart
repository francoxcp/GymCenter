import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/preferences_provider.dart';
import '../../../shared/services/security_service.dart';
import '../../../shared/widgets/shimmer_loading.dart';

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

    // Si no hay preferencias todavía, mostrar loading
    if (prefs == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Configuración'),
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
          onPressed: () => context.pop(),
        ),
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Notificaciones
          _buildSectionTitle('Notificaciones'),
          _buildSwitchTile(
            title: 'Notificaciones',
            subtitle: 'Activar/desactivar todas las notificaciones',
            icon: Icons.notifications_outlined,
            value: prefs.notificationsEnabled,
            onChanged: (value) async {
              await preferencesProvider.toggleNotifications(value);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value
                        ? 'Notificaciones activadas'
                        : 'Notificaciones desactivadas'),
                  ),
                );
              }
            },
          ),
          if (prefs.notificationsEnabled) ...[
            _buildSwitchTile(
              title: 'Recordatorios de entrenamiento',
              subtitle: 'Recibe recordatorios diarios a las 6:00 PM',
              icon: Icons.alarm,
              value: prefs.workoutReminders,
              onChanged: (value) async {
                await preferencesProvider.toggleWorkoutReminders(value);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value
                          ? 'Recordatorios activados'
                          : 'Recordatorios desactivados'),
                    ),
                  );
                }
              },
            ),
            _buildSwitchTile(
              title: 'Alertas de logros',
              subtitle: 'Notificaciones al desbloquear logros',
              icon: Icons.emoji_events,
              value: prefs.achievementAlerts,
              onChanged: (value) async {
                await preferencesProvider.toggleAchievementAlerts(value);
              },
            ),
            _buildSwitchTile(
              title: 'Reportes de progreso',
              subtitle: 'Resumen semanal de tu progreso',
              icon: Icons.bar_chart,
              value: prefs.progressReports,
              onChanged: (value) async {
                await preferencesProvider.toggleProgressReports(value);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value
                          ? 'Reportes semanales activados'
                          : 'Reportes semanales desactivados'),
                    ),
                  );
                }
              },
            ),
          ],
          const SizedBox(height: 24),

          // Unidades
          _buildSectionTitle('Unidades'),
          _buildOptionTile(
            title: 'Sistema de medidas',
            subtitle: prefs.units == 'metric' ? 'Métrico' : 'Imperial',
            icon: Icons.straighten,
            onTap: () => _showUnitSelector(preferencesProvider, prefs.units),
          ),
          const SizedBox(height: 24),

          // Idioma
          _buildSectionTitle('Idioma'),
          _buildOptionTile(
            title: 'Idioma de la app',
            subtitle: prefs.language == 'es' ? 'Español' : 'English',
            icon: Icons.language,
            onTap: () =>
                _showLanguageSelector(preferencesProvider, prefs.language),
          ),
          const SizedBox(height: 24),

          // Cuenta
          _buildSectionTitle('Cuenta'),
          _buildOptionTile(
            title: 'Cambiar contraseña',
            subtitle: 'Actualizar tu contraseña',
            icon: Icons.lock_outline,
            onTap: () => _showChangePasswordDialog(),
          ),
          _buildOptionTile(
            title: 'Privacidad',
            subtitle: 'Configuración de privacidad',
            icon: Icons.privacy_tip_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad próximamente')),
              );
            },
          ),
          const SizedBox(height: 24),

          // Información
          _buildSectionTitle('Información'),
          _buildOptionTile(
            title: 'Términos y condiciones',
            subtitle: 'Leer los términos de uso',
            icon: Icons.description_outlined,
            onTap: () => context.push('/terms-and-conditions'),
          ),
          _buildOptionTile(
            title: 'Política de privacidad',
            subtitle: 'Nuestra política de datos',
            icon: Icons.policy_outlined,
            onTap: () => context.push('/privacy-policy'),
          ),
          _buildOptionTile(
            title: 'Acerca de',
            subtitle: 'Versión 1.0.0',
            icon: Icons.info_outline,
            onTap: () => _showAboutDialog(),
          ),
          const SizedBox(height: 24),

          // Cerrar sesión
          _buildDangerButton(
            'Cerrar Sesión',
            Icons.logout,
            () => _confirmLogout(authProvider),
          ),
          const SizedBox(height: 12),

          // Eliminar cuenta
          _buildDangerButton(
            'Eliminar Cuenta',
            Icons.delete_forever,
            () => _confirmDeleteAccount(),
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
            onChanged: onChanged,
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

  void _showUnitSelector(PreferencesProvider provider, String currentUnit) {
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
            const Text(
              'Sistema de Medidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _buildUnitOption(
                'metric', 'Métrico', 'kg, cm', currentUnit, provider),
            _buildUnitOption(
                'imperial', 'Imperial', 'lb, in', currentUnit, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitOption(
    String unitCode,
    String unit,
    String description,
    String currentUnit,
    PreferencesProvider provider,
  ) {
    final isSelected = currentUnit == unitCode;
    return ListTile(
      title: Text(
        unit,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing:
          isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        provider.changeUnits(unitCode);
        Navigator.pop(context);
      },
    );
  }

  void _showLanguageSelector(
      PreferencesProvider provider, String currentLanguage) {
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
            const Text(
              'Idioma',
              style: TextStyle(
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Row(
          children: [
            Icon(Icons.fitness_center, color: AppColors.primary, size: 32),
            SizedBox(width: 12),
            Text('Chamos Fitness', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Versión 1.0.0\n\nTu compañero perfecto para alcanzar tus metas de fitness.\n\n© 2026 Chamos Fitness Center',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          '¿Cerrar sesión?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              authProvider.logout();
              Navigator.pop(context);
              context.go('/login');
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          '⚠️ ¿Eliminar cuenta?',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Esta acción es permanente y no se puede deshacer. Todos tus datos serán eliminados.\n\n¿Estás completamente seguro?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPasswordConfirmDialog();
            },
            child: const Text(
              'Eliminar',
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
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Cambiar Contraseña'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Contraseña actual',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
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
                    labelText: 'Nueva contraseña',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscureNew = !obscureNew),
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
                    labelText: 'Confirmar contraseña',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
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
                const Text(
                  'La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número',
                  style: TextStyle(
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
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Las contraseñas no coinciden')),
                        );
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message']),
                            backgroundColor:
                                result['success'] ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo para confirmar eliminación con contraseña
  void _showPasswordConfirmDialog() {
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            '🔐 Confirmar Eliminación',
            style: TextStyle(color: Colors.red),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ingresa tu contraseña para confirmar la eliminación de tu cuenta.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
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
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Ingresa tu contraseña')),
                        );
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message']),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message']),
                              backgroundColor: Colors.red,
                            ),
                          );
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
                  : const Text('Eliminar Cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
