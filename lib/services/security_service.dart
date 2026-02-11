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
          'message': 'No hay sesión activa',
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
          'message': 'La contraseña actual es incorrecta',
        };
      }

      // Cambiar contraseña
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        debugPrint('Contraseña cambiada exitosamente');
        return {
          'success': true,
          'message': 'Contraseña actualizada correctamente',
        };
      } else {
        return {
          'success': false,
          'message': 'No se pudo cambiar la contraseña',
        };
      }
    } catch (e) {
      debugPrint('Error al cambiar contraseña: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
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
          'message': 'Email inválido',
        };
      }

      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'chamosfitnessapp://reset-password',
      );

      return {
        'success': true,
        'message':
            'Email de recuperación enviado. Revisa tu bandeja de entrada.',
      };
    } catch (e) {
      debugPrint('Error al enviar email de recuperación: $e');
      return {
        'success': false,
        'message': 'Error al enviar email: ${e.toString()}',
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
          'message': 'Contraseña restablecida exitosamente',
        };
      } else {
        return {
          'success': false,
          'message': 'No se pudo restablecer la contraseña',
        };
      }
    } catch (e) {
      debugPrint('Error al restablecer contraseña: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
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
          'message': 'No hay sesión activa',
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
          'message': 'Contraseña incorrecta',
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
        'message': 'Cuenta eliminada exitosamente',
      };
    } catch (e) {
      debugPrint('Error al eliminar cuenta: $e');
      return {
        'success': false,
        'message': 'Error al eliminar cuenta: ${e.toString()}',
      };
    }
  }

  /// Elimina todos los datos asociados al usuario
  Future<void> _deleteUserData(String userId) async {
    try {
      // Eliminar en orden para respetar foreign keys
      await _supabase.from('user_achievements').delete().eq('user_id', userId);
      await _supabase.from('body_measurements').delete().eq('user_id', userId);
      await _supabase.from('workout_sessions').delete().eq('user_id', userId);
      await _supabase.from('user_preferences').delete().eq('user_id', userId);
      await _supabase.from('users').delete().eq('id', userId);

      debugPrint('Datos del usuario eliminados');
    } catch (e) {
      debugPrint('Error al eliminar datos: $e');
      throw Exception('No se pudieron eliminar los datos del usuario');
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
        'message': 'La contraseña debe tener al menos 8 caracteres',
      };
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return {
        'isValid': false,
        'message': 'La contraseña debe contener al menos una mayúscula',
      };
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return {
        'isValid': false,
        'message': 'La contraseña debe contener al menos una minúscula',
      };
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return {
        'isValid': false,
        'message': 'La contraseña debe contener al menos un número',
      };
    }

    return {
      'isValid': true,
      'message': 'Contraseña válida',
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
          'message': 'Contraseña verificada',
        };
      } else {
        return {
          'success': false,
          'message': 'Contraseña incorrecta',
        };
      }
    } catch (e) {
      debugPrint('Error al verificar contraseña: $e');
      return {
        'success': false,
        'message': 'Contraseña incorrecta',
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
          'message': 'Contraseña actualizada exitosamente',
        };
      } else {
        return {
          'success': false,
          'message': 'No se pudo actualizar la contraseña',
        };
      }
    } catch (e) {
      debugPrint('Error al actualizar contraseña: $e');
      return {
        'success': false,
        'message': 'Error al actualizar contraseña: ${e.toString()}',
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
