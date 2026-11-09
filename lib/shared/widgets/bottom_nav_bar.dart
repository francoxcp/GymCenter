import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_l10n.dart';
import '../../features/settings/providers/preferences_provider.dart';
import '../navigation/role_tabs.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavTabSpec> tabs;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    // Escucha cambios de idioma para reconstruir las etiquetas
    Provider.of<PreferencesProvider>(context);
    final l10n = AppL10n.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.background, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < widget.tabs.length; i++)
                _buildNavItem(
                  icon: widget.tabs[i].icon,
                  activeIcon: widget.tabs[i].activeIcon,
                  label: widget.tabs[i].label(l10n),
                  index: i,
                  badge: widget.tabs[i].badge,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    ValueListenable<int>? badge,
  }) {
    final isSelected = widget.currentIndex == index;

    return Expanded(
      child: Semantics(
        label: label,
        button: true,
        selected: isSelected,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Barra indicadora superior animada
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  height: 3,
                  width: isSelected ? 32 : 0,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: isSelected ? 1.15 : 1.0),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  builder: (context, scale, child) {
                    final iconW = Icon(
                      isSelected ? activeIcon : icon,
                      color: isSelected
                          ? AppColors.primaryText
                          : AppColors.textSecondary,
                      size: 24,
                    );
                    return Transform.scale(
                      scale: scale,
                      child: badge == null
                          ? iconW
                          : ValueListenableBuilder<int>(
                              valueListenable: badge,
                              builder: (_, n, __) => Badge(
                                isLabelVisible: n > 0,
                                label: Text(n > 9 ? '9+' : '$n'),
                                backgroundColor: AppColors.primary,
                                textColor: AppColors.onPrimary,
                                child: iconW,
                              ),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: widget.tabs.length > 4
                        ? (isSelected ? 10.5 : 10)
                        : (isSelected ? 11.5 : 11),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primaryText
                        : AppColors.textSecondary,
                  ),
                  child: Text(label,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
