import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_l10n.dart';
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
      _showError(AppL10n.of(context).fillAllFields);
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

    if (password.length > 15) {
      _showError(AppL10n.of(context).passwordMax15);
      return;
    }

    // Validar complejidad: mayúscula, minúscula y número
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
      final success =
          await authProvider.register(email, password, email.split('@').first);

      if (success && mounted) {
        context.go(authProvider.initialRoute);
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
          _showError(AppL10n.of(context).registerError(e.toString()));
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

              Text(
                AppL10n.of(context).createYourAccount,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppL10n.of(context).registerSubtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // Email Field
              Text(
                AppL10n.of(context).emailLabelUpper,
                style: const TextStyle(
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
                style: const TextStyle(
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
                  if (value.length > 15) return AppL10n.of(context).max15Chars;
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
              Text(
                AppL10n.of(context).confirmPasswordLabelUpper,
                style: const TextStyle(
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
                      text: TextSpan(
                        text: AppL10n.of(context).iAcceptThe,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(
                            text: AppL10n.of(context).termsOfServiceLink,
                            style: const TextStyle(
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: AppL10n.of(context).andThe),
                          TextSpan(
                            text: AppL10n.of(context).privacyPolicyLinkText,
                            style: const TextStyle(
                              color: AppColors.primary,
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
                      style: const TextStyle(
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
                        style: const TextStyle(
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
