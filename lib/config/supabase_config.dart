import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración centralizada de Supabase
class SupabaseConfig {
  // Singleton pattern para evitar múltiples instancias
  SupabaseConfig._();

  // Credenciales inyectadas en tiempo de compilación con --dart-define.
  // Uso: flutter run --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=yyy
  // En desarrollo usar scripts/run_dev.bat para proveer las variables automáticamente.
  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Inicializa la conexión con Supabase.
  /// En producción pasar las credenciales con --dart-define:
  ///   flutter build apk --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=yyy
  static Future<void> initialize() async {
    if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
      throw StateError(
        'Supabase credentials not configured.\n'
        'Run with: flutter run '
        '--dart-define=SUPABASE_URL=<url> '
        '--dart-define=SUPABASE_ANON_KEY=<key>\n'
        'Or use: scripts\\run_dev.bat',
      );
    }

    final uri = Uri.tryParse(_supabaseUrl);
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        uri.scheme != 'https') {
      throw StateError(
        'SUPABASE_URL is not a valid HTTPS URL: "$_supabaseUrl"\n'
        'Expected format: https://your-project.supabase.co',
      );
    }

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
