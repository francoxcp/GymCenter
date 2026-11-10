import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';

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
        redirectTo: SupabaseConfig.passwordResetRedirect,
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

      // El dueño no puede borrar su cuenta: el gimnasio quedaría sin dueño.
      // (El servidor también lo impide en delete_user_account.)
      final me = await _supabase
          .from('users')
          .select('role, org_id')
          .eq('id', user.id)
          .maybeSingle();
      if (me != null && me['role'] == 'admin' && me['org_id'] != null) {
        return {
          'success': false,
          'message': 'owner_cannot_delete',
        };
      }

      // Fotos de perfil (Storage no se borra en cascada)
      await _deleteProfilePhotos(user.id);

      // Borra la cuenta y, en cascada, todos sus datos. Sus rutinas y socios
      // (si es entrenador) pasan al dueño del gimnasio en el servidor.
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

  /// Borra las fotos de perfil del usuario (no fallan el borrado de cuenta).
  Future<void> _deleteProfilePhotos(String userId) async {
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

    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>\-_+=\[\]\\\/~`]'))) {
      return {
        'isValid': false,
        'message': 'password_needs_special',
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
