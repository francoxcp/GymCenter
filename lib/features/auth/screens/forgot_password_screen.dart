import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/services/security_service.dart';
import '../../../shared/services/secure_screen_service.dart';
import '../../../shared/navigation/safe_pop.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    SecureScreenService.enable();
  }

  @override
  void dispose() {
    SecureScreenService.disable();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
 tooltip: 'Atrás',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/login'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                AppL10n.of(context).recoverPasswordTitle,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppL10n.of(context).recoverPasswordDesc,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              // El correo gratuito puede no llegar: alternativa por el gimnasio
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.support_agent, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppL10n.of(context).isEn
                            ? "Didn't get the email? Ask your trainer or the front desk: they can set a temporary password for you in the app."
                            : '¿No te llega el correo? Pídele a tu entrenador o en recepción: pueden ponerte una contraseña temporal desde la app.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                AppL10n.of(context).emailFieldLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _emailController,
                hintText: AppL10n.of(context).emailPlaceholder,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              Text(
                AppL10n.of(context).checkSpamHint,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                text: AppL10n.of(context).sendRecoveryLink,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _handlePasswordReset,
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppL10n.of(context).rememberedPassword,
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
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePasswordReset() async {
    if (_emailController.text.trim().isEmpty) {
      AppSnackbar.error(context, AppL10n.of(context).enterEmail);
      return;
    }

    setState(() => _isLoading = true);

    final securityService = SecurityService();
    final result = await securityService.sendPasswordResetEmail(
      _emailController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      final l10n = AppL10n.of(context);
      if (result['success']) {
        AppSnackbar.success(context, l10n.serviceMessage(result['message']));
      } else {
        AppSnackbar.error(context, l10n.serviceMessage(result['message']));
      }

      if (result['success']) {
        // Esperar un momento y volver al login
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/login');
          }
        });
      }
    }
  }
}
