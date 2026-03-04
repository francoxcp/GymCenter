import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/settings/providers/preferences_provider.dart';

/// Clase de internacionalización ligera.
/// Uso: final l10n = AppL10n.of(context);
/// Nota: llama a Provider.of con listen:true, así el widget se reconstruye
/// automáticamente cuando el usuario cambia el idioma.
class AppL10n {
  final bool isEn;
  const AppL10n({required this.isEn});

  static AppL10n of(BuildContext context) {
    final lang =
        Provider.of<PreferencesProvider>(context).preferences?.language ?? 'es';
    return AppL10n(isEn: lang == 'en');
  }

  // ── Navegación inferior ──────────────────────────────────────────────────
  String get navPanel => isEn ? 'Home' : 'Panel';
  String get navWorkouts => isEn ? 'Workouts' : 'Rutinas';
  String get navPlans => isEn ? 'Plans' : 'Planes';
  String get navProfile => isEn ? 'Profile' : 'Mi Perfil';

  // ── Configuración ────────────────────────────────────────────────────────
  String get settings => isEn ? 'Settings' : 'Configuración';

  // Secciones
  String get sectionNotifications => isEn ? 'Notifications' : 'Notificaciones';
  String get sectionAppearance => isEn ? 'Appearance' : 'Apariencia';
  String get sectionLanguage => isEn ? 'Language' : 'Idioma';
  String get sectionAccount => isEn ? 'Account' : 'Cuenta';
  String get sectionInformation => isEn ? 'Information' : 'Información';

  // Notificaciones
  String get notifications => isEn ? 'Notifications' : 'Notificaciones';
  String get notificationsSubtitle =>
      isEn ? 'Enable/disable all notifications' : 'Activar/desactivar todas las notificaciones';
  String get workoutReminders =>
      isEn ? 'Workout reminders' : 'Recordatorios de entrenamiento';
  String get workoutRemindersSubtitle =>
      isEn ? 'Get reminded before your workout' : 'Recibe recordatorios antes de tu rutina';
  String get achievementAlerts =>
      isEn ? 'Achievement alerts' : 'Alertas de logros';
  String get achievementAlertsSubtitle =>
      isEn ? 'Get notified when you earn badges' : 'Notificaciones cuando ganes insignias';
  String get progressReports => isEn ? 'Progress reports' : 'Reportes de progreso';
  String get progressReportsSubtitle =>
      isEn ? 'Weekly progress updates' : 'Resúmenes semanales de tu avance';

  // Apariencia
  String get measurementSystem =>
      isEn ? 'Measurement system' : 'Sistema de medidas';
  String get metric => isEn ? 'Metric' : 'Métrico';
  String get imperial => isEn ? 'Imperial' : 'Imperial';
  String get selectMeasurementSystem =>
      isEn ? 'Measurement System' : 'Sistema de Medidas';

  // Idioma
  String get appLanguage => isEn ? 'App language' : 'Idioma de la app';
  String get selectLanguage => isEn ? 'Language' : 'Idioma';

  // Cuenta
  String get changePassword => isEn ? 'Change password' : 'Cambiar contraseña';
  String get changePasswordSubtitle =>
      isEn ? 'Update your password' : 'Actualizar tu contraseña';
  String get privacy => isEn ? 'Privacy' : 'Privacidad';
  String get privacySubtitle =>
      isEn ? 'Privacy settings' : 'Configuración de privacidad';

  // Información
  String get termsAndConditions =>
      isEn ? 'Terms & conditions' : 'Términos y condiciones';
  String get termsSubtitle =>
      isEn ? 'Read the terms of use' : 'Leer los términos de uso';
  String get privacyPolicy => isEn ? 'Privacy policy' : 'Política de privacidad';
  String get privacyPolicySubtitle =>
      isEn ? 'Our data policy' : 'Nuestra política de datos';
  String get about => isEn ? 'About' : 'Acerca de';
  String get version => isEn ? 'Version 1.0.0' : 'Versión 1.0.0';

  // Danger buttons
  String get logout => isEn ? 'Log Out' : 'Cerrar Sesión';
  String get deleteAccount => isEn ? 'Delete Account' : 'Eliminar Cuenta';

