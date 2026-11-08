import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';

/// Tarjeta del vínculo entrenador ↔ socio.
///
/// - Entrenador/dueño: muestra su código para que los socios se vinculen,
///   con botones para copiarlo y generar uno nuevo.
/// - Socio: muestra su entrenador o permite vincularse con un código.
class TrainerLinkCard extends StatefulWidget {
  const TrainerLinkCard({super.key});

  @override
  State<TrainerLinkCard> createState() => _TrainerLinkCardState();
}

class _TrainerLinkCardState extends State<TrainerLinkCard> {
  String? _trainerName;
  String? _loadedFor;
  bool _busy = false;

  void _loadTrainerName(AuthProvider auth) {
    final tid = auth.currentUser?.trainerId;
    if (tid == _loadedFor) return;
    _loadedFor = tid;
    if (tid == null) {
      _trainerName = null;
      return;
    }
    auth.loadTrainerName().then((n) {
      if (mounted) setState(() => _trainerName = n);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();
    final isEn = AppL10n.of(context).isEn;

    if (auth.isStaff) return _buildStaff(auth, user.trainerCode, isEn);
    _loadTrainerName(auth);
    return _buildMember(auth, user.trainerId != null, isEn);
  }

  Widget _shell({required IconData icon, required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(width: 14),
            Expanded(child: child),
          ],
        ),
      );

  Widget _buildStaff(AuthProvider auth, String? code, bool isEn) {
    return _shell(
      icon: Icons.qr_code_2,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'Your trainer code' : 'Tu código de entrenador',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  code ?? '——',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  isEn
                      ? 'Members enter it to join you.'
                      : 'Tus socios lo escriben para vincularse contigo.',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: isEn ? 'Copy' : 'Copiar',
            icon: Icon(Icons.copy, color: AppColors.primary),
            onPressed: code == null
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: code));
                    AppSnackbar.success(
                        context, isEn ? 'Code copied' : 'Código copiado');
                  },
          ),
          IconButton(
            tooltip: isEn ? 'New code' : 'Código nuevo',
            icon: Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _busy ? null : () => _regenerate(auth, isEn),
          ),
        ],
      ),
    );
  }

  Future<void> _regenerate(AuthProvider auth, bool isEn) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(isEn ? 'New code?' : '¿Generar código nuevo?'),
        content: Text(isEn
            ? 'The current code will stop working. Members already linked stay with you.'
            : 'El código actual dejará de funcionar. Los socios ya vinculados siguen contigo.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppL10n.of(ctx).cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEn ? 'Generate' : 'Generar')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await auth.regenerateTrainerCode();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, AppL10n.of(context).genericError('$e'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildMember(AuthProvider auth, bool linked, bool isEn) {
    return _shell(
      icon: Icons.sports,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'My trainer' : 'Mi entrenador',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  linked
                      ? (_trainerName ?? '…')
                      : (isEn ? 'Not linked yet' : 'Sin vincular'),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _busy ? null : () => _askCode(auth, isEn),
            child: Text(
              linked
                  ? (isEn ? 'Change' : 'Cambiar')
                  : (isEn ? 'Enter code' : 'Usar código'),
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _askCode(AuthProvider auth, bool isEn) async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(isEn ? 'Trainer code' : 'Código de entrenador'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          style: const TextStyle(letterSpacing: 4, fontSize: 20),
          decoration: InputDecoration(
            hintText: 'ABC234',
            helperText: isEn
                ? 'Ask your trainer for their 6-character code.'
                : 'Pídele a tu entrenador su código de 6 caracteres.',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppL10n.of(ctx).cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text(isEn ? 'Link' : 'Vincular')),
        ],
      ),
    );
    ctrl.dispose();
    if (code == null || code.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final name = await auth.linkTrainerByCode(code);
      if (mounted) {
        setState(() => _trainerName = name);
        AppSnackbar.success(
            context, isEn ? 'Linked with $name' : 'Vinculado con $name');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
            context,
            isEn
                ? 'Invalid code. Check it with your trainer.'
                : 'Código no válido. Revísalo con tu entrenador.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
