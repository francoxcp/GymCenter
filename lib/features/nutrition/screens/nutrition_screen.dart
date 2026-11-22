import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/supabase_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../progress/models/body_measurement.dart';
import '../../progress/providers/body_measurement_provider.dart';
import '../data/foods.dart';
import '../services/meal_choice_store.dart';
import '../services/meal_scaler.dart';
import '../services/nutrition_calculator.dart';
import '../services/nutrition_prefs.dart';
import 'nutrition_setup_screen.dart';

const kNutritionDisclaimer =
    'Guía orientativa; no reemplaza a un nutricionista. Si tienes una '
    'condición médica, consulta antes de cambiar tu alimentación.';

/// Perfil para calcular el plan, o null si faltan datos.
NutritionProfile? nutritionProfileFor(User u,
    {double? latestWeight, int trainingDays = 3}) {
  if (needsNutritionSetup(u, latestWeight: latestWeight)) return null;
  return NutritionProfile(
    weightKg: latestWeight ?? u.weightKg!,
    heightCm: u.heightCm!,
    age: u.age!,
    sex: u.sex!,
    goal: goalFromLabel(u.goal),
    activity: ActivityLevel.fromDb(u.activityLevel)!,
    trainingDays: trainingDays,
    mealsPerDay: u.mealsPerDay!,
    avoid: u.foodAvoid.toSet(),
  );
}

/// Días distintos con rutina en el plan semanal; sin datos o sin red, 3.
Future<int> loadTrainingDays(String userId) async {
  try {
    final rows = await SupabaseConfig.client
        .from('user_workout_schedule')
        .select('day_of_week')
        .eq('user_id', userId);
    final days = {for (final r in rows as List) r['day_of_week']};
    return days.isEmpty ? 3 : days.length;
  } catch (_) {
    return 3;
  }
}

/// /comida — carga los datos del socio y muestra su plan.
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  int _trainingDays = 3;
  Map<MealSlot, String> _choices = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final measures = context.read<BodyMeasurementProvider>();
    var user = auth.currentUser;
    if (user == null) return;
    // Sin conexión, el cuestionario puede estar solo en el dispositivo
    if (needsNutritionSetup(user,
        latestWeight: measures.latestOf(MeasureField.weight))) {
      final local = await NutritionPrefs.load(user.id);
      if (local != null) {
        user = User.fromJson({...user.toJson(), ...local});
        auth.updateUser(user);
      }
    }
    if (measures.measurements.isEmpty) await measures.loadMeasurements();
    final days = await loadTrainingDays(user.id);
    final choices = await MealChoiceStore.today(user.id);
    if (!mounted) return;
    setState(() {
      _trainingDays = days;
      _choices = choices;
      _loading = false;
    });
  }

  Future<void> _adjust() async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => const NutritionSetupScreen(editing: true)));
    if (saved == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final weight =
        context.watch<BodyMeasurementProvider>().latestOf(MeasureField.weight);
    if (user == null || _loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return NutritionPlanView(
      profile: nutritionProfileFor(user,
          latestWeight: weight, trainingDays: _trainingDays),
      choices: _choices,
      now: DateTime.now(),
      onAdjust: _adjust,
      onChoose: (slot, id) {
        MealChoiceStore.choose(user.id, slot, id);
        _choices = {..._choices}..[slot] = id ?? '';
        if (id == null) _choices.remove(slot);
      },
    );
  }
}

/// El plan del día. Sin red ni providers: se prueba sola.
class NutritionPlanView extends StatefulWidget {
  const NutritionPlanView({
    super.key,
    required this.profile,
    required this.choices,
    required this.now,
    required this.onChoose,
    required this.onAdjust,
  });

  final NutritionProfile? profile;
  final Map<MealSlot, String> choices;
  final DateTime now;
  final void Function(MealSlot slot, String? optionId) onChoose;
  final VoidCallback onAdjust;

  @override
  State<NutritionPlanView> createState() => _NutritionPlanViewState();
}

class _NutritionPlanViewState extends State<NutritionPlanView> {
  MealSlot? _slot;
  String? _open;
  late Map<MealSlot, String> _choices = {...widget.choices};

  @override
  void didUpdateWidget(NutritionPlanView old) {
    super.didUpdateWidget(old);
    if (old.choices != widget.choices) _choices = {...widget.choices};
  }

