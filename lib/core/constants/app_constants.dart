/// Constantes utilizadas en toda la aplicación
class AppConstants {
  // Configuración
  static const String appName = 'Chamos Fitness Center';
  static const String appVersion = '1.0.0';

  // Rutas
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String adminRoute = '/admin';
  static const String workoutsRoute = '/workouts';
  static const String profileRoute = '/profile';

  // Roles de usuario
  static const String adminRole = 'admin';
  static const String userRole = 'user';

  // Niveles de entrenamiento
  static const String beginnerLevel = 'Principiante';
  static const String intermediateLevel = 'Intermedio';
  static const String advancedLevel = 'Avanzado';

  // Filtros
  static const String filterAll = 'Todos';
  static const String filterAllMeals = 'TODOS';

  // Categorías de planes de comida
  static const String categoryDeficit = 'DÉFICIT';
  static const String categoryKeto = 'KETO';
  static const String categoryVegan = 'VEGANO';
  static const String categoryMediterranean = 'MEDITERRÁNEA';
  static const String categoryHyper = 'HIPER';

  // Tiempos de espera
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration userCreationDelay = Duration(milliseconds: 500);

  // Colores (referencia para el tema)
  static const int primaryYellowValue = 0xFFFFD700;
  static const int primaryBlackValue = 0xFF000000;

  // Mensajes
  static const String errorLoadingUsers = 'Error al cargar usuarios';
  static const String errorLoadingWorkouts = 'Error al cargar rutinas';
  static const String errorLoadingMealPlans =
      'Error al cargar planes de comida';
  static const String errorAssigning = 'Error al asignar';
  static const String successAssigned = 'Asignado correctamente';

  // Configuración de Supabase
  static const String envFileName = '.env';
  static const String supabaseUrlKey = 'SUPABASE_URL';
  static const String supabaseAnonKeyKey = 'SUPABASE_ANON_KEY';

  // Tablas de Supabase
  static const String usersTable = 'users';
  static const String workoutsTable = 'workouts';
  static const String exercisesTable = 'exercises';
  static const String mealPlansTable = 'meal_plans';
  static const String workoutSessionsTable = 'workout_sessions';

  // Orden de consultas
  static const String createdAtField = 'created_at';
  static const String orderIndexField = 'order_index';

  // Valores por defecto
  static const int defaultRestSeconds = 60;
  static const int defaultCalories = 0;
  static const int defaultActiveDays = 0;
  static const int defaultCompletedWorkouts = 0;
}
