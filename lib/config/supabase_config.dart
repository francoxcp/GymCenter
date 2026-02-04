import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app_constants.dart';

/// Configuración centralizada de Supabase
class SupabaseConfig {
  // Singleton pattern para evitar múltiples instancias
  SupabaseConfig._();

  /// Inicializa la conexión con Supabase
  /// Debe llamarse antes de runApp() en main.dart
  static Future<void> initialize() async {
    await dotenv.load(fileName: AppConstants.envFileName);

    final supabaseUrl = dotenv.env[AppConstants.supabaseUrlKey];
    final supabaseAnonKey = dotenv.env[AppConstants.supabaseAnonKeyKey];

    if (supabaseUrl == null ||
        supabaseUrl.isEmpty ||
        supabaseAnonKey == null ||
        supabaseAnonKey.isEmpty) {
      throw Exception(
        '${AppConstants.supabaseUrlKey} y ${AppConstants.supabaseAnonKeyKey} '
        'deben estar definidos en ${AppConstants.envFileName}',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
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
