import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para gestionar funciones de seguridad de la cuenta
class SecurityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Cambia la contraseña del usuario actual
  ///
  /// [currentPassword] - Contraseña actual (para verificación)
  /// [newPassword] - Nueva contraseña
  /// Returns true si el cambio fue exitoso
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'no_active_session',
        };
      }

      // Validar nueva contraseña
      final validation = _validatePassword(newPassword);
      if (!validation['isValid']) {
        return {
          'success': false,
          'message': validation['message'],
        };
      }

      // Re-autenticar con contraseña actual
      try {
        await _supabase.auth.signInWithPassword(
          email: user.email!,
          password: currentPassword,
        );
      } catch (e) {
        return {
          'success': false,
          'message': 'wrong_current_password',
        };
      }

      // Cambiar contraseña
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        return {
          'success': true,
          'message': 'password_updated',
        };
      } else {
        return {
          'success': false,
          'message': 'password_change_failed',
        };
      }
    } catch (e) {
      debugPrint('Error changing password: $e');
      return {
        'success': false,
        'message': 'error_change_password',
      };
    }
  }

  /// Envía email de recuperación de contraseña
  ///
  /// [email] - Email del usuario
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      // Validar formato de email
      if (!_isValidEmail(email)) {
        return {
          'success': false,
          'message': 'invalid_email',
        };
      }

      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'chamosfitnessapp://reset-password',
      );

      return {
        'success': true,
        'message': 'recovery_email_sent',
      };
    } catch (e) {
      debugPrint('Error sending recovery email: $e');
      return {
        'success': false,
        'message': 'error_send_email',
      };
    }
  }

  /// Actualiza la contraseña con el token de recuperación
  ///
  /// [newPassword] - Nueva contraseña
  Future<Map<String, dynamic>> resetPasswordWithToken(
      String newPassword) async {
    try {
      // Validar nueva contraseña
      final validation = _validatePassword(newPassword);
      if (!validation['isValid']) {
        return {
          'success': false,
          'message': validation['message'],
        };
      }

      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        return {
          'success': true,
          'message': 'password_reset_success',
        };
      } else {
        return {
          'success': false,
          'message': 'password_reset_failed',
        };
      }
    } catch (e) {
      debugPrint('Error resetting password: $e');
      return {
        'success': false,
        'message': 'error_reset_password',
      };
    }
  }

  /// Elimina permanentemente la cuenta del usuario
  ///
  /// Requiere confirmar con contraseña por seguridad
  Future<Map<String, dynamic>> deleteAccount({
    required String password,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'no_active_session',
        };
      }

      // Re-autenticar con contraseña
      try {
        await _supabase.auth.signInWithPassword(
          email: user.email!,
          password: password,
        );
      } catch (e) {
        return {
          'success': false,
          'message': 'wrong_password',
        };
      }

      // Eliminar datos del usuario en cascada
      await _deleteUserData(user.id);

      // Eliminar cuenta de auth
      // Nota: Supabase no tiene método directo para eliminar usuario
      // Se debe hacer mediante RPC o función de backend
      await _supabase.rpc('delete_user_account', params: {
        'user_id': user.id,
      });

      // Cerrar sesión
      await _supabase.auth.signOut();

      return {
        'success': true,
        'message': 'account_deleted',
      };
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return {
        'success': false,
        'message': 'error_delete_account',
      };
    }
  }

  /// Elimina todos los datos asociados al usuario
  Future<void> _deleteUserData(String userId) async {
    try {
      // Eliminar archivos de storage (fotos de perfil)
      try {
        final files =
            await _supabase.storage.from('profile-photos').list(path: userId);
        if (files.isNotEmpty) {
          final paths = files.map((f) => '$userId/${f.name}').toList();
          await _supabase.storage.from('profile-photos').remove(paths);
        }
      } catch (e) {
        debugPrint('Error deleting profile photos from storage: $e');
      }

      // Eliminar en orden para respetar foreign keys
      await _supabase.from('user_achievements').delete().eq('user_id', userId);
      await _supabase
          .from('user_workout_schedule')
          .delete()
          .eq('user_id', userId);
      await _supabase.from('workout_progress').delete().eq('user_id', userId);
      await _supabase.from('body_measurements').delete().eq('user_id', userId);
      await _supabase.from('workout_sessions').delete().eq('user_id', userId);
      await _supabase.from('user_preferences').delete().eq('user_id', userId);
      await _supabase.from('users').delete().eq('id', userId);

      debugPrint('User data deleted');
    } catch (e) {
      debugPrint('Error deleting user data: $e');
      throw Exception('Could not delete user data');
    }
  }

  /// Valida el formato del email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Valida requisitos de contraseña
  Map<String, dynamic> _validatePassword(String password) {
    if (password.length < 8) {
      return {
        'isValid': false,
        'message': 'password_min_8',
      };
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return {
        'isValid': false,
        'message': 'password_needs_uppercase',
      };
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return {
        'isValid': false,
        'message': 'password_needs_lowercase',
      };
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return {
        'isValid': false,
        'message': 'password_needs_number',
      };
    }

    return {
      'isValid': true,
      'message': 'password_valid',
    };
  }

  /// Verifica la contraseña actual del usuario
  ///
  /// [email] - Email del usuario
  /// [password] - Contraseña a verificar
  Future<Map<String, dynamic>> verifyCurrentPassword(
    String email,
    String password,
  ) async {
    try {
      // Intentar iniciar sesión con las credenciales
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return {
          'success': true,
          'message': 'password_verified',
        };
      } else {
        return {
          'success': false,
          'message': 'wrong_password',
        };
      }
    } catch (e) {
      debugPrint('Error verifying password: $e');
      return {
        'success': false,
        'message': 'wrong_password',
      };
    }
  }

  /// Actualiza la contraseña del usuario autenticado
  ///
  /// [newPassword] - Nueva contraseña
  Future<Map<String, dynamic>> updatePassword(String newPassword) async {
    try {
      // Validar nueva contraseña
      final validation = _validatePassword(newPassword);
      if (!validation['isValid']) {
        return {
          'success': false,
          'message': validation['message'],
        };
      }

      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        return {
          'success': true,
          'message': 'password_updated',
        };
      } else {
        return {
          'success': false,
          'message': 'password_update_failed',
        };
      }
    } catch (e) {
      debugPrint('Error updating password: $e');
      return {
        'success': false,
        'message': 'error_update_password',
      };
    }
  }

  /// Verifica si la sesión actual es válida
  Future<bool> isSessionValid() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return false;

      // Verificar si el token ha expirado
      final expiresAt = session.expiresAt;
      if (expiresAt != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        return expiresAt > now;
      }

      return true;
    } catch (e) {
      debugPrint('Error al verificar sesión: $e');
      return false;
    }
  }

  /// Refresca el token de sesión
  Future<bool> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      return response.session != null;
    } catch (e) {
      debugPrint('Error al refrescar sesión: $e');
      return false;
    }
  }
}
