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
  String get notificationsSubtitle => isEn
      ? 'Enable/disable all notifications'
      : 'Activar/desactivar todas las notificaciones';
  String get workoutReminders =>
      isEn ? 'Workout reminders' : 'Recordatorios de entrenamiento';
  String get workoutRemindersSubtitle => isEn
      ? 'Get reminded before your workout'
      : 'Recibe recordatorios antes de tu rutina';
  String get achievementAlerts =>
      isEn ? 'Achievement alerts' : 'Alertas de logros';
  String get achievementAlertsSubtitle => isEn
      ? 'Get notified when you earn badges'
      : 'Notificaciones cuando ganes insignias';
  String get progressReports =>
      isEn ? 'Progress reports' : 'Reportes de progreso';
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
  String get privacyPolicy =>
      isEn ? 'Privacy policy' : 'Política de privacidad';
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
  String get comingSoon => isEn ? 'Coming soon' : 'Funcionalidad próximamente';

  // ── Diálogos de sesión ───────────────────────────────────────────────────
  String get confirmLogoutTitle => isEn ? 'Log out?' : '¿Cerrar sesión?';
  String get confirmLogoutBody => isEn
      ? 'Are you sure you want to log out?'
      : '¿Estás seguro de que deseas cerrar sesión?';
  String get confirmDeleteTitle =>
      isEn ? '⚠️ Delete account?' : '⚠️ ¿Eliminar cuenta?';
  String get confirmDeleteBody => isEn
      ? 'This action is permanent and cannot be undone. All your data will be deleted.\n\nAre you completely sure?'
      : 'Esta acción es permanente y no se puede deshacer. Todos tus datos serán eliminados.\n\n¿Estás completamente seguro?';
  String get confirmDeletePasswordTitle =>
      isEn ? '🔐 Confirm Deletion' : '🔐 Confirmar Eliminación';
  String get confirmDeletePasswordBody => isEn
      ? 'Enter your password to confirm account deletion.'
      : 'Ingresa tu contraseña para confirmar la eliminación de tu cuenta.';
  String get changePasswordTitle =>
      isEn ? 'Change Password' : 'Cambiar Contraseña';
  String get currentPassword => isEn ? 'Current password' : 'Contraseña actual';
  String get newPassword => isEn ? 'New password' : 'Nueva contraseña';
  String get confirmPassword =>
      isEn ? 'Confirm password' : 'Confirmar contraseña';
  String get passwordHint => isEn
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
  String get manageWorkouts => isEn ? 'Manage Workouts' : 'Gestionar Rutinas';
  String get manageWorkoutsSubtitle => isEn
      ? 'Create, edit and assign workouts'
      : 'Crear, editar y asignar rutinas';
  String get manageMealPlans =>
      isEn ? 'Manage Meal Plans' : 'Gestionar Planes Alimenticios';
  String get manageMealPlansSubtitle =>
      isEn ? 'Create and assign diets' : 'Crear y asignar dietas';
  String get adminPanel => isEn ? 'Admin Panel' : 'Panel de Administración';
  String get adminPanelSubtitle =>
      isEn ? 'View stats and users' : 'Ver estadísticas y usuarios';
  String welcomeUser(String name) => isEn ? 'Hello, $name!' : '¡Hola, $name!';
  String get welcomeAdmin => isEn ? 'Hello, Trainer!' : '¡Hola, Entrenador!';

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
  String get noHistoryBody => isEn
      ? 'Complete your first workout\nto see your progress here'
      : 'Completa tu primer entrenamiento\npara ver tu progreso aquí';
  String get exploreWorkouts =>
      isEn ? 'Explore workouts' : 'Explorar entrenamientos';
  String exercisesCount(int n) => isEn ? '$n exercises' : '$n ejercicios';
  String percentCompleted(int p) => isEn ? '$p% completed' : '$p% completado';

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
  String get contactTrainer => isEn
      ? 'Contact your trainer to get a workout assigned'
      : 'Contacta a tu entrenador para que te asigne una rutina';
  String get loadingWorkoutError =>
      isEn ? 'Error loading workout' : 'Error al cargar la rutina';
  String minutesAgoLabel(int m) => isEn ? '$m minutes ago' : 'hace $m minutos';
  String hoursAgoLabel(int h) => isEn ? '$h hours ago' : 'hace $h horas';
  String daysAgoLowerLabel(int d) => isEn ? '$d days ago' : 'hace $d días';

  // ── Resumen de entrenamiento ─────────────────────────────────────────────
  String get workoutSummaryTitle =>
      isEn ? 'Workout Summary' : 'Resumen de Entrenamiento';
  String get workoutCompletedLine1 => isEn ? 'Workout' : '¡Entrenamiento';
  String get workoutCompletedLine2 => isEn ? 'Completed!' : 'Completado!';
  String get exerciseSummaryLabel =>
      isEn ? 'Exercise Summary' : 'Resumen de Ejercicios';
  String get nextSessionLabel => isEn ? 'Next Session' : 'Próxima Sesión';
  String get backToHome => isEn ? 'Back to Home' : 'Volver al Inicio';
  String get nextWorkoutDefault => isEn ? 'Next Workout' : 'Próxima Rutina';
  String get nextWorkoutMsg1 => isEn
      ? 'Get ready for your next session!'
      : '¡Prepárate para tu próxima sesión!';
  String get nextWorkoutMsg2 => isEn
      ? "Don't forget to rest and eat well before your next workout!"
      : '¡No olvides descansar y alimentarte bien antes de tu próxima rutina!';
  List<String> get motivationalMessages => isEn
      ? [
          'INCREDIBLE WORK!',
          'YOU DID IT!',
          'EXCELLENT!',
          'UNSTOPPABLE!',
          'BRUTAL WORKOUT!',
          'KEEP IT UP CHAMP!',
          'SPECTACULAR!',
          'WHAT A MACHINE!'
        ]
      : [
          '¡INCREÍBLE TRABAJO!',
          '¡LO LOGRASTE!',
          '¡EXCELENTE!',
          '¡ERES IMPARABLE!',
          '¡BRUTAL ENTRENAMIENTO!',
          '¡SIGUE ASÍ CAMPEÓN!',
          '¡ESPECTACULAR!',
          '¡QUÉ MÁQUINA!'
        ];

  // ── Progreso ─────────────────────────────────────────────────────────────
  String get myProgress => isEn ? 'My Progress' : 'Mi Progreso';
  // Períodos — usados como labels visibles; las claves internas siguen siendo ES
  List<String> get periodLabels => isEn
      ? ['Week', 'Month', 'Year', 'All']
      : ['Semana', 'Mes', 'Año', 'Todo'];
  List<String> get periodKeys => ['Semana', 'Mes', 'Año', 'Todo'];
  String periodLabel(String key) {
    final idx = periodKeys.indexOf(key);
    return idx >= 0 ? periodLabels[idx] : key;
  }

  String get currentStreakLabel => isEn ? 'Current Streak' : 'Racha Actual';
  String consecutiveDaysLabel(int n) => isEn
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
  String get notTrainedYet => isEn ? 'Not trained yet' : 'Aún no has entrenado';
  String get startBurningCalories =>
      isEn ? 'Start burning calories' : 'Comienza a quemar calorías';
  String get addMeasurementsHint => isEn
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
  String get bodyMeasurementsSubtitle => isEn
      ? 'Track and follow your measurements'
      : 'Registra y sigue tus medidas';
  String get completeWorkoutForStats => isEn
      ? 'Complete a workout to see stats'
      : 'Completa un entreno para ver estadísticas';
  String sessionsCount(int n) => isEn
      ? '$n session${n == 1 ? '' : 's'}'
      : '$n sesión${n == 1 ? '' : 'es'}';
  String get noData => isEn ? 'No data' : 'Sin datos';
  String get achievementsUnlockHint => isEn
      ? 'Complete workouts to unlock achievements'
      : 'Completa entrenamientos para desbloquear logros';
  String timeAgoLabel(int days, int hours) {
    if (days > 0) {
      return isEn
          ? '$days day${days > 1 ? 's' : ''} ago'
          : 'Hace $days día${days > 1 ? 's' : ''}';
    }
    if (hours > 0) {
      return isEn
          ? '$hours hour${hours > 1 ? 's' : ''} ago'
          : 'Hace $hours hora${hours > 1 ? 's' : ''}';
    }
    return isEn ? 'A few moments ago' : 'Hace unos momentos';
  }

  // ── Perfil ───────────────────────────────────────────────────────────────
  String get myProfile => isEn ? 'My Profile' : 'Mi Perfil';
  String get takePhoto => isEn ? 'Take photo' : 'Tomar foto';
  String get galleryLabel => isEn ? 'Gallery' : 'Galería';
  String get profileUpdated => isEn
      ? 'Profile updated successfully'
      : 'Perfil actualizado correctamente';
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
  String get workoutInProgressBody => isEn
      ? 'You have a workout in progress. Continue it or start this one as extra?'
      : 'Tienes una rutina en curso. ¿Quieres continuar esa o iniciar esta como extra?';
  String get continueInProgress =>
      isEn ? 'Continue in progress' : 'Continuar en progreso';
  String get startThisWorkout =>
      isEn ? 'Start this workout' : 'Iniciar esta rutina';
  String get deleteWorkoutTitle =>
      isEn ? 'Delete workout?' : '¿Eliminar rutina?';
  String deleteWorkoutConfirm(String name) => isEn
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
  String get noMeasurementsBody => isEn
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
  String get aboutContent => isEn
      ? 'Version 1.0.0\n\nYour perfect companion to reach your fitness goals.\n\n© 2026 Chamos Fitness Center'
      : 'Versión 1.0.0\n\nTu compañero perfecto para alcanzar tus metas de fitness.\n\n© 2026 Chamos Fitness Center';

  // ── Onboarding ───────────────────────────────────────────────────────────
  String get onboardingWelcome =>
      isEn ? 'Welcome to Chamos Fitness!' : '¡Bienvenido a Chamos Fitness!';
  String get onboardingWelcomeBody => isEn
      ? 'Your perfect companion to reach your fitness goals. Let\'s personalize your experience.'
      : 'Tu compañero perfecto para alcanzar tus metas de fitness. Vamos a personalizar tu experiencia.';
  String get onboardingLevelTitle =>
      isEn ? 'What is your fitness level?' : '¿Cuál es tu nivel de fitness?';
  String get onboardingStatsTitle =>
      isEn ? 'Your personal data' : 'Tus datos personales';
  String get onboardingStatsSubtitle => isEn
      ? 'This data helps us calculate your calories accurately'
      : 'Estos datos nos ayudan a calcular tus calorías con precisión';
  String get weightLabel => isEn ? 'Weight' : 'Peso';
  String get heightLabel => isEn ? 'Height' : 'Altura';
  String get ageLabel => isEn ? 'Age' : 'Edad';
  String ageValue(int age) => isEn ? '$age years' : '$age años';
  String get biologicalSex => isEn ? 'Biological sex' : 'Sexo biológico';
  String get biologicalSexHint =>
      isEn ? 'Used for calorie formula' : 'Usado para la fórmula de calorías';
  String get male => isEn ? 'Male' : 'Hombre';
  String get female => isEn ? 'Female' : 'Mujer';
  String get preferNotToSay => isEn ? 'Prefer not to say' : 'Prefiero no decir';
  String get onboardingGoalTitle =>
      isEn ? 'What is your goal?' : '¿Cuál es tu objetivo?';
  String get goalLoseWeight => isEn ? 'Lose weight' : 'Perder peso';
  String get goalGainMuscle => isEn ? 'Gain muscle' : 'Ganar músculo';
  String get goalMaintain => isEn ? 'Maintain weight' : 'Mantener peso';
  String get goalImproveHealth => isEn ? 'Improve health' : 'Mejorar salud';
  String get back => isEn ? 'Back' : 'Atrás';
  String get start => isEn ? 'Start' : 'Comenzar';
  String get next => isEn ? 'Next' : 'Siguiente';
  String get beginner => isEn ? 'Beginner' : 'Principiante';
  String get beginnerDesc =>
      isEn ? 'New to training' : 'Nuevo en el entrenamiento';
  String get intermediate => isEn ? 'Intermediate' : 'Intermedio';
  String get intermediateDesc =>
      isEn ? 'I train regularly' : 'Entreno regularmente';
  String get advanced => isEn ? 'Advanced' : 'Avanzado';
  String get advancedDesc =>
      isEn ? 'Experienced athlete' : 'Atleta experimentado';

  // ── Admin ────────────────────────────────────────────────────────────────
  String get noWorkoutsInCategory => isEn
      ? 'No workouts in this category'
      : 'No hay rutinas en esta categoría';
  String get assignHint => isEn
      ? 'Use the 3-dot menu on each user to assign or edit their weekly workout'
      : 'Usa los 3 puntos de cada usuario para asignar o editar su rutina semanal';
  String get noUsersFound =>
      isEn ? 'No users found' : 'No se encontraron usuarios';
  String get noRegisteredUsers =>
      isEn ? 'No registered users' : 'No hay usuarios registrados';
  String get reloadingUsers =>
      isEn ? 'Reloading users...' : 'Recargando usuarios...';
  String get tryAnotherSearch =>
      isEn ? 'Try another search' : 'Intenta con otra búsqueda';
  String get noUsersWithRole =>
      isEn ? 'No users with this role' : 'No hay usuarios con este rol';
  String get noWorkoutsAvailable =>
      isEn ? 'No workouts available' : 'No hay rutinas disponibles';
  String get noExercisesFound =>
      isEn ? 'No exercises found' : 'No se encontraron ejercicios';
  String errorSaving(String e) =>
      isEn ? 'Error saving: $e' : 'Error al guardar: $e';

  // ── Onboarding dialog ────────────────────────────────────────────────────
  String get useDefaultValues =>
      isEn ? 'Use default values?' : '¿Usar valores por defecto?';
  String get defaultValuesBody => isEn
      ? 'You haven\'t modified your data. Are you sure these values are correct?'
      : 'No has modificado tus datos. ¿Estás seguro de que estos valores son correctos?';
  String get onboardingErrorSaving =>
      isEn ? 'Error saving' : 'Error al guardar';

  // ── Admin management ─────────────────────────────────────────────────────
  String get userUpdated =>
      isEn ? 'User updated successfully' : 'Usuario actualizado correctamente';
  String get editUser => isEn ? 'Edit user' : 'Editar usuario';
  String get nameLabel => isEn ? 'Name' : 'Nombre';
  String get removeAdmin => isEn ? 'Remove admin' : 'Quitar admin';
  String get makeAdmin => isEn ? 'Make admin' : 'Hacer admin';
  String userNowAdmin(String name) =>
      isEn ? '$name is now admin' : '$name es ahora administrador';
  String adminRemovedFrom(String name) => isEn
      ? 'Admin permissions removed from $name'
      : 'Permisos de admin removidos de $name';
  String get confirmDeletion =>
      isEn ? 'Confirm deletion' : 'Confirmar eliminación';
  String confirmDeleteUser(String name) => isEn
      ? 'Are you sure you want to delete $name? This action cannot be undone.'
      : '¿Estás seguro de eliminar a $name? Esta acción no se puede deshacer.';
  String get userDeleted =>
      isEn ? 'User deleted successfully' : 'Usuario eliminado correctamente';
  String get deleteLabel => isEn ? 'Delete' : 'Eliminar';
  String get routineDeleted => isEn ? 'Routine removed' : 'Rutina eliminada';
  String errorDeletingRoutine(String e) =>
      isEn ? 'Error deleting routine: $e' : 'Error al eliminar la rutina: $e';
  String get routineSaved =>
      isEn ? 'Routine saved successfully' : 'Rutina guardada correctamente';
  String get discardChanges =>
      isEn ? 'Discard changes?' : '¿Descartar cambios?';
  String get discardChangesBody => isEn
      ? 'You have unsaved changes. Do you want to discard them?'
      : 'Hay cambios no guardados. ¿Deseas descartarlos?';
  String get discard => isEn ? 'Discard' : 'Descartar';

  // ── Auth / errors ────────────────────────────────────────────────────────
  String get enterEmail =>
      isEn ? 'Enter your email' : 'Ingresa tu correo electrónico';
  String get search => isEn ? 'Search' : 'Buscar';

  // ── Admin dashboard ──────────────────────────────────────────────────────
  String get quickManagement => isEn ? 'QUICK MANAGEMENT' : 'GESTIÓN RÁPIDA';
  String get userManagement => isEn ? 'User management' : 'Gestión de usuarios';
  String get userAssignments =>
      isEn ? 'User assignments' : 'Asignaciones de usuarios';
  String get newWorkoutRoutine =>
      isEn ? 'New workout routine' : 'Nueva rutina de entrenamiento';
  String get editUserLabel => isEn ? 'Edit user' : 'Editar usuario';
  String get deleteUser => isEn ? 'Delete user' : 'Eliminar usuario';

  // ── Workout screens ────────────────────────────────────────────────────
  String get addAtLeastOneExercise =>
      isEn ? 'Add at least one exercise' : 'Agrega al menos un ejercicio';
  String get routineCreated =>
      isEn ? 'Routine created successfully' : 'Rutina creada exitosamente';
  String get couldNotCreateRoutine => isEn
      ? 'Could not create routine. Try again.'
      : 'No se pudo crear la rutina. Intenta de nuevo.';
  String get routineUpdated => isEn
      ? 'Routine updated successfully'
      : 'Rutina actualizada correctamente';
  String errorUpdating(String e) =>
      isEn ? 'Error updating: $e' : 'Error al actualizar: $e';
  String get routineDeletedOk =>
      isEn ? 'Routine deleted successfully' : 'Rutina eliminada correctamente';
  String errorDeleting(String e) =>
      isEn ? 'Error deleting: $e' : 'Error al eliminar: $e';
  String errorSelectingVideo(String e) =>
      isEn ? 'Error selecting video: $e' : 'Error al seleccionar video: $e';
  String get videoUploaded =>
      isEn ? 'Video uploaded successfully' : 'Video subido exitosamente';
  String errorUploadingVideo(String e) =>
      isEn ? 'Error uploading video: $e' : 'Error al subir video: $e';
  String get exerciseNameRequired => isEn
      ? 'Exercise name is required'
      : 'El nombre del ejercicio es requerido';

  // ── Today workout ──────────────────────────────────────────────────────
  String get couldNotSaveProgress => isEn
      ? 'Could not save progress. Check your connection.'
      : 'No se pudo guardar el progreso. Verifica tu conexión.';
  String get couldNotSaveWeights => isEn
      ? 'Could not save session weights'
      : 'No se pudieron guardar los pesos de esta sesión';
  String get enterValidNumber =>
      isEn ? 'Enter a valid number' : 'Ingresa un número válido';
  String get weightMustBePositive =>
      isEn ? 'Weight must be greater than 0' : 'El peso debe ser mayor a 0';
  String newPersonalRecord(String w) =>
      isEn ? 'New personal record! $w' : '¡Nuevo récord personal! $w';

  // ── Body measurements ──────────────────────────────────────────────────
  String get enterAtLeastOneMeasure =>
      isEn ? 'Enter at least one measurement' : 'Ingresa al menos una medida';
  String get valuesMustBePositive => isEn
      ? 'Values must be positive numbers'
      : 'Los valores deben ser números positivos';
  String valueTooHigh(int max) =>
      isEn ? 'Value too high (max: $max)' : 'Valor demasiado alto (máx: $max)';
  String get measureSaved =>
      isEn ? 'Measurement saved' : 'Medida guardada correctamente';
  String get errorSavingMeasure =>
      isEn ? 'Error saving measurement' : 'Error al guardar medida';

  // ── Change password ────────────────────────────────────────────────────
  String get passwordChanged => isEn
      ? 'Password changed successfully ✅'
      : 'Contraseña cambiada exitosamente ✅';
  String errorChangingPassword(String e) =>
      isEn ? 'Error changing password: $e' : 'Error al cambiar contraseña: $e';

  // ── Profile photo ──────────────────────────────────────────────────────
  String get unsupportedFormat => isEn
      ? 'Unsupported format. Use JPG, PNG or WebP.'
      : 'Formato no soportado. Usa JPG, PNG o WebP.';
  String get imageTooLarge => isEn
      ? 'Image too large. Max 5 MB.'
      : 'La imagen es muy grande. Máximo 5 MB.';
  String get profilePhotoUpdated =>
      isEn ? 'Profile photo updated' : 'Foto de perfil actualizada';
  String errorUploadingPhoto(String e) =>
      isEn ? 'Error uploading photo: $e' : 'Error al subir foto: $e';

  // ── Workout detail readonly ────────────────────────────────────────────
  String get cancelLabel => isEn ? 'Cancel' : 'Cancelar';
  String get deleteConfirm => isEn ? 'Delete' : 'Eliminar';

  // ── User management ──────────────────────────────────────────────────
  String get filterAll => isEn ? 'All' : 'Todos';
  String get filterAdmins => isEn ? 'Admins' : 'Admins';
  String get filterUsers => isEn ? 'Users' : 'Usuarios';
  String get totalUsersLabel => isEn ? 'Total users' : 'Total usuarios';
  String get administratorsLabel => isEn ? 'Administrators' : 'Administradores';
  String get reloadUsersTooltip => isEn ? 'Reload users' : 'Recargar usuarios';
  String get usersWillAppear => isEn
      ? 'Users will appear here once they register'
      : 'Los usuarios aparecerán aquí cuando se registren';
  String get reloadLabel => isEn ? 'Reload' : 'Recargar';
  String levelAndWorkoutsInfo(String level, int workouts) => isEn
      ? 'Level: $level · $workouts workouts'
      : 'Nivel: $level · $workouts entrenamientos';

  // ── Assign plans ─────────────────────────────────────────────────────
  String get mondayFull => isEn ? 'Monday' : 'Lunes';
  String get tuesdayFull => isEn ? 'Tuesday' : 'Martes';
  String get wednesdayFull => isEn ? 'Wednesday' : 'Miércoles';
  String get thursdayFull => isEn ? 'Thursday' : 'Jueves';
  String get fridayFull => isEn ? 'Friday' : 'Viernes';
  String get saturdayFull => isEn ? 'Saturday' : 'Sábado';
  String get monShort => isEn ? 'MO' : 'LU';
  String get tueShort => isEn ? 'TU' : 'MA';
  String get wedShort => isEn ? 'WE' : 'MI';
  String get thuShort => isEn ? 'TH' : 'JU';
  String get friShort => isEn ? 'FR' : 'VI';
  String get satShort => isEn ? 'SA' : 'SÁ';
  String get restDay => isEn ? 'Rest day' : 'Día de descanso';
  String get noRoutineAssigned =>
      isEn ? 'No routine assigned' : 'Sin rutina asignada';
  String exerciseCountLabel(int count) =>
      isEn ? '$count exercises' : '$count ejercicios';
  String get assignRoutineSubtitle =>
      isEn ? 'ASSIGN ROUTINE' : 'ASIGNAR RUTINA';
  String get clearScheduleTooltip =>
      isEn ? 'Clear schedule' : 'Limpiar horario';
  String get clearScheduleTitle =>
      isEn ? 'Clear schedule?' : '¿Limpiar horario?';
  String get clearScheduleBody => isEn
      ? 'All assigned routines for these days will be removed. You must save to apply changes.'
      : 'Se quitarán todas las rutinas asignadas a los días. Debes guardar para aplicar los cambios.';
  String get clearLabel => isEn ? 'Clear' : 'Limpiar';
  String get weeklyRoutineHeader => isEn ? 'WEEKLY ROUTINE' : 'RUTINA SEMANAL';
  String get tapDayToAssign =>
      isEn ? 'Tap a day to assign' : 'Toca un día para asignar';
  String get restDayMessage => isEn ? 'Rest day! 💤' : '¡Día de descanso! 💤';
  String nextTrainingDay(String day) =>
      isEn ? 'Next training: $day' : 'Próximo entreno: $day';
  String get modifiedBadge => isEn ? 'modified' : 'modificado';
  String get saveRoutine => isEn ? 'Save routine' : 'Guardar rutina';
  String levelInfo(String level) => isEn ? 'Level: $level' : 'Nivel: $level';
  String get closeLabel => isEn ? 'Close' : 'Cerrar';

  // ── Settings extra ───────────────────────────────────────────────────
  String get backTooltip => isEn ? 'Back' : 'Volver';
  String get reminderTime => isEn ? 'Reminder time' : 'Hora del recordatorio';
  String get workoutReminderTime =>
      isEn ? 'Workout reminder time' : 'Hora del recordatorio de entrenamiento';
  String reminderScheduled(String h, String m, String period) => isEn
      ? 'Reminder scheduled for $h:$m $period every day'
      : 'Recordatorio programado para las $h:$m $period todos los días';
  String get testNotification =>
      isEn ? 'Test notification' : 'Probar notificación';
  String get testNotificationSubtitle => isEn
      ? 'Send a workout notification now'
      : 'Envía una notificación de entrenamiento ahora';
  String get notifPermissionDenied => isEn
      ? 'Notification permission denied. Enable it from system Settings.'
      : 'Permiso de notificaciones denegado. Actívalo desde Ajustes del sistema.';
  String get workoutTimeTitle =>
      isEn ? '💪 Time to train' : '💪 Hora de entrenar';
  String get workoutTimeBody => isEn
      ? "Don't forget today's routine! Your body will thank you."
      : '¡No olvides tu rutina de hoy! Tu cuerpo te lo agradecerá.';
  String get notificationSent =>
      isEn ? 'Notification sent' : 'Notificación enviada';
  String get exportMyData => isEn ? 'Export my data' : 'Exportar mis datos';
  String get exportMyDataSubtitle => isEn
      ? 'Download all your information in JSON format'
      : 'Descarga toda tu información en formato JSON';
  String get chamosFitness => 'Chamos Fitness';
  String get preparingExport =>
      isEn ? 'Preparing export...' : 'Preparando exportación...';
  String errorExportingData(String e) =>
      isEn ? 'Error exporting data: $e' : 'Error al exportar datos: $e';
  String get discardChangesTitle =>
      isEn ? 'Discard changes?' : '¿Descartar cambios?';
  String get discardPasswordBody => isEn
      ? 'Leave without changing the password?'
      : '¿Salir sin cambiar la contraseña?';
  String get exitLabel => isEn ? 'Exit' : 'Salir';

  // ── Edit profile ─────────────────────────────────────────────────────
  String get editProfile => isEn ? 'Edit profile' : 'Editar perfil';
  String get discardProfileBody => isEn
      ? 'Are you sure you want to leave without saving changes?'
      : '¿Estás seguro de que quieres salir sin guardar los cambios?';
  String get personalInfo =>
      isEn ? 'Personal information' : 'Información personal';
  String get trainingLevelSection =>
      isEn ? 'Training level' : 'Nivel de entrenamiento';
  String get bodyMeasurementsTip => isEn
      ? 'Record your weight, height, and measurements in the "Body Measurements" section.'
      : 'Registra tu peso, altura y medidas en la sección "Medidas Corporales".';

  // ── Body measurements extra ──────────────────────────────────────────
  String get chestLabel => isEn ? 'Chest' : 'Pecho';
  String get waistLabel => isEn ? 'Waist' : 'Cintura';
  String get hipLabel => isEn ? 'Hip' : 'Cadera';
  String get leftBicep => isEn ? 'Left Bicep' : 'Bícep Izq.';
  String get rightBicep => isEn ? 'Right Bicep' : 'Bícep Der.';
  String get leftThigh => isEn ? 'Left Thigh' : 'Muslo Izq.';
  String get rightThigh => isEn ? 'Right Thigh' : 'Muslo Der.';
  String get leftBicepFull => isEn ? 'Left Bicep' : 'Bícep Izquierdo';
  String get rightBicepFull => isEn ? 'Right Bicep' : 'Bícep Derecho';
  String get leftThighFull => isEn ? 'Left Thigh' : 'Muslo Izquierdo';
  String get rightThighFull => isEn ? 'Right Thigh' : 'Muslo Derecho';
  String daysAgo(int days) => isEn ? '$days days ago' : 'Hace $days días';
  String get leftBicepShort => isEn ? 'L.Bic' : 'B.Izq';
  String get rightBicepShort => isEn ? 'R.Bic' : 'B.Der';
  String get leftThighShort => isEn ? 'L.Thi' : 'M.Izq';
  String get rightThighShort => isEn ? 'R.Thi' : 'M.Der';
  String get discardMeasurementsTitle =>
      isEn ? 'Discard measurements?' : '¿Descartar medidas?';
  String get discardMeasurementsBody => isEn
      ? 'Are you sure you want to leave without saving the measurements?'
      : '¿Estás seguro de que quieres salir sin guardar las medidas?';
  String get discardLabel => isEn ? 'Discard' : 'Descartar';
  String weightUnit(String unit) => isEn ? 'Weight ($unit)' : 'Peso ($unit)';
  String heightUnit(String unit) => isEn ? 'Height ($unit)' : 'Altura ($unit)';
  String measureUnit(String label, String unit) => '$label ($unit)';
  String get notesOptional => isEn ? 'Notes (optional)' : 'Notas (opcional)';

  // ── Create workout ───────────────────────────────────────────────────
  String get newCategory => isEn ? 'New category' : 'Nueva categoría';
  String get categoryHint => isEn
      ? 'E.g.: Shoulders, HIIT, Functional...'
      : 'Ej: Hombros, HIIT, Funcional...';
  String get addLabel => isEn ? 'Add' : 'Agregar';
  String get manageCategories =>
      isEn ? 'Manage categories' : 'Gestionar categorías';
  String get defaultCategoriesInfo => isEn
      ? 'Default categories cannot be deleted.'
      : 'Las categorías predeterminadas no se pueden eliminar.';
  String get discardWorkoutBody => isEn
      ? 'Are you sure you want to leave without saving the routine?'
      : '¿Estás seguro de que quieres salir sin guardar la rutina?';
  String get newRoutine => isEn ? 'New routine' : 'Nueva rutina';
  String get routineNameLabel => isEn ? 'Routine name' : 'Nombre de la rutina';
  String get routineNameHint => isEn ? 'E.g.: Strength' : 'Ej: Fuerza';
  String get enterAName => isEn ? 'Enter a name' : 'Ingresa un nombre';
  String get descriptionLabel => isEn ? 'Description' : 'Descripción';
  String get descriptionHint => isEn
      ? 'Describe the goals of this routine...'
      : 'Describe los objetivos de esta rutina...';
  String get enterADescription =>
      isEn ? 'Enter a description' : 'Ingresa una descripción';
  String get levelLabel => isEn ? 'Level' : 'Nivel';
  String get categoryLabel => isEn ? 'Category' : 'Categoría';
  String get selectACategory =>
      isEn ? 'Select a category' : 'Selecciona una categoría';
  String get noCategory => isEn ? 'No category' : 'Sin categoría';
  String get exercisesSection => isEn ? 'Exercises' : 'Ejercicios';
  String get noExercises => isEn ? 'No exercises' : 'No hay ejercicios';
  String get addExercisesHint => isEn
      ? 'Add exercises to create the routine'
      : 'Agrega ejercicios para crear la rutina';
  String get addExerciseTitle => isEn ? 'Add Exercise' : 'Agregar Ejercicio';
  String get exerciseNameLabel =>
      isEn ? 'Exercise name' : 'Nombre del ejercicio';
  String get exerciseNameHint =>
      isEn ? 'E.g.: Bench press' : 'Ej: Press de banca';
  String get requiredField => isEn ? 'Required' : 'Requerido';
  String get setsLabel => isEn ? 'Sets' : 'Series';
  String get repsLabel => isEn ? 'Reps' : 'Reps';
  String get invalidNumber => isEn ? 'Invalid number' : 'Número inválido';
  String get restSecondsLabel =>
      isEn ? 'Rest (seconds)' : 'Descanso (segundos)';
  String get weightLbs => isEn ? 'Weight (lbs)' : 'Peso (lbs)';
  String get weightLbsHint => isEn
      ? 'E.g.: 20 — leave empty for bodyweight'
      : 'Ej: 20  —  dejar vacío si es peso corporal';
  String get exerciseVideoOptional =>
      isEn ? 'Exercise video (optional)' : 'Video del ejercicio (opcional)';
  String get selectVideo => isEn ? 'Select video' : 'Seleccionar video';
  String get uploading => isEn ? 'Uploading...' : 'Subiendo...';
  String get uploadVideo => isEn ? 'Upload Video' : 'Subir Video';
  String get videoUploadedOk =>
      isEn ? 'Video uploaded successfully' : 'Video subido exitosamente';
  String get discardExerciseTitle =>
      isEn ? 'Discard exercise?' : '¿Descartar ejercicio?';
  String get discardExerciseBody => isEn
      ? 'Are you sure you want to leave without adding this exercise?'
      : '¿Estás seguro de que quieres salir sin agregar este ejercicio?';

  // ── Notification service ─────────────────────────────────────────────
  String get notifChannelName => 'Chamos Fitness';
  String get notifChannelDesc => isEn
      ? 'Chamos Fitness Center notifications'
      : 'Notificaciones de Chamos Fitness Center';
  String get notifInactiveTitle =>
      isEn ? 'Everything ok? 💪' : '¿Todo bien? 💪';
  String notifInactiveBody(int daysSince) => isEn
      ? "You haven't trained in $daysSince days. Today is a great day to get back!"
      : 'Llevas $daysSince días sin entrenar. ¡Hoy es un buen día para retomar!';
  String get notifFirstSessionTitle =>
      isEn ? 'Start today! 💪' : '¡Empieza hoy! 💪';
  String get notifFirstSessionBody => isEn
      ? 'Ready for your first session? Your body will thank you!'
      : '¿Listo para tu primera sesión? ¡Tu cuerpo te lo agradecerá!';
  String get notifAchievementTitle =>
      isEn ? '🏆 Achievement Unlocked!' : '🏆 ¡Logro Desbloqueado!';
  String get progressReportsChannel =>
      isEn ? 'Progress Reports' : 'Reportes de Progreso';
  String get progressReportsChannelDesc => isEn
      ? 'Chamos Fitness Center weekly progress reports'
      : 'Reportes semanales de progreso de Chamos Fitness Center';
  String get weeklyReportTitle =>
      isEn ? '📊 Weekly report' : '📊 Reporte semanal';
  String get weeklyReportBody => isEn
      ? 'Open the app to see your summary for this week.'
      : 'Abre la app para ver tu resumen de esta semana.';

  // ── Misc / duration format ───────────────────────────────────────────
  String durationMinExercises(int min, int count) =>
      isEn ? '$min min · $count exercises' : '$min min · $count ejercicios';
}
