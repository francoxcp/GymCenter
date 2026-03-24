import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/services/security_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/services/secure_screen_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    SecureScreenService.enable();
  }

  @override
  void dispose() {
    SecureScreenService.disable();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(AppL10n.of(context).changePasswordTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header con informaci�n
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_reset,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.accountSecurity,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.changePasswordScreenHint,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Contrase�a actual
              Text(
                l10n.currentPassword,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _currentPasswordController,
                hintText: l10n.enterCurrentPassword,
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureCurrentPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrentPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Nueva contrase�a
              Text(
                l10n.newPassword,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _newPasswordController,
                hintText: l10n.min8Chars,
                prefixIcon: Icons.lock,
                obscureText: _obscureNewPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Confirmar contrase�a
              Text(
                l10n.confirmNewPassword,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _confirmPasswordController,
                hintText: l10n.repeatNewPassword,
                prefixIcon: Icons.lock,
                obscureText: _obscureConfirmPassword,
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

              const SizedBox(height: 12),

              // Requisitos de contrase�a
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.passwordRequirements,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRequirement(l10n.min8Chars),
                    _buildRequirement(l10n.max15Chars),
                    _buildRequirement(l10n.passwordRecommendation),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Bot�n de cambiar contrase�a
              PrimaryButton(
                text: l10n.changePasswordButton,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _handleChangePassword,
              ),

              const SizedBox(height: 16),

              // Mensaje de ayuda
              Center(
                child: TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.cardBackground,
                        title: Text(
                          l10n.forgotPassword,
                          style: const TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          l10n.forgotPasswordInstructions,
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              l10n.understood,
                              style: const TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    l10n.dontRememberPassword,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    // Validar campos vac�os
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError(AppL10n.of(context).fillAllFields);
      return;
    }

    // Validar largo m�nimo
    if (_newPasswordController.text.length < 8) {
      _showError(AppL10n.of(context).newPasswordMin8);
      return;
    }

    // Validar largo m�ximo
    if (_newPasswordController.text.length > 15) {
      _showError(AppL10n.of(context).passwordMax15);
      return;
    }

    // Validar que las contrase�as nuevas coincidan
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError(AppL10n.of(context).newPasswordsDoNotMatch);
      return;
    }

    // Validar que la nueva contrase�a sea diferente
    if (_currentPasswordController.text == _newPasswordController.text) {
      _showError(AppL10n.of(context).newPasswordMustDiffer);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null || currentUser.email.isEmpty) {
        _showError(AppL10n.of(context).userNotFoundTitle);
        setState(() => _isLoading = false);
        return;
      }

      // Primero verificar la contrase�a actual intentando iniciar sesi�n
      final securityService = SecurityService();
      final loginResult = await securityService.verifyCurrentPassword(
        currentUser.email,
        _currentPasswordController.text,
      );

      if (!loginResult['success']) {
        if (!mounted) return;
        _showError(AppL10n.of(context).currentPasswordIncorrect);
        setState(() => _isLoading = false);
        return;
      }

      // Cambiar la contrase�a
      final result = await securityService.updatePassword(
        _newPasswordController.text,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (result['success']) {
          // Mostrar �xito
          AppSnackbar.success(context, AppL10n.of(context).passwordChanged);

          // Volver a la pantalla anterior despu�s de un breve delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              context.pop();
            }
          });
        } else {
          _showError(AppL10n.of(context).serviceMessage(result['message']));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showError(AppL10n.of(context).errorChangingPassword(e.toString()));
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      AppSnackbar.error(context, message);
    }
  }
}
