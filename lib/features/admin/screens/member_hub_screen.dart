import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../auth/models/user.dart';
import '../../profile/providers/user_provider.dart';
import '../models/member_status.dart';
import '../widgets/members_status_section.dart';
import '../widgets/membership_card.dart';
import 'assign_plans_screen.dart';

/// Ficha del socio: todo lo que el entrenador necesita en un solo lugar.
/// - Estado (semáforo, última sesión, semana vs plan)
/// - Asignar rutinas por día
/// - Control de entrenamiento (progreso, pesos, volumen)
/// - Restablecer contraseña / activar cuenta
class MemberHubScreen extends StatelessWidget {
  final User member;
  final MemberStatus status;

  const MemberHubScreen({super.key, required this.member, required this.status});

  @override
  Widget build(BuildContext context) {
    final isEn = AppL10n.of(context).isEn;
    final color = MembersStatusSectionState.colorOf(status.light);
    final days = status.daysSinceLast(DateTime.now());
    final lightLabel = switch (status.light) {
      MemberLight.red => isEn ? 'Not coming' : 'Sin venir',
      MemberLight.yellow => isEn ? 'Behind plan' : 'Atrasado',
      MemberLight.green => isEn ? 'On track' : 'Al día',
    };

    Widget action({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) =>
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            onTap: onTap,
            leading: Icon(icon, color: AppColors.primary, size: 28),
            title: Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(member.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Estado
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lightLabel,
                          style: TextStyle(
                              color: color,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        [
                          days == null
                              ? (isEn ? 'Never trained' : 'Nunca ha entrenado')
                              : days == 0
                                  ? (isEn ? 'Trained today' : 'Entrenó hoy')
                                  : (isEn
                                      ? 'Last workout $days days ago'
                                      : 'Último entreno hace $days días'),
                          status.plannedPerWeek > 0
                              ? (isEn
                                  ? 'This week ${status.sessionsThisWeek}/${status.plannedPerWeek}'
                                  : 'Esta semana ${status.sessionsThisWeek}/${status.plannedPerWeek}')
                              : (isEn
                                  ? 'No weekly plan assigned'
                                  : 'Sin plan semanal asignado'),
                        ].join(' · '),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MembershipCard(memberId: member.id),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(member.email,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          action(
            icon: Icons.calendar_month,
            title: isEn ? 'Assign routines' : 'Asignar rutinas',
            subtitle: isEn
                ? 'Choose the routine for each day of the week'
                : 'Elige la rutina de cada día de la semana',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AssignPlansScreen(user: member))),
          ),
          action(
            icon: Icons.insights,
            title: isEn ? 'Training control' : 'Control de entrenamiento',
            subtitle: isEn
                ? 'Weekly compliance, weights and progress per exercise'
                : 'Cumplimiento semanal, pesos y progreso por ejercicio',
            onTap: () => context.push(
                '/admin/user-progress/${member.id}?name=${Uri.encodeQueryComponent(member.name)}'),
          ),
          action(
            icon: Icons.lock_reset,
            title: isEn ? 'Reset password' : 'Restablecer contraseña',
            subtitle: isEn
                ? 'Set a temporary password (also activates the account)'
                : 'Pon una contraseña temporal (también activa la cuenta)',
            onTap: () => showResetPasswordDialog(context, member),
          ),
        ],
      ),
    );
  }
}

/// Diálogo para asignar una contraseña temporal a un socio.
Future<void> showResetPasswordDialog(BuildContext context, User member) async {
  final isEn = AppL10n.of(context).isEn;
  final ctrl = TextEditingController();
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  String? error;
  var saving = false;

  String errorText(String code) => switch (code) {
        'weak_password' => isEn
            ? 'At least 8 characters.'
            : 'Mínimo 8 caracteres.',
        'not_allowed' => isEn
            ? 'You can only do this for your own members.'
            : 'Solo puedes hacerlo con tus socios.',
        _ => isEn ? 'Could not reset it.' : 'No se pudo restablecer.',
      };

  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(isEn ? 'Reset password' : 'Restablecer contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn
                  ? 'New temporary password for ${member.name}. Give it to them in person; they can change it in Settings.'
                  : 'Nueva contraseña temporal para ${member.name}. Dásela en persona; podrá cambiarla en Configuración.',
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: isEn ? 'Temporary password' : 'Contraseña temporal',
                border: const OutlineInputBorder(),
                errorText: error,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialogContext),
            child: Text(AppL10n.of(dialogContext).cancel),
          ),
          ElevatedButton(
            onPressed: saving
                ? null
                : () async {
                    setState(() {
                      saving = true;
                      error = null;
                    });
                    final code = await userProvider.resetMemberPassword(
                        member.id, ctrl.text);
                    if (code == null) {
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      if (context.mounted) {
                        AppSnackbar.success(
                            context,
                            isEn
                                ? 'Password updated and account active'
                                : 'Contraseña actualizada y cuenta activa');
                      }
                    } else {
                      setState(() {
                        saving = false;
                        error = errorText(code);
                      });
                    }
                  },
            child: Text(isEn ? 'Save' : 'Guardar'),
          ),
        ],
      ),
    ),
  );
  ctrl.dispose();
}
