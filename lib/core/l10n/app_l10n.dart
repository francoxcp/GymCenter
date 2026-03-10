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

  // ── Historial de entrenamientos ─────────────────────────────────────────
  String get workoutHistory =>
      isEn ? 'Workout History' : 'Historial de Entrenamientos';
  String get recentSessions => isEn ? 'Recent Sessions' : 'Sesiones Recientes';
  String get generalSummary => isEn ? 'General Summary' : 'Resumen General';
  String get totalWorkoutsLabel => isEn ? 'Workouts' : 'Entrenamientos';
  String get totalTimeLabel => isEn ? 'Total time' : 'Tiempo total';
  String get thisWeek => isEn ? 'This week' : 'Esta semana';
  String get todayLabel => isEn ? 'Today' : 'Hoy';
  String get yesterdayLabel => isEn ? 'Yesterday' : 'Ayer';
  String daysAgoLabel(int n) => isEn ? '$n days ago' : 'Hace $n días';
  String get completeWorkoutLabel =>
      isEn ? 'Complete Workout' : 'Entrenamiento Completo';
  String get completedLabel => isEn ? 'Completed' : 'Completado';
  String get noHistoryYet => isEn ? 'No history yet' : 'Sin historial aún';
  String get noHistoryBody =>
      isEn
          ? 'Complete your first workout\nto see your progress here'
          : 'Completa tu primer entrenamiento\npara ver tu progreso aquí';
  String get exploreWorkouts =>
      isEn ? 'Explore workouts' : 'Explorar entrenamientos';
  String exercisesCount(int n) => isEn ? '$n exercises' : '$n ejercicios';
  String percentCompleted(int p) =>
      isEn ? '$p% completed' : '$p% completado';

  // ── Rutina de hoy ────────────────────────────────────────────────────────
  String get myTodayWorkout => isEn ? 'My Workout' : 'Mi Rutina de Hoy';
  String get myWorkoutHeader => isEn ? 'MY WORKOUT' : 'MI RUTINA DE HOY';
  String get incompleteWorkoutFound =>
      isEn ? 'Incomplete Workout Found' : 'Rutina Incompleta Encontrada';
  String startedLabel(String t) => isEn ? 'Started $t' : 'Iniciada $t';
  String progressLabel(int p) => isEn ? 'Progress: $p%' : 'Progreso: $p%';
  String get startFromScratch => isEn ? 'Start Over' : 'Empezar de Cero';
  String get continueAction => isEn ? 'Continue' : 'Continuar';
  String get noAssignedWorkout =>
      isEn ? 'No workout assigned' : 'No tienes rutina asignada';
  String get contactTrainer =>
      isEn
          ? 'Contact your trainer to get a workout assigned'
          : 'Contacta a tu entrenador para que te asigne una rutina';
  String get loadingWorkoutError =>
      isEn ? 'Error loading workout' : 'Error al cargar la rutina';
  String minutesAgoLabel(int m) =>
      isEn ? '$m minutes ago' : 'hace $m minutos';
  String hoursAgoLabel(int h) => isEn ? '$h hours ago' : 'hace $h horas';
  String daysAgoLowerLabel(int d) => isEn ? '$d days ago' : 'hace $d días';

  // ── Resumen de entrenamiento ─────────────────────────────────────────────
  String get workoutSummaryTitle =>
      isEn ? 'Workout Summary' : 'Resumen de Entrenamiento';
  String get workoutCompletedLine1 =>
      isEn ? 'Workout' : '¡Entrenamiento';
  String get workoutCompletedLine2 => isEn ? 'Completed!' : 'Completado!';
  String get exerciseSummaryLabel =>
      isEn ? 'Exercise Summary' : 'Resumen de Ejercicios';
  String get nextSessionLabel => isEn ? 'Next Session' : 'Próxima Sesión';
  String get backToHome => isEn ? 'Back to Home' : 'Volver al Inicio';
  String get nextWorkoutDefault =>
      isEn ? 'Next Workout' : 'Próxima Rutina';
  String get nextWorkoutMsg1 =>
      isEn
          ? 'Get ready for your next session!'
          : '¡Prepárate para tu próxima sesión!';
  String get nextWorkoutMsg2 =>
      isEn
          ? "Don't forget to rest and eat well before your next workout!"
          : '¡No olvides descansar y alimentarte bien antes de tu próxima rutina!';
  List<String> get motivationalMessages => isEn
      ? ['INCREDIBLE WORK!', 'YOU DID IT!', 'EXCELLENT!', 'UNSTOPPABLE!',
          'BRUTAL WORKOUT!', 'KEEP IT UP CHAMP!', 'SPECTACULAR!', 'WHAT A MACHINE!']
      : ['¡INCREÍBLE TRABAJO!', '¡LO LOGRASTE!', '¡EXCELENTE!', '¡ERES IMPARABLE!',
          '¡BRUTAL ENTRENAMIENTO!', '¡SIGUE ASÍ CAMPEÓN!', '¡ESPECTACULAR!', '¡QUÉ MÁQUINA!'];

  // ── Progreso ─────────────────────────────────────────────────────────────
  String get myProgress => isEn ? 'My Progress' : 'Mi Progreso';
  // Períodos — usados como labels visibles; las claves internas siguen siendo ES
  List<String> get periodLabels =>
      isEn ? ['Week', 'Month', 'Year', 'All'] : ['Semana', 'Mes', 'Año', 'Todo'];
  List<String> get periodKeys => ['Semana', 'Mes', 'Año', 'Todo'];
  String periodLabel(String key) {
    final idx = periodKeys.indexOf(key);
    return idx >= 0 ? periodLabels[idx] : key;
  }
  String get currentStreakLabel => isEn ? 'Current Streak' : 'Racha Actual';
  String consecutiveDaysLabel(int n) =>
      isEn
          ? (n == 1 ? 'consecutive day' : 'consecutive days')
          : (n == 1 ? 'día consecutivo' : 'días consecutivos');
  String get startStreakToday =>
      isEn ? 'Start your streak today 💪' : 'Comienza tu racha hoy 💪';
  String get keepGoing => isEn ? 'Keep it up! 🎉' : '¡Sigue así! 🎉';
  String get incredibleStreak =>
      isEn ? 'Incredible streak! 🔥' : '¡Increíble racha! 🔥';
  String get unstoppableStreak =>
      isEn ? "You're unstoppable! 🏆" : '¡Eres imparable! 🏆';
  String get workoutsLabel => isEn ? 'Workouts' : 'Entrenamientos';
  String get totalTimeStatLabel => isEn ? 'Total Time' : 'Tiempo Total';
  String get caloriesStatLabel => isEn ? 'Calories' : 'Calorías';
  String get weightStatLabel => isEn ? 'Weight' : 'Peso';
  String inPeriod(String key) =>
      isEn ? 'in ${periodLabel(key).toLowerCase()}' : 'en ${key.toLowerCase()}';
  String get noWorkoutsYet =>
      isEn ? 'Start your first workout' : 'Comienza tu primer entrenamiento';
  String get notTrainedYet =>
      isEn ? 'Not trained yet' : 'Aún no has entrenado';
  String get startBurningCalories =>
      isEn ? 'Start burning calories' : 'Comienza a quemar calorías';
  String get addMeasurementsHint =>
      isEn
          ? 'Add measurements to track progress'
          : 'Agrega medidas para seguimiento';
  String get recentActivityLabel =>
      isEn ? 'Recent Activity' : 'Actividad Reciente';
  String get weightProgressLabel =>
      isEn ? 'Weight Progress' : 'Progreso de Peso';
  String get workoutFrequencyLabel =>
      isEn ? 'Workout Frequency' : 'Frecuencia de Entrenos';
  String get recentAchievementsLabel =>
      isEn ? 'Recent Achievements' : 'Logros Recientes';
  String get bodyMeasurementsLabel =>
      isEn ? 'Body Measurements' : 'Medidas Corporales';
  String get bodyMeasurementsSubtitle =>
      isEn ? 'Track and follow your measurements' : 'Registra y sigue tus medidas';
  String get completeWorkoutForStats =>
      isEn
          ? 'Complete a workout to see stats'
          : 'Completa un entreno para ver estadísticas';
  String sessionsCount(int n) =>
      isEn ? '$n session${n == 1 ? '' : 's'}' : '$n sesión${n == 1 ? '' : 'es'}';
  String get noData => isEn ? 'No data' : 'Sin datos';
  String get achievementsUnlockHint =>
      isEn
          ? 'Complete workouts to unlock achievements'
          : 'Completa entrenamientos para desbloquear logros';
  String timeAgoLabel(int days, int hours) {
    if (days > 0) return isEn ? '$days day${days > 1 ? 's' : ''} ago' : 'Hace $days día${days > 1 ? 's' : ''}';
    if (hours > 0) return isEn ? '$hours hour${hours > 1 ? 's' : ''} ago' : 'Hace $hours hora${hours > 1 ? 's' : ''}';
    return isEn ? 'A few moments ago' : 'Hace unos momentos';
  }

  // ── Perfil ───────────────────────────────────────────────────────────────
  String get myProfile => isEn ? 'My Profile' : 'Mi Perfil';
  String get takePhoto => isEn ? 'Take photo' : 'Tomar foto';
  String get galleryLabel => isEn ? 'Gallery' : 'Galería';
  String get profileUpdated =>
      isEn ? 'Profile updated successfully' : 'Perfil actualizado correctamente';
  String errorSavingMsg(String e) =>
      isEn ? 'Error saving: $e' : 'Error al guardar: $e';
  String get photoUpdated => isEn ? 'Photo updated' : 'Foto actualizada';
  String get trainingLevel =>
      isEn ? 'TRAINING LEVEL' : 'NIVEL DE ENTRENAMIENTO';
  String get saveChanges => isEn ? 'Save Changes' : 'Guardar Cambios';
  String get workoutHistoryMenu =>
      isEn ? 'Workout history' : 'Historial de entrenamientos';
  String get configurationMenu => isEn ? 'Settings' : 'Configuración';
  String get changePasswordMenu =>
      isEn ? 'Change Password' : 'Cambiar Contraseña';
  String get logOutLabel => isEn ? 'LOG OUT' : 'CERRAR SESIÓN';
  String get fullName => isEn ? 'Full name' : 'Nombre completo';
  String get enterYourName => isEn ? 'Enter your name' : 'Ingresa tu nombre';
  String get noAuthUser =>
      isEn ? 'No authenticated user' : 'No hay usuario autenticado';
  String get uploadPhotoError =>
      isEn ? 'Error uploading photo' : 'Error al subir foto';

  // ── Lista de rutinas ─────────────────────────────────────────────────────
  String get workoutListTitle => isEn ? 'Workout List' : 'Lista de Rutinas';
  String get searchWorkoutsHint =>
      isEn ? 'Search workouts by name...' : 'Buscar rutinas por nombre...';
  String get workoutInProgressTitle =>
      isEn ? 'Workout in Progress' : 'Rutina en Progreso';
  String get workoutInProgressBody =>
      isEn
          ? 'You have a workout in progress. Continue it or start this one as extra?'
          : 'Tienes una rutina en curso. ¿Quieres continuar esa o iniciar esta como extra?';
  String get continueInProgress =>
      isEn ? 'Continue in progress' : 'Continuar en progreso';
  String get startThisWorkout =>
      isEn ? 'Start this workout' : 'Iniciar esta rutina';
  String get deleteWorkoutTitle =>
      isEn ? 'Delete workout?' : '¿Eliminar rutina?';
  String deleteWorkoutConfirm(String name) =>
      isEn
          ? 'Are you sure you want to delete "$name"? This cannot be undone.'
          : '¿Estás seguro de eliminar "$name"? Esta acción no se puede deshacer.';
  String get workoutDeletedOk =>
      isEn ? 'Workout deleted successfully' : 'Rutina eliminada correctamente';
  String workoutDeleteError(String e) =>
      isEn ? 'Error deleting: $e' : 'Error al eliminar: $e';

  // ── Detalle de rutina ────────────────────────────────────────────────────
  String get workoutLabel => isEn ? 'Workout' : 'Rutina';
  String get editLabel => isEn ? 'Edit' : 'Editar';
  String get deleteConfirmTitle =>
      isEn ? 'Confirm Delete' : 'Confirmar Eliminación';
  String get continueInProgressShort =>
      isEn ? 'Continue in progress' : 'Continuar en progreso';
  String get startThisOne => isEn ? 'Start this one' : 'Iniciar esta';
  String get workoutInProgressShort =>
      isEn ? 'Workout in Progress' : 'Rutina en Progreso';

  // ── Calendario ───────────────────────────────────────────────────────────
  String get workoutCalendar =>
      isEn ? 'Workout Calendar' : 'Calendario de Entrenamientos';

  // ── Medidas corporales ───────────────────────────────────────────────────
  String get bodyMeasurementsTitle =>
      isEn ? 'Body Measurements' : 'Medidas Corporales';
  String get currentMeasurements =>
      isEn ? 'Current Measurements' : 'Medidas Actuales';
  String get measurementHistory => isEn ? 'History' : 'Historial';
  String get noMeasurementsYet =>
      isEn ? 'No measurements recorded' : 'Sin medidas registradas';
  String get noMeasurementsBody =>
      isEn
          ? 'Start recording your measurements\nto track your progress'
          : 'Comienza a registrar tus medidas\npara hacer seguimiento de tu progreso';
  String get addFirstMeasurement =>
      isEn ? 'Add first measurement' : 'Añadir primera medida';
  String get newMeasurement => isEn ? 'New Measurement' : 'Nueva Medida';

  // ── Legal ────────────────────────────────────────────────────────────────
  String get termsTitle =>
      isEn ? 'Terms and Conditions' : 'Términos y Condiciones';
  String get privacyPolicyTitle =>
      isEn ? 'Privacy Policy' : 'Política de Privacidad';

  // About dialog
  String get aboutContent =>
      isEn
          ? 'Version 1.0.0\n\nYour perfect companion to reach your fitness goals.\n\n© 2026 Chamos Fitness Center'
          : 'Versión 1.0.0\n\nTu compañero perfecto para alcanzar tus metas de fitness.\n\n© 2026 Chamos Fitness Center';
}
