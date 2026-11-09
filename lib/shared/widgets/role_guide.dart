import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../navigation/role_tabs.dart';

class _GuideStep {
  final IconData icon;
  final String title;
  final String body;
  const _GuideStep(this.icon, this.title, this.body);
}

/// Guía de 3 pasos que se muestra una sola vez por rol en este dispositivo.
class RoleGuide {
  RoleGuide._();

  static String _key(NavRole r) => 'role_guide_v1_${r.name}';

  static List<_GuideStep> _steps(NavRole r) => switch (r) {
        NavRole.member => const [
            _GuideStep(Icons.bolt, 'Tu entreno de hoy',
                'Cuando tu entrenador te asigne rutinas, en Hoy verás la del día con un solo botón: empezar.'),
            _GuideStep(Icons.check_circle_outline, 'Registra cada serie',
                'El peso sugerido viene puesto. Si lo hiciste igual, un toque y listo.'),
            _GuideStep(Icons.show_chart, 'Mira cuánto subes',
                'En Progreso ves tus 3 números clave. Tu entrenador también los ve.'),
          ],
        NavRole.trainer => const [
            _GuideStep(Icons.bolt, 'Hoy',
                'Quién entrenó, quién lleva días sin venir y los comentarios por responder.'),
            _GuideStep(Icons.groups, 'Socios',
                'Asigna una rutina a un día, copia un plan de otro socio o deja una nota privada.'),
            _GuideStep(Icons.qr_code_2, 'Invita con un enlace',
                'Botón Invitar: lo mandas por WhatsApp o muestras el QR en el gimnasio.'),
          ],
        NavRole.owner => const [
            _GuideStep(Icons.grid_view, 'Panel',
                'El resumen de la semana: entrenos, socios nuevos y membresías por vencer.'),
            _GuideStep(Icons.groups, 'Socios',
                'Filtra por al día, por vencer o vencidas y registra un pago en dos toques.'),
            _GuideStep(Icons.storefront, 'Gimnasio',
                'Tu nombre, logo, invitaciones y el pago de la plataforma en un solo lugar.'),
          ],
      };

  static Future<void> maybeShow(BuildContext context, NavRole role) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_key(role)) ?? false) return;
    if (!context.mounted) return;
    await prefs.setBool(_key(role), true);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _GuideSheet(steps: _steps(role)),
    );
  }
}

class _GuideSheet extends StatefulWidget {
  final List<_GuideStep> steps;
  const _GuideSheet({required this.steps});

  @override
  State<_GuideSheet> createState() => _GuideSheetState();
}

class _GuideSheetState extends State<_GuideSheet> {
  final _ctrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == widget.steps.length - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${_page + 1}/${widget.steps.length}',
                    style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1)),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Saltar',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
            SizedBox(
              height: 190,
              child: PageView(
                controller: _ctrl,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  for (final s in widget.steps)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(s.icon, size: 40, color: AppColors.primaryText),
                        const SizedBox(height: 16),
                        Text(s.title,
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                height: 1.1)),
                        const SizedBox(height: 8),
                        Text(s.body,
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                height: 1.4)),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                onPressed: () {
                  if (last) {
                    Navigator.pop(context);
                  } else {
                    _ctrl.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut);
                  }
                },
                child: Text(last ? 'Entendido' : 'Siguiente',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
