import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/weight_units.dart';

/// Selector lbs / kg (mancuernas suelen ir en lbs; máquinas y discos en kg).
class WeightUnitToggle extends StatelessWidget {
  final WeightUnit unit;
  final ValueChanged<WeightUnit> onChanged;

  /// Más compacto para ir junto a un campo de texto.
  final bool dense;

  const WeightUnitToggle({
    super.key,
    required this.unit,
    required this.onChanged,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget option(WeightUnit u) {
      final selected = u == unit;
      return Semantics(
        button: true,
        selected: selected,
        label: u == WeightUnit.kg ? 'Kilos' : 'Libras',
        child: InkWell(
          onTap: () => onChanged(u),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: dense ? 52 : 72,
            height: dense ? 40 : 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              u.label,
              style: TextStyle(
                fontSize: dense ? 14 : 15,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.onPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [option(WeightUnit.lbs), option(WeightUnit.kg)],
      ),
    );
  }
}
