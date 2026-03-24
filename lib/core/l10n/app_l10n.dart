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
  String get searchExercisesHint =>
      isEn ? 'Search exercises...' : 'Buscar ejercicios...';
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

  // ── Auth ──────────────────────────────────────────────────────────────
  String get fillAllFields => isEn
      ? 'Please fill in all fields'
      : 'Por favor completa todos los campos';
  String get enterValidEmail => isEn
      ? 'Please enter a valid email address'
      : 'Por favor ingresa un correo electrónico válido';
  String get loginFailed => isEn
      ? 'Could not complete login. Check your credentials.'
      : 'No se pudo completar el inicio de sesión. Verifica tus credenciales.';
  String get loginErrorTitle =>
      isEn ? 'Login error' : 'Error al iniciar sesión';
  String get unexpectedError => isEn
      ? 'An unexpected error occurred. Try again.'
      : 'Ocurrió un error inesperado. Intenta nuevamente.';
  String get wrongCredentialsTitle =>
      isEn ? 'Wrong credentials' : 'Credenciales incorrectas';
  String get wrongCredentialsMsg => isEn
      ? 'The email or password is incorrect.\n\nForgot your password?'
      : 'El correo electrónico o la contraseña son incorrectos.\n\n¿Olvidaste tu contraseña?';
  String get connectionErrorTitle =>
      isEn ? 'Connection error' : 'Error de conexión';
  String get connectionErrorMsg => isEn
      ? 'Could not connect to the server.\nCheck your internet connection.'
      : 'No se pudo conectar al servidor.\nVerifica tu conexión a internet.';
  String get userNotFoundTitle =>
      isEn ? 'User not found' : 'Usuario no encontrado';
  String get userNotFoundMsg => isEn
      ? 'No account exists with this email.\n\nWould you like to register?'
      : 'No existe una cuenta con este correo electrónico.\n\n¿Quieres registrarte?';
  String get signMeUp => isEn ? 'Sign up' : 'Registrarme';
  String get signInTab => isEn ? 'Sign in' : 'Iniciar sesión';
  String get signUpTab => isEn ? 'Sign up' : 'Registrarse';
  String get welcomeTitle => isEn ? 'Welcome' : 'Bienvenido';
  String get welcomeSubtitle => isEn
      ? 'Your best version starts here.'
      : 'Tu mejor versión comienza aquí.';
  String get emailLabel => isEn ? 'Email' : 'Correo Electrónico';
  String get emailLabelUpper => isEn ? 'EMAIL' : 'CORREO ELECTRÓNICO';
  String get passwordFieldLabel => isEn ? 'Password' : 'Contraseña';
  String get passwordLabelUpper => isEn ? 'PASSWORD' : 'CONTRASEÑA';
  String get min8Chars => isEn ? 'Minimum 8 characters' : 'Mínimo 8 caracteres';
  String get max15Chars =>
      isEn ? 'Maximum 15 characters' : 'Máximo 15 caracteres';
  String get forgotPassword =>
      isEn ? 'Forgot your password?' : '¿Olvidaste tu contraseña?';
  String get signingIn => isEn ? 'Signing in...' : 'Ingresando...';
  String get enterGym => isEn ? 'Enter the gym' : 'Entrar al gimnasio';
  String get acceptTermsText => isEn
      ? 'By continuing, you confirm that you accept our\n'
      : 'Al continuar, confirmas que aceptas nuestros\n';
  String get termsOfServiceLabel =>
      isEn ? 'TERMS OF SERVICE' : 'TÉRMINOS DE SERVICIO';
  String get privacyLabel => isEn ? 'PRIVACY' : 'PRIVACIDAD';
  String get passwordMin8 => isEn
      ? 'Password must be at least 8 characters'
      : 'La contraseña debe tener al menos 8 caracteres';
  String get passwordMax15 => isEn
      ? 'Password cannot be longer than 15 characters'
      : 'La contraseña no puede tener más de 15 caracteres';
  String get passwordNeedsUppercase => isEn
      ? 'Password must have at least one uppercase letter'
      : 'La contraseña debe tener al menos una letra mayúscula';
  String get passwordNeedsLowercase => isEn
      ? 'Password must have at least one lowercase letter'
      : 'La contraseña debe tener al menos una letra minúscula';
  String get passwordNeedsNumber => isEn
      ? 'Password must have at least one number'
      : 'La contraseña debe tener al menos un número';
  String get registerFailed => isEn
      ? 'Could not complete registration. Try again.'
      : 'No se pudo completar el registro. Intenta nuevamente.';
  String get emailAlreadyExists => isEn
      ? 'An account with this email already exists.'
      : 'Ya existe una cuenta con este correo electrónico.';
  String get connectionError => isEn
      ? 'Connection error. Check your internet.'
      : 'Error de conexión. Verifica tu internet.';
  String registerError(String e) =>
      isEn ? 'Registration error: $e' : 'Error al registrar: $e';
  String get createYourAccount =>
      isEn ? 'Create your account' : 'Crea tu cuenta';
  String get registerSubtitle => isEn
      ? 'Enter your details to start training.'
      : 'Ingresa tus datos para empezar el entrenamiento.';
  String get confirmPasswordLabelUpper =>
      isEn ? 'CONFIRM PASSWORD' : 'CONFIRMAR CONTRASEÑA';
  String get iAcceptThe => isEn ? 'I accept the ' : 'Acepto los ';
  String get termsOfServiceLink =>
      isEn ? 'Terms of Service' : 'Términos de Servicio';
  String get andThe => isEn ? ' and the ' : ' y la ';
  String get privacyPolicyLinkText =>
      isEn ? 'Privacy Policy' : 'Política de Privacidad';
  String get ofChamosFitness =>
      isEn ? ' of Chamos Fitness Center.' : ' de Chamos Fitness Center.';
  String get signUpButton => isEn ? 'SIGN UP' : 'REGISTRARSE';
  String get alreadyMember =>
      isEn ? 'Already a member? ' : '¿Ya eres miembro? ';
  String get signInLink => isEn ? 'Sign in' : 'Inicio Sesión';

  // ── Forgot password ──────────────────────────────────────────────────
  String get recoverPasswordTitle =>
      isEn ? 'Recover password' : 'Recuperar contraseña';
  String get recoverPasswordDesc => isEn
      ? 'Enter your email and we will send you instructions to reset your access to the training center.'
      : 'Ingresa tu correo electrónico y te enviaremos las instrucciones para restablecer tu acceso al centro de entrenamiento.';
  String get emailFieldLabel => isEn ? 'Email' : 'Correo electrónico';
  String get checkSpamHint => isEn
      ? "If you don't receive the email in a few minutes, check your spam folder."
      : 'Si no recibes el correo en unos minutos, revisa tu carpeta de spam.';
  String get sendRecoveryLink =>
      isEn ? 'Send recovery link' : 'Enviar enlace de recuperación';
  String get rememberedPassword =>
      isEn ? 'Remembered your password? ' : '¿Recordaste tu contraseña? ';

  // ── Home extra ───────────────────────────────────────────────────────
  String get offlineBanner => isEn
      ? 'No connection · Showing saved data'
      : 'Sin conexión · Mostrando datos guardados';
  List<String> get dayNamesFull => isEn
      ? [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday'
        ]
      : [
          'lunes',
          'martes',
          'miércoles',
          'jueves',
          'viernes',
          'sábado',
          'domingo'
        ];
  String get availableTomorrow =>
      isEn ? 'Available tomorrow' : 'Disponible mañana';
  String availableOnDay(String day) =>
      isEn ? 'Available on $day' : 'Disponible el $day';
  String availableInDays(int count) =>
      isEn ? 'Available in $count days' : 'Disponible en $count días';
  String get activeDaysLabel => isEn ? 'Active days' : 'Días activos';
  String get sessionsStatLabel => isEn ? 'Sessions' : 'Sesiones';
  String get nextRoutineLabel => isEn ? 'Next routine' : 'Próxima rutina';
  String get scheduledRest => isEn ? 'Scheduled rest' : 'Descanso programado';
  String get yourAssignedRoutine =>
      isEn ? 'Your assigned routine' : 'Tu rutina asignada';
  String get loadingRoutines =>
      isEn ? 'Loading routines...' : 'Cargando rutinas...';
  String get restDayTitleHome => isEn ? 'Rest day! 💤' : '¡Día de descanso! 💤';
  String restDayMsgWithDay(String day) => isEn
      ? 'Rest and recover your muscles.\nYour next session is on $day'
      : 'Descansa y recupera músculos.\nTu próxima sesión es el $day';
  String get noWorkoutToday => isEn
      ? "You don't have a scheduled workout today.\nRest and recover your muscles."
      : 'Hoy no tienes entrenamiento programado.\nDescansa y recupera músculos.';
  String exerciseCountSimple(int count) =>
      isEn ? '$count exercises' : '$count ejercicios';
  String get trainNow => isEn ? 'TRAIN NOW' : 'ENTRENAR AHORA';
  String get routineNotFound =>
      isEn ? 'Routine not found' : 'Rutina no encontrada';
  String assignedRoutineUnavailable(String id) => isEn
      ? 'The assigned routine (ID: $id) is not available.'
      : 'La rutina asignada (ID: $id) no está disponible.';
  String get noAssignedRoutineTitle =>
      isEn ? "You don't have an assigned routine" : 'No tienes rutina asignada';
  String get trainerWillAssign => isEn
      ? 'Your trainer will assign you a routine soon'
      : 'Tu entrenador te asignará una rutina pronto';
  String get exploreLabel => isEn ? 'Explore' : 'Explorar';
  String get routinesLabel => isEn ? 'Routines' : 'Rutinas';
  String get plansLabel => isEn ? 'Plans' : 'Planes';
  String agoMin(int m) => isEn ? '${m}m ago' : 'hace $m min';
  String agoHours(int h) => isEn ? '${h}h ago' : 'hace ${h}h';
  String agoDays(int d) => isEn ? '${d}d ago' : 'hace ${d}d';
  String get routineInProgressBanner =>
      isEn ? 'ROUTINE IN PROGRESS' : 'RUTINA EN PROGRESO';
  String percentCompletedSimple(int p) =>
      isEn ? '$p% completed' : '$p% completado';

  // ── Workout list extra ───────────────────────────────────────────────
  String get routineFallback => isEn ? 'Routine' : 'Rutina';
  String get endRoutineTitle => isEn ? 'End routine' : 'Terminar rutina';
  String get endRoutineConfirm => isEn
      ? 'Are you sure you want to end the routine? Current progress will be lost.'
      : '¿Seguro que quieres terminar la rutina? Se perderá el progreso actual.';
  String get endAction => isEn ? 'End' : 'Terminar';
  String get allRoutines => isEn ? 'All routines' : 'Todas las rutinas';
  String get noRoutinesAvailable =>
      isEn ? 'No routines available' : 'No hay rutinas disponibles';
  String get officialRoutines =>
      isEn ? 'Official routines' : 'Rutinas oficiales';
  String get userRoutinesLabel =>
      isEn ? 'User routines' : 'Rutinas de usuarios';
  String get myRoutines => isEn ? 'My routines' : 'Mis rutinas';

  // ── Today workout extra ──────────────────────────────────────────────
  String get routineInCourseTitle =>
      isEn ? 'ROUTINE IN PROGRESS' : 'RUTINA EN CURSO';
  String get whatDoYouWantToDo =>
      isEn ? 'What do you want to do?' : '¿Qué quieres hacer?';
  String get continueRoutine => isEn ? 'Continue routine' : 'Continuar rutina';
  String get continueLater => isEn ? 'Continue later' : 'Continuar después';
  String get endRoutine => isEn ? 'End routine' : 'Terminar rutina';
  String weightSetTitle(int set) =>
      isEn ? 'Weight · Set $set' : 'Peso · Serie $set';
  String get noPreviousHistory =>
      isEn ? 'No previous history' : 'Sin historial previo';
  String get resumeTooltip => isEn ? 'Resume' : 'Reanudar';
  String get pauseTooltip => isEn ? 'Pause' : 'Pausar';

  // ── Edit workout ─────────────────────────────────────────────────────
  String get adminPortal => isEn ? 'ADMIN PORTAL' : 'ADMIN PORTAL';
  String get editRoutineTitle => isEn ? 'Edit Routine' : 'Editar Rutina';
  String get pleaseEnterName =>
      isEn ? 'Please enter a name' : 'Por favor ingresa un nombre';
  String get durationMinutesLabel =>
      isEn ? 'Duration (minutes)' : 'Duración (minutos)';
  String get pleaseEnterDuration =>
      isEn ? 'Please enter duration' : 'Por favor ingresa la duración';
  String get mustBeNumber => isEn ? 'Must be a number' : 'Debe ser un número';
  String get exercisesSectionUpper => isEn ? 'EXERCISES' : 'EJERCICIOS';
  String get addButton => isEn ? 'Add' : 'Agregar';
  String get noExercisesEditHint => isEn
      ? 'No exercises. Tap "Add" to start.'
      : 'No hay ejercicios. Toca "Agregar" para comenzar.';
  String confirmDeleteExercise(String name) => isEn
      ? 'Are you sure you want to delete "$name"? This cannot be undone.'
      : '¿Estás seguro de eliminar "$name"? Esta acción no se puede deshacer.';
  String get videoUploadFailed =>
      isEn ? 'Could not upload video' : 'No se pudo subir el video';
  String get newExercise => isEn ? 'New exercise' : 'Nuevo ejercicio';
  String get editExercise => isEn ? 'Edit exercise' : 'Editar ejercicio';
  String get muscleGroupLabel => isEn ? 'Muscle Group' : 'Grupo Muscular';
  String get exerciseVideoLabel =>
      isEn ? 'Exercise video' : 'Video del ejercicio';
  String get videoAvailable => isEn ? 'Video available' : 'Video disponible';
  String get restSecsLabel => isEn ? 'Rest (sec)' : 'Descanso (seg)';

  // ── Workout summary extra ────────────────────────────────────────────
  String get achievementUnlockedTitle =>
      isEn ? 'Achievement Unlocked!' : '¡Logro Desbloqueado!';
  String get achievementUnlockedMsg => isEn
      ? 'You unlocked a new achievement! Keep training to unlock more.'
      : '¡Desbloqueaste un nuevo logro! Sigue entrenando para desbloquear más.';
  String achievementUnlockedMsgCount(int count) => count == 1
      ? (isEn
          ? 'You unlocked a new achievement! Check your progress to see it.'
          : '¡Desbloqueaste un nuevo logro! Revisa tu progreso para verlo.')
      : (isEn
          ? 'You unlocked $count new achievements! Check your progress.'
          : '¡Desbloqueaste $count nuevos logros! Revisa tu progreso.');
  String get awesomeButton => isEn ? 'Awesome!' : '¡Genial!';
  String get comingSoonLabel => isEn ? 'Coming soon' : 'Próximamente';
  String get tomorrowLabel => isEn ? 'Tomorrow' : 'Mañana';
  String inDaysWithDate(int days, String date) =>
      isEn ? 'In $days days ($date)' : 'En $days días ($date)';
  String get timeStatLabel => isEn ? 'TIME' : 'TIEMPO';
  String get caloriesStatLabelUpper => isEn ? 'CALORIES' : 'CALORÍAS';
  String get volumeStatLabel => isEn ? 'VOLUME' : 'VOLUMEN';
  String get totalStatLabel => isEn ? 'TOTAL' : 'TOTAL';

  // ── Workout calendar extra ───────────────────────────────────────────
  String get workoutFallback => isEn ? 'Workout' : 'Entrenamiento';
  String get refreshTooltip => isEn ? 'Refresh' : 'Actualizar';
  String get totalTimeCalendar => isEn ? 'Total time' : 'Tiempo total';
  String get complianceLabel => isEn ? 'Compliance' : 'Cumplimiento';
  String get noScheduledWorkouts =>
      isEn ? 'No scheduled workouts' : 'Sin entrenamientos programados';
  String minutesCompletedLabel(int m) =>
      isEn ? '$m minutes completed' : '$m minutos completados';
  String get scheduledLabel => isEn ? 'Scheduled' : 'Programado';
  String get doneLabel => isEn ? '✓ Done' : '✓ Hecho';
  List<String> get monthNames => isEn
      ? [
          'january',
          'february',
          'march',
          'april',
          'may',
          'june',
          'july',
          'august',
          'september',
          'october',
          'november',
          'december'
        ]
      : [
          'enero',
          'febrero',
          'marzo',
          'abril',
          'mayo',
          'junio',
          'julio',
          'agosto',
          'septiembre',
          'octubre',
          'noviembre',
          'diciembre'
        ];

  // ── Workout detail readonly extra ────────────────────────────────────
  String get routineInProgressTitle =>
      isEn ? 'Routine in progress' : 'Rutina en progreso';
  String get routineInProgressMsg => isEn
      ? 'You have a routine in progress. Continue it or start this one as extra?'
      : 'Tienes una rutina en curso. ¿Quieres continuarla o iniciar esta como extra?';
  String get startThisLabel => isEn ? 'Start this' : 'Iniciar esta';
  String get goBackTooltip => isEn ? 'Back' : 'Volver';
  String get startRoutine => isEn ? 'START ROUTINE' : 'INICIAR RUTINA';
  String get deleteRoutineTitle =>
      isEn ? 'Delete routine?' : '¿Eliminar rutina?';
  String get durationLabel => isEn ? 'Duration' : 'Duración';
  String get exercisesLabel => isEn ? 'Exercises' : 'Ejercicios';
  String get routineExercises =>
      isEn ? 'Routine exercises' : 'Ejercicios de la rutina';
  String setsCount(int n) => isEn ? '$n sets' : '$n series';
  String repsCount(int n) => isEn ? '$n reps' : '$n reps';

  // ── Admin dashboard extra ────────────────────────────────────────────
  String get goodMorning => isEn ? 'Good morning' : 'Buenos días';
  String get goodAfternoon => isEn ? 'Good afternoon' : 'Buenas tardes';
  String get goodEvening => isEn ? 'Good evening' : 'Buenas noches';
  String get weeklyActivity => isEn ? 'Weekly activity' : 'Actividad semanal';
  String get last7Days => isEn ? 'Last 7 days' : 'Últimos 7 días';
  String get errorLoadingData => isEn
      ? 'Error loading data. Check your connection.'
      : 'Error al cargar datos. Verifica tu conexión.';
  String get retryButton => isEn ? 'Retry' : 'Reintentar';
  String get usersStatLabel => isEn ? 'USERS' : 'USUARIOS';
  String get sessionsStatLabelUpper => isEn ? 'SESSIONS' : 'SESIONES';
  String get noSessionsThisWeek =>
      isEn ? 'No sessions this week' : 'Sin sesiones esta semana';
  List<String> get weekdayAbbreviations => isEn
      ? ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
      : ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
  String get todayUpper => isEn ? 'TODAY' : 'HOY';
  String get yesterdayUpper => isEn ? 'YESTERDAY' : 'AYER';

  // ── User assignments extra ───────────────────────────────────────────
  String get userAssignmentsTitle =>
      isEn ? 'User assignments' : 'Asignaciones de usuarios';
  String get noAssignedRoutine =>
      isEn ? 'No assigned routine' : 'Sin rutina asignada';
  String get routineAssigned => isEn ? 'Routine assigned' : 'Rutina asignada';
  String get addRoutine => isEn ? 'Add routine' : 'Agregar rutina';
  String get editRoutineMenu => isEn ? 'Edit routine' : 'Editar rutina';
  String get removeRoutine => isEn ? 'Remove routine' : 'Quitar rutina';

  // ── Change password screen ───────────────────────────────────────────
  String get accountSecurity =>
      isEn ? 'Account security' : 'Seguridad de tu cuenta';
  String get changePasswordScreenHint => isEn
      ? 'Change your password regularly to keep your account secure'
      : 'Cambia tu contraseña regularmente para mantener tu cuenta segura';
  String get enterCurrentPassword =>
      isEn ? 'Enter your current password' : 'Ingresa tu contraseña actual';
  String get confirmNewPassword =>
      isEn ? 'Confirm new password' : 'Confirmar nueva contraseña';
  String get repeatNewPassword =>
      isEn ? 'Repeat the new password' : 'Repite la nueva contraseña';
  String get passwordRequirements =>
      isEn ? 'Password requirements:' : 'Requisitos de contraseña:';
  String get passwordRecommendation => isEn
      ? 'We recommend using letters, numbers and symbols'
      : 'Se recomienda usar letras, números y símbolos';
  String get changePasswordButton =>
      isEn ? 'Change Password' : 'Cambiar Contraseña';
  String get forgotPasswordInstructions => isEn
      ? 'If you don\'t remember your current password, you must log out and use the "Recover password" option on the login screen.'
      : 'Si no recuerdas tu contraseña actual, debes cerrar sesión y usar la opción "Recuperar contraseña" en la pantalla de inicio de sesión.';
  String get understood => isEn ? 'Understood' : 'Entendido';
  String get dontRememberPassword => isEn
      ? "Don't remember your current password?"
      : '¿No recuerdas tu contraseña actual?';
  String get newPasswordMin8 => isEn
      ? 'New password must be at least 8 characters'
      : 'La nueva contraseña debe tener al menos 8 caracteres';
  String get newPasswordsDoNotMatch => isEn
      ? 'New passwords do not match'
      : 'Las contraseñas nuevas no coinciden';
  String get newPasswordMustDiffer => isEn
      ? 'New password must be different from current'
      : 'La nueva contraseña debe ser diferente a la actual';
  String get currentPasswordIncorrect => isEn
      ? 'Current password is incorrect'
      : 'La contraseña actual es incorrecta';

  // ── Coming soon workout card ─────────────────────────────────────────
  String get goodJob => isEn ? 'Good job!' : '¡Buen trabajo!';
  String get workoutCompletedBanner =>
      isEn ? 'Workout completed!' : '¡Entrenamiento completado!';
  String get nextRoutineLabelUpper => isEn ? 'NEXT ROUTINE' : 'PRÓXIMA RUTINA';

  // ── Video widgets ────────────────────────────────────────────────────
  String get videoUrlUnavailable =>
      isEn ? 'Video URL unavailable' : 'URL del video no disponible';
  String get videoLoadError =>
      isEn ? 'Error loading video' : 'Error al cargar el video';
  String get loadingVideo => isEn ? 'Loading video...' : 'Cargando video...';

  // ── Profile extra ────────────────────────────────────────────────────
  String get personalRecords =>
      isEn ? 'Personal Records' : 'Récords Personales';
  String get settingsTooltip => isEn ? 'Settings' : 'Ajustes';

  // ── Level display (DB keys → labels) ─────────────────────────────────
  String levelDisplay(String dbKey) {
    switch (dbKey) {
      case 'Principiante':
        return beginner;
      case 'Intermedio':
        return intermediate;
      case 'Avanzado':
        return advanced;
      default:
        return dbKey;
    }
  }

  // ── Today workout extra (batch 2) ──────────────────────────────────────
  String exerciseProgress(int current, int total) =>
      isEn ? 'Exercise $current of $total' : 'Ejercicio $current de $total';
  String get videoUnavailable =>
      isEn ? 'Video unavailable' : 'Video no disponible';
  String get instructionsLabel => isEn ? 'Instructions:' : 'Instrucciones:';
  String get restingTitle => isEn ? 'RESTING' : 'DESCANSANDO';
  String get secondsLabel => isEn ? 'seconds' : 'segundos';
  String get skipRest => isEn ? 'Skip rest' : 'Saltar descanso';
  String get markCompletedSets =>
      isEn ? 'Mark the completed sets:' : 'Marca las series completadas:';
  String setNumber(int n) => isEn ? 'Set $n' : 'Serie $n';
  String get nextExercise => isEn ? 'NEXT EXERCISE' : 'SIGUIENTE EJERCICIO';
  String get finishRoutine => isEn ? 'FINISH ROUTINE' : 'FINALIZAR RUTINA';
  String get restLabel => isEn ? 'Rest' : 'Descanso';

  // ── Service error/success codes ──────────────────────────────────────────
  /// Translates a service-layer error/success code into a localised message.
  /// Services (which have no BuildContext) return short string codes;
  /// the UI passes them through this method before displaying.
  String serviceMessage(String code) {
    switch (code) {
      // ── SecurityService ──
      case 'no_active_session':
        return isEn ? 'No active session' : 'No hay sesión activa';
      case 'wrong_current_password':
        return isEn
            ? 'Current password is incorrect'
            : 'La contraseña actual es incorrecta';
      case 'password_updated':
        return isEn
            ? 'Password updated successfully'
            : 'Contraseña actualizada correctamente';
      case 'password_change_failed':
        return isEn
            ? 'Could not change password'
            : 'No se pudo cambiar la contraseña';
      case 'invalid_email':
        return isEn ? 'Invalid email' : 'Email inválido';
      case 'recovery_email_sent':
        return isEn
            ? 'Recovery email sent. Check your inbox.'
            : 'Email de recuperación enviado. Revisa tu bandeja de entrada.';
      case 'password_reset_success':
        return isEn
            ? 'Password reset successfully'
            : 'Contraseña restablecida exitosamente';
      case 'password_reset_failed':
        return isEn
            ? 'Could not reset password'
            : 'No se pudo restablecer la contraseña';
      case 'wrong_password':
        return isEn ? 'Incorrect password' : 'Contraseña incorrecta';
      case 'account_deleted':
        return isEn
            ? 'Account deleted successfully'
            : 'Cuenta eliminada exitosamente';
      case 'password_min_8':
        return isEn
            ? 'Password must be at least 8 characters'
            : 'La contraseña debe tener al menos 8 caracteres';
      case 'password_needs_uppercase':
        return isEn
            ? 'Password must contain at least one uppercase letter'
            : 'La contraseña debe contener al menos una mayúscula';
      case 'password_needs_lowercase':
        return isEn
            ? 'Password must contain at least one lowercase letter'
            : 'La contraseña debe contener al menos una minúscula';
      case 'password_needs_number':
        return isEn
            ? 'Password must contain at least one number'
            : 'La contraseña debe contener al menos un número';
      case 'password_valid':
        return isEn ? 'Valid password' : 'Contraseña válida';
      case 'password_verified':
        return isEn ? 'Password verified' : 'Contraseña verificada';
      case 'password_update_failed':
        return isEn
            ? 'Could not update password'
            : 'No se pudo actualizar la contraseña';
      case 'error_change_password':
        return isEn
            ? 'Error changing password'
            : 'Error al cambiar la contraseña';
      case 'error_send_email':
        return isEn
            ? 'Error sending recovery email'
            : 'Error al enviar email de recuperación';
      case 'error_reset_password':
        return isEn
            ? 'Error resetting password'
            : 'Error al restablecer contraseña';
      case 'error_delete_account':
        return isEn ? 'Error deleting account' : 'Error al eliminar cuenta';
      case 'error_update_password':
        return isEn
            ? 'Error updating password'
            : 'Error al actualizar contraseña';
      // ── WorkoutProvider ──
      case 'server_connection_failed':
        return isEn
            ? 'Could not connect to server. Showing saved data.'
            : 'No se pudo conectar al servidor. Mostrando datos guardados.';
      default:
        return code;
    }
  }

  // ── Offline workout errors ───────────────────────────────────────────────
  String get offlineCannotCreate => isEn
      ? 'No internet connection. Connect to create a routine.'
      : 'No hay conexión a internet. Conéctate para crear una rutina.';
  String get offlineCannotEdit => isEn
      ? 'No internet connection. Connect to edit the routine.'
      : 'No hay conexión a internet. Conéctate para editar la rutina.';
  String get offlineCannotDelete => isEn
      ? 'No internet connection. Connect to delete the routine.'
      : 'No hay conexión a internet. Conéctate para eliminar la rutina.';

  // ── Workout list extra (batch 2) ──────────────────────────────────────
  String get appTitleUpper => 'CHAMOS FITNESS CENTER';
  String get officialBadge => isEn ? 'OFFICIAL' : 'OFICIAL';
  String get routinePausedTitle => isEn ? 'ROUTINE PAUSED' : 'RUTINA EN PAUSA';
  String exerciseNumber(int n) => isEn ? 'Exercise $n' : 'Ejercicio $n';
  String get continueButton => isEn ? 'Continue' : 'Continuar';

  // ── Workout summary extra (batch 2) ──────────────────────────────────
  List<String> get motivationalPhrases => isEn
      ? [
          'INCREDIBLE WORK!',
          'YOU DID IT!',
          'EXCELLENT!',
          'UNSTOPPABLE!',
          'BRUTAL WORKOUT!',
          'KEEP IT UP CHAMP!',
          'SPECTACULAR!',
          'WHAT A MACHINE!',
        ]
      : [
          '¡INCREÍBLE TRABAJO!',
          '¡LO LOGRASTE!',
          '¡EXCELENTE!',
          '¡ERES IMPARABLE!',
          '¡BRUTAL ENTRENAMIENTO!',
          '¡SIGUE ASÍ CAMPEÓN!',
          '¡ESPECTACULAR!',
          '¡QUÉ MÁQUINA!',
        ];

  // ── Auth extra (batch 2) ──────────────────────────────────────────────
  String get emailPlaceholder =>
      isEn ? 'example@email.com' : 'ejemplo@correo.com';

  // ── User management extra ─────────────────────────────────────────────
  String get adminBadge => 'ADMIN';
  String genericError(String e) => isEn ? 'Error: $e' : 'Error: $e';

  // ── Privacy settings screen ───────────────────────────────────────────
  String get dataUsageSection => isEn ? 'Data Usage' : 'Uso de Datos';
  String get analyticsTitle => isEn ? 'Analytics' : 'Analíticas';
  String get analyticsSubtitle => isEn
      ? 'Help us improve by sharing anonymous usage data'
      : 'Ayúdanos a mejorar compartiendo datos anónimos de uso';
  String get personalizationTitle =>
      isEn ? 'Personalization' : 'Personalización';
  String get personalizationSubtitle => isEn
      ? 'Allow us to personalize your experience'
      : 'Permítenos personalizar tu experiencia';
  String get workoutInsightsTitle =>
      isEn ? 'Workout Insights' : 'Análisis de Entrenamientos';
  String get workoutInsightsSubtitle => isEn
      ? 'Generate statistics from your workouts'
      : 'Generar estadísticas de tus entrenamientos';
  String get yourDataSection => isEn ? 'Your Data' : 'Tus Datos';
  String get whatWeCollectTitle => isEn ? 'What we collect' : 'Qué recopilamos';
  String get whatWeCollectSubtitle => isEn
      ? 'Basic profile info and workout data'
      : 'Información básica del perfil y datos de entrenamientos';
  String get howWeStoreTitle =>
      isEn ? 'How we store it' : 'Cómo lo almacenamos';
  String get howWeStoreSubtitle => isEn
      ? 'Encrypted and secure on our servers'
      : 'Encriptado y seguro en nuestros servidores';
  String get thirdPartiesTitle => isEn ? 'Third parties' : 'Terceros';
  String get thirdPartiesSubtitle => isEn
      ? 'We do not share your data with third parties'
      : 'No compartimos tus datos con terceros';
  String get legalSection => isEn ? 'Legal' : 'Legal';

  // ── Achievements screen ───────────────────────────────────────────────
  String get totalPoints => isEn ? 'Total points' : 'Puntos totales';
  String get unlockedLabel => isEn ? 'unlocked' : 'desbloqueados';

  // ── Assigned workout card ─────────────────────────────────────────────
  String get myAssignedRoutine =>
      isEn ? 'MY ASSIGNED ROUTINE' : 'MI RUTINA ASIGNADA';
  String get startWorkout => isEn ? 'START WORKOUT' : 'INICIAR ENTRENAMIENTO';

  // ── Misc ──────────────────────────────────────────────────────────────
  String get watchVideo => isEn ? 'Watch video' : 'Ver video';
}