  // ── Botones comunes ──────────────────────────────────────────────────────
  String get save => isEn ? 'Save' : 'Guardar';
  String get cancel => isEn ? 'Cancel' : 'Cancelar';
  String get close => isEn ? 'Close' : 'Cerrar';
  String get delete => isEn ? 'Delete' : 'Eliminar';
  String get edit => isEn ? 'Edit' : 'Editar';
  String get confirm => isEn ? 'Confirm' : 'Confirmar';
  String get comingSoon =>
      isEn ? 'Coming soon' : 'Funcionalidad próximamente';

  // ── Diálogos de sesión ───────────────────────────────────────────────────
  String get confirmLogoutTitle =>
      isEn ? 'Log out?' : '¿Cerrar sesión?';
  String get confirmLogoutBody =>
      isEn ? 'Are you sure you want to log out?' : '¿Estás seguro de que deseas cerrar sesión?';
  String get confirmDeleteTitle =>
      isEn ? '⚠️ Delete account?' : '⚠️ ¿Eliminar cuenta?';
  String get confirmDeleteBody =>
      isEn
          ? 'This action is permanent and cannot be undone. All your data will be deleted.\n\nAre you completely sure?'
          : 'Esta acción es permanente y no se puede deshacer. Todos tus datos serán eliminados.\n\n¿Estás completamente seguro?';
  String get confirmDeletePasswordTitle =>
      isEn ? '🔐 Confirm Deletion' : '🔐 Confirmar Eliminación';
  String get confirmDeletePasswordBody =>
      isEn
          ? 'Enter your password to confirm account deletion.'
          : 'Ingresa tu contraseña para confirmar la eliminación de tu cuenta.';
  String get changePasswordTitle =>
      isEn ? 'Change Password' : 'Cambiar Contraseña';
  String get currentPassword =>
      isEn ? 'Current password' : 'Contraseña actual';
  String get newPassword => isEn ? 'New password' : 'Nueva contraseña';
  String get confirmPassword =>
      isEn ? 'Confirm password' : 'Confirmar contraseña';
  String get passwordHint =>
      isEn
          ? 'Must have at least 8 characters, one uppercase, one lowercase and one number'
          : 'La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número';
  String get passwordsDontMatch =>
      isEn ? 'Passwords do not match' : 'Las contraseñas no coinciden';
  String get enterPassword =>
      isEn ? 'Enter your password' : 'Ingresa tu contraseña';
  String get change => isEn ? 'Change' : 'Cambiar';
  String get password => isEn ? 'Password' : 'Contraseña';
  String get notificationsEnabled =>
      isEn ? 'Notifications enabled' : 'Notificaciones activadas';
  String get notificationsDisabled =>
      isEn ? 'Notifications disabled' : 'Notificaciones desactivadas';

  // ── Home ─────────────────────────────────────────────────────────────────
  String get controlPanel => isEn ? 'Control Panel' : 'Panel de Control';
  String get quickActions => isEn ? 'Quick Actions' : 'Acciones Rápidas';
  String get manageWorkouts =>
      isEn ? 'Manage Workouts' : 'Gestionar Rutinas';
  String get manageWorkoutsSubtitle =>
      isEn ? 'Create, edit and assign workouts' : 'Crear, editar y asignar rutinas';
  String get manageMealPlans =>
      isEn ? 'Manage Meal Plans' : 'Gestionar Planes Alimenticios';
  String get manageMealPlansSubtitle =>
      isEn ? 'Create and assign diets' : 'Crear y asignar dietas';
  String get adminPanel => isEn ? 'Admin Panel' : 'Panel de Administración';
  String get adminPanelSubtitle =>
      isEn ? 'View stats and users' : 'Ver estadísticas y usuarios';
  String welcomeUser(String name) =>
      isEn ? 'Hello, $name!' : '¡Hola, $name!';
  String get welcomeAdmin =>
      isEn ? 'Hello, Trainer!' : '¡Hola, Entrenador!';

  // About dialog
  String get aboutContent =>
      isEn
          ? 'Version 1.0.0\n\nYour perfect companion to reach your fitness goals.\n\n© 2026 Chamos Fitness Center'
          : 'Versión 1.0.0\n\nTu compañero perfecto para alcanzar tus metas de fitness.\n\n© 2026 Chamos Fitness Center';
}
