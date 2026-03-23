import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../settings/providers/preferences_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedLevel = 'Principiante';
  double _weight = 70.0;
  double _height = 170.0;
  int _age = 25;
  String _sex = 'male'; // 'male' | 'female' | 'other'
  String _goal = 'Perder peso';
  bool _statsModified = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // Cuando el usuario sale de la página de stats sin modificar, confirmar
    if (_currentPage == 2 && !_statsModified) {
      final l10n = AppL10n.of(context);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text(
            l10n.useDefaultValues,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            l10n.defaultValuesBody,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _statsModified = true; // prevent re-asking
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Text(l10n.confirm,
                  style: const TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
      return;
    }

    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final preferencesProvider =
        Provider.of<PreferencesProvider>(context, listen: false);

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      // Guardar datos de fitness en Supabase (usuarios registrados)
      if (authProvider.isAuthenticated) {
        await authProvider.saveOnboardingData(
          age: _age,
          weightKg: _weight,
          heightCm: _height.round(),
          sex: _sex,
          level: _selectedLevel,
        );
      }

      // Guardar preferencias locales (goal, etc.)
      final onboardingData = {
        'level': _selectedLevel,
        'weight': _weight,
        'height': _height,
        'age': _age,
        'sex': _sex,
        'goal': _goal,
        'completed_at': DateTime.now().toIso8601String(),
      };
      await preferencesProvider.completeOnboarding(onboardingData);

      if (mounted) {
        Navigator.of(context).pop();
        HapticFeedback.mediumImpact();
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.error(
            context, '${AppL10n.of(context).onboardingErrorSaving}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? AppColors.primary
                            : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildLevelPage(),
                  _buildStatsPage(),
                  _buildGoalPage(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Builder(
                builder: (context) {
                  final l10n = AppL10n.of(context);
                  return Row(
                    children: [
                      if (_currentPage > 0)
                        TextButton(
                          onPressed: _previousPage,
                          child: Text(
                            l10n.back,
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      const Spacer(),
                      PrimaryButton(
                        text: _currentPage == 3 ? l10n.start : l10n.next,
                        onPressed: _nextPage,
                        width: 150,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    final l10n = AppL10n.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.fitness_center,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.onboardingWelcome,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.onboardingWelcomeBody,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelPage() {
    final l10n = AppL10n.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.onboardingLevelTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildLevelOption(
                  'Principiante',
                  l10n.beginnerDesc,
                  Icons.trending_up,
                  AppColors.badgePrincipiante,
                  l10n.beginner,
                ),
                const SizedBox(height: 12),
                _buildLevelOption(
                  'Intermedio',
                  l10n.intermediateDesc,
                  Icons.fitness_center,
                  AppColors.badgeIntermedio,
                  l10n.intermediate,
                ),
                const SizedBox(height: 12),
                _buildLevelOption(
                  'Avanzado',
                  l10n.advancedDesc,
                  Icons.emoji_events,
                  AppColors.badgeAvanzado,
                  l10n.advanced,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelOption(String level, String description, IconData icon,
      Color color, String displayLabel) {
    final isSelected = _selectedLevel == level;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLevel = level;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsPage() {
    final l10n = AppL10n.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            l10n.onboardingStatsTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingStatsSubtitle,
            style:
                const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildStatSlider(
            l10n.weightLabel,
            _weight,
            'kg',
            30,
            180,
            (value) => setState(() {
              _weight = value;
              _statsModified = true;
            }),
          ),
          const SizedBox(height: 24),
          _buildStatSlider(
            l10n.heightLabel,
            _height,
            'cm',
            140,
            220,
            (value) => setState(() {
              _height = value;
              _statsModified = true;
            }),
          ),
          const SizedBox(height: 24),
          _buildAgeSlider(),
          const SizedBox(height: 28),
          _buildSexSelector(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAgeSlider() {
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.ageLabel,
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _age.toDouble(),
                min: 12,
                max: 90,
                divisions: 78,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.cardBackground,
                onChanged: (value) => setState(() {
                  _age = value.round();
                  _statsModified = true;
                }),
              ),
            ),
            Container(
              width: 88,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.ageValue(_age),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSexSelector() {
    final l10n = AppL10n.of(context);
    final options = [
      {'value': 'male', 'label': l10n.male, 'icon': Icons.male},
      {'value': 'female', 'label': l10n.female, 'icon': Icons.female},
      {'value': 'other', 'label': l10n.preferNotToSay, 'icon': Icons.person},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.biologicalSex,
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.biologicalSexHint,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          children: options.map((opt) {
            final isSelected = _sex == opt['value'];
            const color = AppColors.primary;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _sex = opt['value'] as String;
                  _statsModified = true;
                }),
                child: Container(
                  margin: EdgeInsets.only(
                    right: opt['value'] != 'other' ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.2)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        opt['icon'] as IconData,
                        color: isSelected ? color : AppColors.textSecondary,
                        size: 26,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opt['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatSlider(
    String label,
    double value,
    String unit,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: ((max - min) * 2).toInt(),
                activeColor: AppColors.primary,
                inactiveColor: AppColors.cardBackground,
                onChanged: onChanged,
              ),
            ),
            Container(
              width: 90,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toStringAsFixed(1)} $unit',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalPage() {
    final l10n = AppL10n.of(context);
    final goals = [
      {
        'key': 'Perder peso',
        'title': l10n.goalLoseWeight,
        'icon': Icons.trending_down,
        'color': Colors.red,
      },
      {
        'key': 'Ganar músculo',
        'title': l10n.goalGainMuscle,
        'icon': Icons.fitness_center,
        'color': Colors.blue,
      },
      {
        'key': 'Mantener peso',
        'title': l10n.goalMaintain,
        'icon': Icons.favorite,
        'color': Colors.green,
      },
      {
        'key': 'Mejorar salud',
        'title': l10n.goalImproveHealth,
        'icon': Icons.directions_run,
        'color': Colors.orange,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.onboardingGoalTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ...goals.map((goal) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildGoalOption(
                        goal['key'] as String,
                        goal['title'] as String,
                        goal['icon'] as IconData,
                        goal['color'] as Color,
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalOption(
      String key, String title, IconData icon, Color color) {
    final isSelected = _goal == key;

    return GestureDetector(
      onTap: () {
        setState(() {
          _goal = key;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 28),
          ],
        ),
      ),
    );
  }
}
