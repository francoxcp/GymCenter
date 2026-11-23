import 'package:flutter/material.dart';
import '../../../shared/web/web_bridge.dart';
import '../../../shared/widgets/install_guide_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/trainer_link_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }



  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppL10n.of(context).myProfile)),
        body: Center(
          child: Text(AppL10n.of(context).noAuthUser,
              style: TextStyle(color: AppColors.textPrimary)),
        ),
      );
    }

    // ...variables eliminadas porque ya no se usan...

    final l10n = AppL10n.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.goBackTooltip,
          onPressed: () => context.go('/home'),
        ),
        title: Text(l10n.myProfile),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -- Cabecera: iniciales, nombre y correo (fijos) --------
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Iniciales (sin foto de perfil)
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.primaryText, width: 3),
                          color: AppColors.background,
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(currentUser.name),
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Nombre y apellido fijos (no se editan)
                      Text(
                        currentUser.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        currentUser.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 20),

                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // -- Menú -------------------------------------------------
                _MenuItem(
                  icon: Icons.emoji_events_outlined,
                  title: l10n.personalRecords,
                  onTap: () => context.push('/personal-records'),
                ),
                const SizedBox(height: 10),
                if (kIsWeb && !WebBridge.isStandalone) ...[
                  _MenuItem(
                    icon: Icons.install_mobile,
                    title: 'Instalar la app',
                    onTap: () => showInstallGuide(context),
                  ),
                  const SizedBox(height: 10),
                ],
                _MenuItem(
                  icon: Icons.history,
                  title: AppL10n.of(context).workoutHistoryMenu,
                  onTap: () => context.push('/workout-history'),
                ),
                const SizedBox(height: 10),
                // Los socios ya tienen Progreso en la barra inferior
                if (context.read<AuthProvider>().isStaff) ...[
                  _MenuItem(
                    icon: Icons.show_chart,
                    title: AppL10n.of(context).myProgress,
                    onTap: () => context.push('/progress'),
                  ),
                  const SizedBox(height: 10),
                ],
                // Vínculo con el entrenador (socio) o código (entrenador)
                const TrainerLinkCard(),
                const SizedBox(height: 10),
                _MenuItem(
                  icon: Icons.straighten,
                  title: AppL10n.of(context).bodyMeasurementsLabel,
                  onTap: () => context.push('/body-measurements'),
                ),
                const SizedBox(height: 10),
                _MenuItem(
                  icon: Icons.lock_outline,
                  title: AppL10n.of(context).changePasswordMenu,
                  onTap: () => context.push('/change-password'),
                ),
                const SizedBox(height: 10),
                _MenuItem(
                  icon: Icons.settings,
                  title: AppL10n.of(context).configurationMenu,
                  onTap: () => context.push('/settings'),
                ),

                const SizedBox(height: 32),

                // -- Cerrar sesión -----------------------------------------
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final auth = context.read<AuthProvider>();
                      await auth.logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: Icon(Icons.logout, color: Colors.red),
                    label: Text(
                      AppL10n.of(context).logOutLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
