import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_validators.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validar campos vacíos
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }

    // Validar formato de email
    if (!AppValidators.isValidEmail(email)) {
      _showError('Por favor ingresa un correo electrónico válido');
      return;
    }

    // Validar largo de contraseña
    if (password.length < 8) {
      _showError('La contraseña debe tener al menos 8 caracteres');
      return;
    }

    if (password.length > 15) {
      _showError('La contraseña no puede tener más de 15 caracteres');
      return;
    }

    // Validar complejidad: mayúscula, minúscula y número
    if (!password.contains(RegExp(r'[A-Z]'))) {
      _showError('La contraseña debe tener al menos una letra mayúscula');
      return;
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      _showError('La contraseña debe tener al menos una letra minúscula');
      return;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      _showError('La contraseña debe tener al menos un número');
      return;
    }

    // Validar que coincidan
    if (password != confirmPassword) {
      _showError('Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success =
          await authProvider.register(email, password, email.split('@').first);

      if (success && mounted) {
        context.go(authProvider.initialRoute);
      } else if (mounted) {
        _showError('No se pudo completar el registro. Intenta nuevamente.');
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('already registered') ||
            errorMsg.contains('already exists')) {
          _showError('Ya existe una cuenta con este correo electrónico.');
        } else if (errorMsg.contains('network') ||
            errorMsg.contains('connection')) {
          _showError('Error de conexión. Verifica tu internet.');
        } else {
          _showError('Error al registrar: ${e.toString()}');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    AppSnackbar.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Logo
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        size: 40,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'CHAMOS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const Text(
                      'FITNESS CENTER',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Crea tu cuenta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa tus datos para empezar el entrenamiento.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // Email Field
              const Text(
                'CORREO ELECTRÓNICO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _emailController,
                hintText: 'ejemplo@correo.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  if (!AppValidators.isValidEmail(value.trim())) {
                    return 'Ingresa un correo electrónico válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Password Field
              const Text(
                'CONTRASEÑA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _passwordController,
                hintText: '••••••••',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (value.length < 8) return 'Mínimo 8 caracteres';
                  if (value.length > 15) return 'Máximo 15 caracteres';
                  return null;
                },
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Confirm Password Field
              const Text(
                'CONFIRMAR CONTRASEÑA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _confirmPasswordController,
                hintText: '••••••••',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureConfirmPassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (value != _passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Terms and Conditions
              Row(
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptedTerms = value ?? false;
                      });
                    },
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primary;
                      }
                      return AppColors.surface;
                    }),
                  ),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        text: 'Acepto los ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(
                            text: 'Términos de Servicio',
                            style: TextStyle(
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' y la '),
                          TextSpan(
                            text: 'Política de Privacidad',
                            style: TextStyle(
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' de Chamos Fitness Center.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Register Button
              PrimaryButton(
                text: 'REGISTRARSE',
                isLoading: _isLoading,
                onPressed:
                    _acceptedTerms && !_isLoading ? _handleRegister : null,
              ),

              const SizedBox(height: 24),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿Ya eres miembro? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Inicio Sesión',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