  void _choose(MealSlot slot, String id) {
    final unchoose = _choices[slot] == id;
    setState(() => unchoose ? _choices.remove(slot) : _choices[slot] = id);
    widget.onChoose(slot, unchoose ? null : id);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: p == null ? _empty() : _plan(p)),
    );
  }

  Widget _empty() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tu plan de comida',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
                'Tres preguntas y te mostramos qué comer, con porciones a tu medida y comida de aquí.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 16, height: 1.4)),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800),
                ),
                onPressed: widget.onAdjust,
                child: const Text('Armar mi plan'),
              ),
            ),
          ],
        ),
      );

  Widget _plan(NutritionProfile p) {
    final t = computeTargets(p);
    final slots = [for (final m in t.meals) m.slot];
    final slot =
        slots.contains(_slot) ? _slot! : defaultSlot(widget.now, slots);
    final target = t.meals.firstWhere((m) => m.slot == slot);
    final options = [
      for (final o in optionsFor(slot, p.avoid)) scaleOption(o, target),
    ];
    final goal = p.isMinor && p.goal == NutritionGoal.cut
        ? NutritionGoal.maintain
        : p.goal;

    // Suma de lo elegido hoy
    var kcal = 0, protein = 0, price = 0, chosen = 0;
    for (final m in t.meals) {
      final id = _choices[m.slot];
      if (id == null) continue;
      final o = kMealCatalog.where((o) => o.id == id).firstOrNull;
      if (o == null) continue;
      final s = scaleOption(o, m);
      kcal += s.kcal;
      protein += s.proteinG;
      price += s.priceCrc;
      chosen++;
    }

    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                  child: Text('COMIDA · ${_goalLabel(goal)}',
                      style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6)),
                ),
                TextButton(
                    onPressed: widget.onAdjust, child: const Text('Ajustar')),
              ]),
              const SizedBox(height: 4),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: _Big(_thousands(t.kcal), 'kcal al día')),
                const SizedBox(width: 24),
                Expanded(child: _Big('${t.proteinG} g', 'proteína')),
              ]),
              if (p.isMinor) ...[
                const SizedBox(height: 16),
                const _Note(kMinorNotice),
              ],
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final s in slots) ...[
                    ChoiceChip(
                      label: Text(s.label),
                      selected: s == slot,
                      showCheckmark: false,
                      avatar: _choices.containsKey(s)
                          ? Icon(Icons.check,
                              size: 16, color: AppColors.primaryText)
                          : null,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                          color: s == slot
                              ? AppColors.onPrimary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700),
                      onSelected: (_) => setState(() {
                        _slot = s;
                        _open = null;
                      }),
                    ),
                    const SizedBox(width: 8),
                  ],
                ]),
              ),
              const SizedBox(height: 16),
              Text(
                  '${_thousands(target.kcal)} kcal · ${target.proteinG} g proteína · elige una',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              if (options.length < 3)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Pocas opciones con tus restricciones',
                      style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700)),
                ),
              for (final s in options)
                _OptionTile(
                  option: s,
                  open: _open == s.option.id,
                  chosen: _choices[slot] == s.option.id,
                  onTap: () => setState(
                      () => _open = _open == s.option.id ? null : s.option.id),
                  onChoose: () => _choose(slot, s.option.id),
                ),
              const SizedBox(height: 16),
              Text('$kNutritionDisclaimer Precios aprox. $kPricesAsOf.',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4)),
            ],
          ),
        ),
      ),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.cardBackground)),
        ),
        child: Text(
          'Tu día: $chosen de ${slots.length} comidas elegidas'
          '${chosen > 0 ? ' · ${_thousands(kcal)} kcal · $protein g proteína · ~₡${_thousands(price)}' : ''}',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700),
        ),
      ),
    ]);
  }
}

String _goalLabel(NutritionGoal g) => switch (g) {
      NutritionGoal.maintain => 'MANTENER PESO',
      NutritionGoal.gain => 'SUBIR MASA',
      NutritionGoal.cut => 'BAJAR GRASA',
    };

/// 2500 → "2 500"; 900 → "900".
String _thousands(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

class _Big extends StatelessWidget {
  const _Big(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1)),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      );
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
        ),
        child: Text(text,
            style: TextStyle(color: AppColors.textPrimary, height: 1.4)),
      );
}

/// Opción de comida: precio grande a la derecha (estilo pizarra de soda);
/// al tocarla se ven los ingredientes y el botón Elegir.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.open,
    required this.chosen,
    required this.onTap,
    required this.onChoose,
  });

  final ScaledOption option;
  final bool open;
  final bool chosen;
  final VoidCallback onTap;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: chosen ? AppColors.primary : Colors.transparent, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.option.name,
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                          '${option.proteinG} g proteína · ${option.kcal} kcal'
                          '${option.option.quick ? ' · rápida' : ''}',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text('~₡${_thousands(option.priceCrc)}',
                    style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
              ]),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: open
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final it in option.items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('· ${it.label}',
                                    style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15)),
                              ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (c, a) =>
                                    ScaleTransition(scale: a, child: c),
                                child: chosen
                                    ? OutlinedButton.icon(
                                        key: const ValueKey('chosen'),
                                        onPressed: onChoose,
                                        icon: const Icon(Icons.check),
                                        label: const Text('Elegido'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              AppColors.primaryText,
                                          side: BorderSide(
                                              color: AppColors.primary),
                                        ),
                                      )
                                    : FilledButton(
                                        key: const ValueKey('choose'),
                                        onPressed: onChoose,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.onPrimary,
                                        ),
                                        child: const Text('Elegir'),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
