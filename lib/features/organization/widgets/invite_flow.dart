import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/organization_service.dart';
import 'invite_link_sheet.dart';

/// Un solo botón "Invitar": pregunta Socio o Entrenador (solo si el dueño de
/// un gimnasio puede invitar entrenadores) y muestra el enlace con QR.
/// El enlace de socios vigente se reutiliza en vez de crear uno nuevo.
Future<void> startInviteFlow(BuildContext context) async {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  final org = auth.organization;
  if (org == null) return;
  final canInviteTrainer = auth.isAdmin && !org.isIndependent;

  String? role = 'user';
  if (canInviteTrainer) {
    role = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿A quién invitas?',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              // Socio es lo normal: botón grande. Entrenador, discreto.
              _RoleOption(
                icon: Icons.person_add_alt_1,
                title: 'Socio',
                body: 'Un enlace para todos tus socios. Verán sus rutinas y su progreso.',
                onTap: () => Navigator.pop(ctx, 'user'),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'trainer'),
                  icon: const Icon(Icons.sports, size: 18),
                  label: const Text('Invitar a un entrenador'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  if (role == null || !context.mounted) return;

  try {
    String? token;
    if (role == 'user') {
      final existing = (await OrganizationService.activeInvitations())
          .where((i) => i.role == 'user' && i.uses < i.maxUses);
      if (existing.isNotEmpty) token = existing.first.token;
    }
    token ??= await OrganizationService.createInvitation(role);
    if (!context.mounted) return;
    final trainer = role == 'trainer';
    await showInviteLinkSheet(
      context,
      token: token,
      title: trainer ? 'Invitar entrenador' : 'Enlace para socios',
      hint: trainer
          ? 'Este enlace da acceso a tus socios. Úsalo solo con entrenadores. Una persona, vence en 7 días.'
          : 'Mándalo por WhatsApp o muestra el QR en recepción.',
      shareText: trainer
          ? 'Te invito a ser entrenador en ${org.name}. Crea tu cuenta aquí:'
          : 'Únete a ${org.name} para ver tus rutinas y tu progreso:',
    );
  } catch (e) {
    if (context.mounted) {
      AppSnackbar.error(context, OrganizationService.friendlyError(e));
    }
  }
}

class _RoleOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  const _RoleOption(
      {required this.icon,
      required this.title,
      required this.body,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryText, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(body,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
