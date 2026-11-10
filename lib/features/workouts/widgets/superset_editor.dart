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
            kind: groupKindAt(exercises, index),
            rounds: exercises[index].sets,
            restSeconds: exercises[index].restSeconds,
            innerRestSeconds: exercises[index].groupRestSeconds,
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
  final String? kind;
  final int rounds;
  final int restSeconds;
  final int innerRestSeconds;
  final VoidCallback? onTap;

  const SupersetHeader({
    super.key,
    required this.size,
    this.kind,
    required this.rounds,
    required this.restSeconds,
    this.innerRestSeconds = 0,
    this.onTap,
  });

  bool get _functional => kind == kGroupFunctional;
  String get _kind => groupTitle(kind, size);

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
              _functional
                  ? '${innerRestSeconds}s · ${restSeconds}s'
                  : 'descanso ${restSeconds}s',
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
      label: _functional
          ? '$_kind de $rounds rondas, ${innerRestSeconds}s entre ejercicios y ${restSeconds}s por ronda. Toca para ajustar'
          : '$_kind de $rounds rondas. Toca para ajustar rondas y descanso',
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
          linked ? 'Separar' : 'Agrupar',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Elegir el tipo de un grupo nuevo: superserie o funcional.
Future<String?> showGroupKindPicker(BuildContext context) {
  Widget option(BuildContext ctx, String kind, String title, String sub) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Material(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: () => Navigator.pop(ctx, kind),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                border: Border(
                    left: BorderSide(
                        color: AppColors.primary, width: kSupersetRailWidth)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(sub,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ]),
            ),
          ),
        ),
      );
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('¿Qué tipo de grupo?',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),
            option(ctx, kGroupSuperset, 'Superserie',
                'Seguidos, sin descanso entre ejercicios. Descanso al cerrar la ronda.'),
            option(ctx, kGroupFunctional, 'Funcional',
                'Circuito: descanso corto entre ejercicios, por reps o por tiempo.'),
          ],
        ),
      ),
    ),
  );
}

/// Hoja para ajustar todo el grupo: tipo, rondas y descansos.
Future<({String kind, int rounds, int rest, int innerRest})?> showSupersetSettings(
  BuildContext context, {
  String kind = kGroupSuperset,
  required int rounds,
  required int rest,
  int innerRest = 0,
}) {
  return showModalBottomSheet<({String kind, int rounds, int rest, int innerRest})>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl))),
    builder: (_) => _SupersetSettingsSheet(
        kind: kind, rounds: rounds, rest: rest, innerRest: innerRest),
  );
}

class _SupersetSettingsSheet extends StatefulWidget {
  final String kind;
  final int rounds;
  final int rest;
  final int innerRest;
  const _SupersetSettingsSheet(
      {required this.kind,
      required this.rounds,
      required this.rest,
      required this.innerRest});

  @override
  State<_SupersetSettingsSheet> createState() => _SupersetSettingsSheetState();
}

class _SupersetSettingsSheetState extends State<_SupersetSettingsSheet> {
  late String kind = widget.kind;
  late int rounds = widget.rounds;
  late int rest = widget.rest;
  late int innerRest =
      widget.innerRest > 0 ? widget.innerRest : kFunctionalInnerRest;

  bool get functional => kind == kGroupFunctional;

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

  Widget _kindChip(String value, String label) {
    final sel = kind == value;
    return Expanded(
      child: Semantics(
        button: true,
        selected: sel,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          onTap: () => setState(() {
            if (kind == value) return;
            kind = value;
            // Al cambiar de tipo, descanso por ronda sugerido del tipo
            rest = value == kGroupFunctional
                ? kFunctionalRoundRest
                : kSupersetRoundRest;
          }),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sel ? AppColors.primary : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: sel ? AppColors.onPrimary : AppColors.textSecondary)),
          ),
        ),
      ),
    );
  }

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
            Text('Grupo',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              _kindChip(kGroupSuperset, 'Superserie'),
              const SizedBox(width: AppSpacing.sm),
              _kindChip(kGroupFunctional, 'Funcional'),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Text(
              functional
                  ? 'Circuito: descanso corto entre ejercicios y descanso al terminar cada ronda.'
                  : 'Se hacen todos los ejercicios seguidos y se descansa al terminar cada ronda.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            _stepper('Rondas', '$rounds',
                () => setState(() => rounds = (rounds - 1).clamp(1, 20)),
                () => setState(() => rounds = (rounds + 1).clamp(1, 20))),
            if (functional)
              _stepper('Entre ejercicios', '${innerRest}s',
                  () => setState(() => innerRest = (innerRest - 5).clamp(0, 300)),
                  () => setState(() => innerRest = (innerRest + 5).clamp(0, 300))),
            _stepper('Por ronda', '${rest}s',
                () => setState(() => rest = (rest - 15).clamp(0, 600)),
                () => setState(() => rest = (rest + 15).clamp(0, 600))),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, (
                kind: kind,
                rounds: rounds,
                rest: rest,
                innerRest: functional ? innerRest : 0,
              )),
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
