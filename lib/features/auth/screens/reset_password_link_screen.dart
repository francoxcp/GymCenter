import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

/// Destino del enlace "Restablecer contraseña" del correo:
/// `https://<sitio>/reset-password?token_hash=...&type=recovery`
///
/// Verifica el token y, si es válido, el router lleva al usuario a
/// /change-password para que elija su nueva contraseña.
class ResetPasswordLinkScreen extends StatefulWidget {
  final String? tokenHash;

  const ResetPasswordLinkScreen({super.key, required this.tokenHash});

  @override
  State<ResetPasswordLinkScreen> createState() =>
      _ResetPasswordLinkScreenState();
}

class _ResetPasswordLinkScreenState extends State<ResetPasswordLinkScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
  }

  Future<void> _verify() async {
    final token = widget.tokenHash;
    if (token == null || token.isEmpty) {
      setState(() => _failed = true);
      return;
    }
    final ok = await Provider.of<AuthProvider>(context, listen: false)
        .verifyRecoveryToken(token);
    // Si es válido, el router redirige solo a /change-password.
    if (!ok && mounted) setState(() => _failed = true);
  }

  @override
  Widget build(BuildContext context) {
    final isEn = AppL10n.of(context).isEn;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _failed
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link_off,
                          color: AppColors.error, size: 56),
                      const SizedBox(height: 20),
                      Text(
                        isEn
                            ? 'This link is invalid or has expired'
                            : 'Este enlace no es válido o ya expiró',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isEn
                            ? 'Request a new password reset email and open the latest link.'
                            : 'Solicita un nuevo correo de recuperación y abre el enlace más reciente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: () => context.go('/forgot-password'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                        ),
                        child: Text(isEn ? 'Request new link' : 'Pedir nuevo enlace'),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          isEn ? 'Back to login' : 'Volver al inicio de sesión',
                          style:
                              TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                          color: AppColors.primaryText),
                      const SizedBox(height: 20),
                      Text(
                        isEn ? 'Verifying link…' : 'Verificando enlace…',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
