import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/biometric_service.dart';

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
    // Iniciar autenticación automáticamente al mostrar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
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
                const Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
                  size: 64,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Chamos Fitness',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
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
                    style: const TextStyle(color: Colors.redAccent),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
