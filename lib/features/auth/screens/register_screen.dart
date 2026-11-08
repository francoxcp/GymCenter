import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../organization/services/organization_service.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_validators.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../providers/auth_provider.dart';
import '../../../shared/services/secure_screen_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _trainerCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  /// Viene de un enlace de invitación: se muestra a qué gimnasio se une y
  /// no se pide código de entrenador.
  String? _inviteOrg;

  @override
  void initState() {
    super.initState();
    SecureScreenService.enable();
    OrganizationService.pendingInviteOrgName().then((name) {
      if (mounted && name != null) setState(() => _inviteOrg = name);
    });
  }

  @override
  void dispose() {
    SecureScreenService.disable();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _trainerCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validar campos vacíos
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError(AppL10n.of(context).fillAllFields);
      return;
    }

    // Nombre: el entrenador lo necesita para identificar al socio
    if (name.length < 2 || name.length > 60) {
      _showError(AppL10n.of(context).isEn
          ? 'Enter your name (2 to 60 characters).'
          : 'Escribe tu nombre (de 2 a 60 caracteres).');
      return;
    }

    // Validar formato de email
    if (!AppValidators.isValidEmail(email)) {
      _showError(AppL10n.of(context).enterValidEmail);
      return;
    }

    // Validar largo de contraseña
    if (password.length < 8) {
      _showError(AppL10n.of(context).passwordMin8);
      return;
    }

    // Validar complejidad: mayúscula, minúscula, número y carácter especial
    if (!password.contains(RegExp(r'[A-Z]'))) {
      _showError(AppL10n.of(context).passwordNeedsUppercase);
      return;
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      _showError(AppL10n.of(context).passwordNeedsLowercase);
      return;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      _showError(AppL10n.of(context).passwordNeedsNumber);
      return;
    }
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_+=\[\]\\/~`]'))) {
      _showError(AppL10n.of(context).passwordNeedsSpecial);
      return;
    }

    // Validar que coincidan
    if (password != confirmPassword) {
      _showError(AppL10n.of(context).newPasswordsDoNotMatch);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        email,
        password,
        name,
        trainerCode: _trainerCodeController.text,
      );

      if (success && mounted) {
        context.go(authProvider.initialRoute);
      } else if (authProvider.pendingEmailConfirmation && mounted) {
        final l10n = AppL10n.of(context);
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.mark_email_unread_outlined,
                    color: AppColors.primaryText),
                const SizedBox(width: 12),
                Text(l10n.confirmEmailTitle),
              ],
            ),
            content: Text(l10n.confirmEmailBody(email)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.goToLogin),
              ),
            ],
          ),
        );
        if (mounted) context.go('/login');
      } else if (mounted) {
        _showError(AppL10n.of(context).registerFailed);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('already registered') ||
            errorMsg.contains('already exists')) {
          _showError(AppL10n.of(context).emailAlreadyExists);
        } else if (errorMsg.contains('network') ||
            errorMsg.contains('connection')) {
          _showError(AppL10n.of(context).connectionError);
        } else {
          _showError(AppL10n.of(context).registerFailed);
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
                      child: Icon(
                        Icons.fitness_center,
                        size: 40,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'GYMCENTER',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    Text(
                      'RUTINAS · GESTIÓN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text(
                AppL10n.of(context).createYourAccount,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppL10n.of(context).registerSubtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // Nombre completo
              Text(
                AppL10n.of(context).isEn ? 'FULL NAME' : 'NOMBRE COMPLETO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _nameController,
                hintText: AppL10n.of(context).isEn ? 'Your name' : 'Tu nombre',
                prefixIcon: Icons.person_outline,
              ),

              const SizedBox(height: 20),

              // Email Field
              Text(
                AppL10n.of(context).emailLabelUpper,
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
                hintText: AppL10n.of(context).emailPlaceholder,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  if (!AppValidators.isValidEmail(value.trim())) {
                    return AppL10n.of(context).enterValidEmail;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Password Field
              Text(
                AppL10n.of(context).passwordLabelUpper,
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
                  if (value.length < 8) return AppL10n.of(context).min8Chars;
                  if (value.length > 72) {
                    return AppL10n.of(context).passwordMax72;
                  }
                  return null;
                },
                suffixIcon: IconButton(
 tooltip: 'Ocultar contraseña',
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
              Text(
                AppL10n.of(context).confirmPasswordLabelUpper,
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
                    return AppL10n.of(context).newPasswordsDoNotMatch;
                  }
                  return null;
                },
                suffixIcon: IconButton(
 tooltip: 'Ocultar contraseña',
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

              const SizedBox(height: 16),

              // Código del entrenador (opcional): vincula al socio al registrarse.
              // Con invitación no hace falta.
              if (_inviteOrg == null)
                CustomTextField(
                  controller: _trainerCodeController,
                  hintText: AppL10n.of(context).isEn
                      ? 'Trainer code (optional)'
                      : 'Código de tu entrenador (opcional)',
                  prefixIcon: Icons.sports,
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(left: BorderSide(color: AppColors.primaryText, width: 4)),
                  ),
                  child: Text('Al crear tu cuenta te unirás a $_inviteOrg.',
                      style: TextStyle(
                          color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
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
                      text: TextSpan(
                        text: AppL10n.of(context).iAcceptThe,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: AppL10n.of(context).termsOfServiceLink,
                            style: TextStyle(
                              color: AppColors.primaryText,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: AppL10n.of(context).andThe),
                          TextSpan(
                            text: AppL10n.of(context).privacyPolicyLinkText,
                            style: TextStyle(
                              color: AppColors.primaryText,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: AppL10n.of(context).ofChamosFitness),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Register Button
              PrimaryButton(
                text: AppL10n.of(context).signUpButton,
                isLoading: _isLoading,
                onPressed:
                    _acceptedTerms && !_isLoading ? _handleRegister : null,
              ),

              const SizedBox(height: 24),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppL10n.of(context).alreadyMember,
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
                      child: Text(
                        AppL10n.of(context).signInLink,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryText,
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
