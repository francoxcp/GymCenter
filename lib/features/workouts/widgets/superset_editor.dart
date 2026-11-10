import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../models/exercise.dart';
import '../models/superset.dart';

/// Ancho del riel que une los ejercicios de una superserie.
const double kSupersetRailWidth = 3;

/// Envuelve la tarjeta de un ejercicio en el editor de rutinas:
/// cabecera de la superserie (si es el primero del grupo), riel lateral
/// y, debajo, el eslabón para unir/separar con el siguiente.
class SupersetEditorItem extends StatelessWidget {
  final List<Exercise> exercises;
  final int index;
  final Widget card;
  final VoidCallback onToggleLink;
  final VoidCallback onEditGroup;

  const SupersetEditorItem({
    super.key,
    required this.exercises,
    required this.index,
    required this.card,
    required this.onToggleLink,
    required this.onEditGroup,
  });

  @override
  Widget build(BuildContext context) {
    final span = supersetSpanAt(exercises, index);
    final isHead = span != null && span.start == index;
    final linked = isLinkedWithNext(exercises, index);
    final canLink = canLinkWithNext(exercises, index);

    Widget body = card;
    if (span != null) {
      body = Container(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
                color: AppColors.primary, width: kSupersetRailWidth),
          ),
        ),
        child: card,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isHead)
          SupersetHeader(
            size: span.size,
            rounds: exercises[index].sets,
            restSeconds: exercises[index].restSeconds,
            onTap: onEditGroup,
          ),
        body,
        if (linked || canLink)
          _LinkToggle(linked: linked, onTap: onToggleLink),
      ],
    );
  }
}

/// "SUPERSERIE · 4 RONDAS" — también se usa en la vista de solo lectura.
class SupersetHeader extends StatelessWidget {
  final int size;
  final int rounds;
  final int restSeconds;
  final VoidCallback? onTap;

  const SupersetHeader({
    super.key,
    required this.size,
    required this.rounds,
    required this.restSeconds,
    this.onTap,
  });

  String get _kind => switch (size) {
        2 => 'SUPERSERIE',
        3 => 'TRISERIE',
        _ => 'CIRCUITO',
      };

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.primary, width: kSupersetRailWidth),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _kind,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$rounds',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              rounds == 1 ? 'RONDA' : 'RONDAS',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              'descanso ${restSeconds}s',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.tune, size: AppSpacing.iconXs,
                color: AppColors.textSecondary),
          ],
        ],
      ),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: '$_kind de $rounds rondas. Toca para ajustar rondas y descanso',
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

class _LinkToggle extends StatelessWidget {
  final bool linked;
  final VoidCallback onTap;
  const _LinkToggle({required this.linked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = linked ? AppColors.primaryText : AppColors.textSecondary;
    return Container(
      // Mantiene el riel continuo entre dos ejercicios unidos
      decoration: linked
          ? BoxDecoration(
              border: Border(
                left: BorderSide(
                    color: AppColors.primary, width: kSupersetRailWidth),
              ),
            )
          : null,
      alignment: Alignment.center,
      child: TextButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(48, 40),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          visualDensity: VisualDensity.compact,
        ),
        icon: Icon(linked ? Icons.link_off : Icons.link,
            size: AppSpacing.iconXs),
        label: Text(
          linked ? 'Separar' : 'Unir en superserie',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Hoja para ajustar rondas y descanso de toda la superserie.
Future<({int rounds, int rest})?> showSupersetSettings(
    BuildContext context, {required int rounds, required int rest}) {
  return showModalBottomSheet<({int rounds, int rest})>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl))),
    builder: (_) => _SupersetSettingsSheet(rounds: rounds, rest: rest),
  );
}

class _SupersetSettingsSheet extends StatefulWidget {
  final int rounds;
  final int rest;
  const _SupersetSettingsSheet({required this.rounds, required this.rest});

  @override
  State<_SupersetSettingsSheet> createState() => _SupersetSettingsSheetState();
}

class _SupersetSettingsSheetState extends State<_SupersetSettingsSheet> {
  late int rounds = widget.rounds;
  late int rest = widget.rest;

  Widget _stepper(String label, String value, VoidCallback onMinus,
          VoidCallback onPlus) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 15))),
          IconButton(
              tooltip: 'Menos $label',
              onPressed: onMinus,
              icon: const Icon(Icons.remove_circle_outline)),
          SizedBox(
            width: 80,
            child: Text(value,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900)),
          ),
          IconButton(
              tooltip: 'Más $label',
              onPressed: onPlus,
              icon: Icon(Icons.add_circle_outline,
                  color: AppColors.primaryText)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg,
            AppSpacing.xl, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Superserie',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Se hacen todos los ejercicios seguidos y se descansa al terminar cada ronda.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            _stepper('Rondas', '$rounds',
                () => setState(() => rounds = (rounds - 1).clamp(1, 20)),
                () => setState(() => rounds = (rounds + 1).clamp(1, 20))),
            _stepper('Descanso', '${rest}s',
                () => setState(() => rest = (rest - 15).clamp(0, 600)),
                () => setState(() => rest = (rest + 15).clamp(0, 600))),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, (rounds: rounds, rest: rest)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              ),
              child: const Text('Listo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
