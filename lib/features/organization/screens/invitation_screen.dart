import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/organization.dart';
import '../services/organization_service.dart';

/// /invitacion/:token — "Te invitaron a <gimnasio>". Funciona con y sin
/// sesión: sin sesión guarda el código y lo aplica al crear la cuenta.
class InvitationScreen extends StatefulWidget {
  final String token;
  const InvitationScreen({super.key, required this.token});

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> {
  InvitationInfo? _info;
  bool _loading = true;
  bool _joining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await OrganizationService.invitationInfo(widget.token);
      if (info?.valid == true) OrganizationService.trackInvitationView(widget.token);
      if (mounted) setState(() => _info = info);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo cargar la invitación.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueWithoutSession(String route) async {
    await OrganizationService.savePendingInvite(widget.token, orgName: _info?.orgName);
    if (mounted) context.go(route);
  }

  Future<void> _join() async {
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      await OrganizationService.acceptInvitation(widget.token);
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      await auth.refreshUser();
      if (mounted) context.go(auth.initialRoute);
    } catch (e) {
      if (mounted) setState(() => _error = OrganizationService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final signedIn = auth.isAuthenticated;
    final info = _info;
    // Con sesión: ¿ya pertenece a ese gimnasio o a otro?
    final myOrg = auth.organization;
    final alreadyHere = signedIn && myOrg != null && info != null && myOrg.name == info.orgName;
    final otherOrg = signedIn && myOrg != null && info != null && !alreadyHere;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _loading
                  ? const CircularProgressIndicator()
                  : info == null || !info.valid
                      ? _invalid()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Logo(url: info.orgLogo, name: info.orgName),
                            const SizedBox(height: 28),
                            Text('TE INVITARON A',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    letterSpacing: 2,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(info.orgName,
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 34,
                                    height: 1.1,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 10),
                            Text(
                              'Entrarás como ${info.roleLabel}. '
                              '${info.role == 'user' ? 'Tu entrenador verá tus rutinas y tu progreso.' : 'Podrás gestionar socios y rutinas.'}',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                  height: 1.4),
                            ),
                            const SizedBox(height: 32),
                            if (_error != null) ...[
                              Text(_error!,
                                  style: TextStyle(color: AppColors.error)),
                              const SizedBox(height: 12),
                            ],
                            if (alreadyHere) ...[
                              Text('Ya eres parte de ${info.orgName}.',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              _primary('Ir a la app', () => context.go(auth.initialRoute)),
                            ] else if (otherOrg) ...[
                              Text(
                                'Tu cuenta ya pertenece a ${myOrg.name}. Cada cuenta '
                                'puede estar en un solo gimnasio: para unirte a '
                                '${info.orgName} usa otra cuenta.',
                                style: TextStyle(color: AppColors.warning, height: 1.4),
                              ),
                              const SizedBox(height: 12),
                              _primary('Cerrar sesión y crear otra cuenta', () async {
                                await OrganizationService.savePendingInvite(widget.token,
                                    orgName: info.orgName);
                                await auth.logout();
                                if (context.mounted) context.go('/register');
                              }),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: () => context.go(auth.initialRoute),
                                style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12))),
                                child: Text('Seguir en ${myOrg.name}'),
                              ),
                            ] else if (signedIn)
                              _primary('Unirme', _joining ? null : _join,
                                  loading: _joining)
                            else ...[
                              _primary('Crear mi cuenta',
                                  () => _continueWithoutSession('/register')),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: () =>
                                    _continueWithoutSession('/login'),
                                style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12))),
                                child: const Text('Ya tengo cuenta'),
                              ),
                            ],
                          ],
                        ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _primary(String text, VoidCallback? onPressed, {bool loading = false}) =>
      ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(text,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      );

  Widget _invalid() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_off, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(_error ?? 'Este enlace ya no es válido',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Puede que haya vencido o ya se haya usado. Pide uno nuevo a quien te invitó.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
          const SizedBox(height: 24),
          TextButton(onPressed: () => context.go('/login'), child: const Text('Ir al inicio')),
        ],
      );
}

class _Logo extends StatelessWidget {
  final String? url;
  final String name;
  const _Logo({required this.url, required this.name});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 72,
            height: 72,
            color: AppColors.primary,
            alignment: Alignment.center,
            child: url != null
                ? Image.network(url!, width: 72, height: 72, fit: BoxFit.cover)
                : Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 34,
                        fontWeight: FontWeight.w900)),
          ),
        ),
      );
}
