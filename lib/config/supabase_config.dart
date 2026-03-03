import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración centralizada de Supabase
class SupabaseConfig {
  // Singleton pattern para evitar múltiples instancias
  SupabaseConfig._();

  // Credenciales inyectadas en tiempo de compilación con --dart-define.
  // El defaultValue permite correr con `flutter run` sin flags extra en desarrollo.
  // En producción siempre se sobreescribirán con --dart-define.
  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://njjurkgagfypwjqnsqfc.supabase.co',
  );
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qanVya2dhZ2Z5cHdqcW5zcWZjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMjYwNDUsImV4cCI6MjA4NTgwMjA0NX0.NigaukWUa7zwjUSWMBNq0wlefZlQNupYAaxfF8ZKwcc',
  );

  /// Inicializa la conexión con Supabase.
  /// En producción pasar las credenciales con --dart-define:
  ///   flutter build apk --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=yyy
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// Cliente de Supabase para operaciones de base de datos
  static SupabaseClient get client => Supabase.instance.client;

  /// Cliente de autenticación de Supabase
  static GoTrueClient get auth => Supabase.instance.client.auth;

  /// Verifica si hay una sesión activa
  static bool get hasActiveSession => auth.currentSession != null;

  /// Obtiene el ID del usuario actual (si existe)
  static String? get currentUserId => auth.currentUser?.id;
}
