import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/biometric_service.dart';
import '../providers/auth_provider.dart';

/// Pantalla de bloqueo biométrico.
/// Se muestra al volver a la app cuando el bloqueo está habilitado.
class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const BiometricLockScreen({super.key, required this.onUnlocked});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _isAuthenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // En móvil se inicia automáticamente. En web, Safari/Chrome exigen que
    // la solicitud de Face ID/huella parta de un toque del usuario.
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    final success = await BiometricService().authenticate(
      reason: 'Desbloquea para acceder a Chamos Fitness',
    );

    if (!mounted) return;

    if (success) {
      widget.onUnlocked();
    } else {
      setState(() {
        _isAuthenticating = false;
        _error = 'Autenticación fallida';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  color: AppColors.primaryText,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  'Chamos Fitness',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'App bloqueada',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton.icon(
                  onPressed: _isAuthenticating ? null : _authenticate,
                  icon: const Icon(Icons.fingerprint, size: 28),
                  label: Text(
                    _isAuthenticating ? 'Verificando...' : 'Desbloquear',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isAuthenticating ? null : _logout,
                  child: Text(
                    'Cerrar sesión e ingresar con contraseña',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Salida de emergencia: si la passkey/biometría no está disponible
  /// (p. ej. se borró del dispositivo) el usuario puede volver a entrar
  /// con su contraseña.
  Future<void> _logout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await BiometricService().disable();
    await auth.logout();
    if (mounted) widget.onUnlocked();
  }
}
