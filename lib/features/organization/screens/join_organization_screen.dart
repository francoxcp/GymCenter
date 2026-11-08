import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/organization_service.dart';

/// Acepta "F5PZEY", "AB12CD34EF" o el enlace completo de invitación.
String normalizeJoinCode(String raw) {
  var t = raw.trim();
  final i = t.lastIndexOf('/');
  if (i >= 0) t = t.substring(i + 1);
  return t.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
}

/// Cuenta sin gimnasio ni entrenador: se une con el código del entrenador
/// (6 letras) o con el código/enlace de invitación (10 letras).
class JoinOrganizationScreen extends StatefulWidget {
  const JoinOrganizationScreen({super.key});

  @override
  State<JoinOrganizationScreen> createState() => _JoinOrganizationScreenState();
}

class _JoinOrganizationScreenState extends State<JoinOrganizationScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = normalizeJoinCode(_ctrl.text);
    if (code.length != 6 && code.length != 10) {
      setState(() => _error = 'Revisa el código: tiene 6 o 10 caracteres.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    try {
      if (code.length == 6) {
        await auth.linkTrainerByCode(code);
      } else {
        await OrganizationService.acceptInvitation(code);
        await auth.refreshUser();
      }
      if (mounted) context.go(auth.initialRoute);
    } catch (e) {
      final msg = e.toString();
      setState(() => _error = msg.contains('invalid_trainer_code')
          ? 'Ese código no existe. Pídeselo de nuevo a tu entrenador.'
          : OrganizationService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthProvider>().currentUser?.name ?? '';
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Hola${name.isNotEmpty ? ', $name' : ''}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 4),
            Text('¿Con quién entrenas?',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.1)),
            const SizedBox(height: 12),
            Text(
              'Escribe el código que te dio tu entrenador o tu gimnasio, '
              'o pega el enlace de invitación.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _ctrl,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                labelText: 'Código o enlace',
                hintText: 'F5PZEY',
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Unirme',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

/// La plataforma suspendió a este cliente.
class SuspendedOrganizationScreen extends StatelessWidget {
  const SuspendedOrganizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isOwner = auth.isAdmin;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.pause_circle_outline, size: 64, color: AppColors.warning),
              const SizedBox(height: 20),
              Text('${auth.organization?.name ?? 'Tu gimnasio'} está en pausa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(
                isOwner
                    ? 'El acceso está suspendido por un pago pendiente. '
                        'Sube tu comprobante y lo reactivamos al validarlo.'
                    : 'El acceso está suspendido temporalmente. '
                        'Consulta con tu gimnasio o entrenador.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 28),
              if (isOwner)
                ElevatedButton(
                  onPressed: () => context.go('/admin/organization'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Subir comprobante'),
                ),
              TextButton(
                onPressed: () => context.read<AuthProvider>().logout(),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
