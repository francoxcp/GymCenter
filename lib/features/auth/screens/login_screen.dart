import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_validators.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    // Escuchar cambios de auth para redirigir automáticamente cuando
    // Supabase restaura la sesión persistida (sin que el usuario tenga que
    // volver a escribir sus credenciales)
    _authProvider.addListener(_onAuthChanged);
    // Verificar por si la sesión ya está cargada en este momento
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (_authProvider.isAuthenticated && mounted) {
      context.go(_authProvider.initialRoute);
    }
  }

  void _checkSession() {
    if (_authProvider.isAuthenticated && mounted) {
      context.go(_authProvider.initialRoute);
    }
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      AppSnackbar.error(
        context,
        AppL10n.of(context).fillAllFields,
      );
      return;
    }

    final email = _emailController.text.trim();
    if (!AppValidators.isValidEmail(email)) {
      AppSnackbar.error(
        context,
        AppL10n.of(context).enterValidEmail,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        // Redirigir según el rol del usuario
        final route = _authProvider.initialRoute;
        context.go(route);
      } else if (!success && mounted) {
        AppSnackbar.error(
          context,
          AppL10n.of(context).loginFailed,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      // Mensajes de error específicos
      final l10n = AppL10n.of(context);
      String title = l10n.loginErrorTitle;
      String message = l10n.unexpectedError;

      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('invalid') ||
          errorMessage.contains('credentials') ||
          errorMessage.contains('email') ||
          errorMessage.contains('password')) {
        title = l10n.wrongCredentialsTitle;
        message = l10n.wrongCredentialsMsg;
      } else if (errorMessage.contains('network') ||
          errorMessage.contains('connection')) {
        title = l10n.connectionErrorTitle;
        message = l10n.connectionErrorMsg;
      } else if (errorMessage.contains('user') &&
          errorMessage.contains('not found')) {
        title = l10n.userNotFoundTitle;
        message = l10n.userNotFoundMsg;
      }

      _showLoginError(title, message);
    }
  }

  void _showLoginError(String title, String message) {
    // For "user not found" errors, show a SnackBar with a register action
    if (message.contains('register') || message.contains('registrarte')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title: $message'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: AppL10n.of(context).signMeUp,
            textColor: Colors.white,
            onPressed: () => context.push('/register'),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      AppSnackbar.error(context, '$title: $message');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mientras Supabase verifica la sesión guardada, mostrar splash en lugar de
    // hacer flash del formulario de login y luego redirigir.
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.isInitializing) {
      final l10n = AppL10n.of(context);
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.appTitleUpper,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 28),
              const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

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

              const SizedBox(height: 40),

              // Tabs
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.primary,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          AppL10n.of(context).signInTab,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/register'),
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.surface,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            AppL10n.of(context).signUpTab,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Text(
                AppL10n.of(context).welcomeTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppL10n.of(context).welcomeSubtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // Email Field
              Text(
                AppL10n.of(context).emailLabel,
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
                AppL10n.of(context).passwordFieldLabel,
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

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: Text(
                    AppL10n.of(context).forgotPassword,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Login Button
              PrimaryButton(
                text: _isLoading
                    ? AppL10n.of(context).signingIn
                    : AppL10n.of(context).enterGym,
                onPressed: _isLoading ? () {} : _handleLogin,
              ),

              const SizedBox(height: 40),

              Center(
                child: RichText(
                  text: TextSpan(
                    text: AppL10n.of(context).acceptTermsText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      TextSpan(
                        text: AppL10n.of(context).termsOfServiceLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: ' • '),
                      TextSpan(
                        text: AppL10n.of(context).privacyLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
