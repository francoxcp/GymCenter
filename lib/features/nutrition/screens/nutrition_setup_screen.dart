import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../progress/models/body_measurement.dart';
import '../../progress/providers/body_measurement_provider.dart';
import '../data/foods.dart';
import '../services/nutrition_calculator.dart';

/// ¿Faltan datos para calcular el plan?
bool needsNutritionSetup(User u, {double? latestWeight}) =>
    u.age == null ||
    u.heightCm == null ||
    u.sex == null ||
    (latestWeight ?? u.weightKg) == null ||
    ActivityLevel.fromDb(u.activityLevel) == null ||
    u.mealsPerDay == null;

const kMinorNotice =
    'A tu edad, consulta con un nutricionista y tu encargado antes de '
    'cambiar tu alimentación.';

/// Valores con los que arranca el cuestionario.
class NutritionSetupInitial {
  final double weightKg;
  final int heightCm;
  final int age;
  final String? sex;
  final NutritionGoal goal;
  final ActivityLevel? activity;
  final Set<String> avoid;
  final int mealsPerDay;

  const NutritionSetupInitial({
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.sex,
    required this.goal,
    required this.activity,
    required this.avoid,
    required this.mealsPerDay,
  });

  factory NutritionSetupInitial.fromUser(User u, {double? latestWeight}) =>
      NutritionSetupInitial(
        weightKg: latestWeight ?? u.weightKg ?? 70,
        heightCm: u.heightCm ?? 165,
        age: u.age ?? 25,
        sex: u.sex,
        goal: goalFromLabel(u.goal),
        activity: ActivityLevel.fromDb(u.activityLevel),
        avoid: u.foodAvoid.toSet(),
        mealsPerDay: u.mealsPerDay ?? 4,
      );
}

/// Lo que el socio respondió.
class NutritionSetupResult {
  final double weightKg;
  final int heightCm;
  final int age;
  final String sex;
  final NutritionGoal goal;
  final ActivityLevel activity;
  final Set<String> avoid;
  final int mealsPerDay;
  final bool weightChanged;

  const NutritionSetupResult({
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.sex,
    required this.goal,
    required this.activity,
    required this.avoid,
    required this.mealsPerDay,
    required this.weightChanged,
  });
}

/// Cuestionario conectado a los datos del socio. Devuelve `true` al guardar.
class NutritionSetupScreen extends StatelessWidget {
  const NutritionSetupScreen({super.key, this.editing = false});

  final bool editing;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final measures = context.read<BodyMeasurementProvider>();
    final user = auth.currentUser!;
    final latest = measures.latestOf(MeasureField.weight);
    return NutritionSetupForm(
      initial: NutritionSetupInitial.fromUser(user, latestWeight: latest),
      onDone: (r) async {
        await auth.saveNutritionProfile(
          weightKg: r.weightKg,
          heightCm: r.heightCm,
          age: r.age,
          sex: r.sex,
          goal: r.goal,
          activity: r.activity,
          avoid: r.avoid,
          mealsPerDay: r.mealsPerDay,
        );
        if (r.weightChanged) {
          await measures.saveMeasurement(BodyMeasurement(
              id: '', userId: user.id, date: DateTime.now(), weight: r.weightKg));
        }
        if (context.mounted) Navigator.of(context).pop(true);
      },
    );
  }
}

/// Cuestionario de 3 pasos, sin dependencias de red (se prueba solo).
class NutritionSetupForm extends StatefulWidget {
  const NutritionSetupForm(
      {super.key, required this.initial, required this.onDone});

  final NutritionSetupInitial initial;
  final Future<void> Function(NutritionSetupResult result) onDone;

  @override
  State<NutritionSetupForm> createState() => _NutritionSetupFormState();
}

class _NutritionSetupFormState extends State<NutritionSetupForm> {
  int _step = 0;
  bool _saving = false;
  late double _weight = widget.initial.weightKg;
  late int _height = widget.initial.heightCm;
  late int _age = widget.initial.age;
  late String? _sex = widget.initial.sex;
  late NutritionGoal _goal = widget.initial.goal;
  late ActivityLevel? _activity = widget.initial.activity;
  late final Set<String> _avoid = {...widget.initial.avoid};
  late int _meals = widget.initial.mealsPerDay;

  bool get _minor => _age < 18;

  bool get _canContinue => switch (_step) {
        0 => _sex != null,
        1 => _activity != null,
        _ => !_saving,
      };

  Future<void> _next() async {
    if (!_canContinue) return;
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    setState(() => _saving = true);
    await widget.onDone(NutritionSetupResult(
      weightKg: _weight,
      heightCm: _height,
      age: _age,
      sex: _sex!,
      goal: _minor && _goal == NutritionGoal.cut ? NutritionGoal.maintain : _goal,
      activity: _activity!,
      avoid: {..._avoid},
      mealsPerDay: _meals,
      weightChanged: _weight != widget.initial.weightKg,
    ));
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: _step == 0
            ? null
            : IconButton(
                tooltip: 'Atrás',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step--),
              ),
        title: Text('Paso ${_step + 1} de 3',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      ),
      body: SafeArea(
        child: Column(children: [
          LinearProgressIndicator(
            value: (_step + 1) / 3,
            minHeight: 3,
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: switch (_step) {
                  0 => _stepBody(),
                  1 => _stepActivity(),
                  _ => _stepFood(),
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800),
                ),
                onPressed: _canContinue ? _next : null,
                child: Text(_step < 2 ? 'Siguiente' : 'Listo'),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Paso 1 ──
  List<Widget> _stepBody() => [
        const _Title('Confirma tus datos'),
        const _Why('Con esto calculamos cuánta energía gasta tu cuerpo.'),
        const SizedBox(height: 16),
        _Stepper(
          label: 'Peso',
          value: '${_fmt(_weight)} kg',
          what: 'peso',
          onMinus: () => setState(() => _weight = (_weight - 0.5).clamp(30, 250)),
          onPlus: () => setState(() => _weight = (_weight + 0.5).clamp(30, 250)),
        ),
        _Stepper(
          label: 'Estatura',
          value: '$_height cm',
          what: 'estatura',
          onMinus: () => setState(() => _height = (_height - 1).clamp(120, 230)),
          onPlus: () => setState(() => _height = (_height + 1).clamp(120, 230)),
        ),
        _Stepper(
          label: 'Edad',
          value: '$_age años',
          what: 'edad',
          onMinus: () => setState(() => _age = (_age - 1).clamp(12, 99)),
          onPlus: () => setState(() => _age = (_age + 1).clamp(12, 99)),
        ),
        const SizedBox(height: 8),
        _Label('Sexo'),
        _Segmented<String>(
          values: const ['male', 'female', 'other'],
          labels: const ['Hombre', 'Mujer', 'Otro'],
          selected: _sex,
          onSelect: (v) => setState(() => _sex = v),
        ),
        const SizedBox(height: 24),
        _Label('Objetivo'),
        const _Why('Define si comes un poco más, igual o un poco menos.'),
        const SizedBox(height: 8),
        _Choice(
          title: 'Mantener peso',
          selected: _goal == NutritionGoal.maintain ||
              (_minor && _goal == NutritionGoal.cut),
          onTap: () => setState(() => _goal = NutritionGoal.maintain),
        ),
        _Choice(
          title: 'Subir masa muscular',
          selected: _goal == NutritionGoal.gain,
          onTap: () => setState(() => _goal = NutritionGoal.gain),
        ),
        if (!_minor)
          _Choice(
            title: 'Bajar grasa',
            subtitle: 'Manteniendo el músculo',
            selected: _goal == NutritionGoal.cut,
            onTap: () => setState(() => _goal = NutritionGoal.cut),
          ),
        if (_minor) ...[
          const SizedBox(height: 8),
          const _Notice(kMinorNotice),
        ],
      ];

  // ── Paso 2 ──
  List<Widget> _stepActivity() => [
        const _Title('¿Qué tan activo eres fuera del gym?'),
        const _Why('Un trabajo físico gasta mucho más que uno de oficina.'),
        const SizedBox(height: 16),
        for (final (a, t, s) in const [
          (ActivityLevel.sedentary, 'Trabajo sentado', 'Oficina, estudio, manejar'),
          (ActivityLevel.standing, 'De pie o camino mucho', 'Comercio, docencia, mensajería'),
          (ActivityLevel.physical, 'Trabajo físico', 'Construcción, campo, cargar peso'),
        ])
          _Choice(
            title: t,
            subtitle: s,
            selected: _activity == a,
            onTap: () => setState(() => _activity = a),
          ),
      ];

  // ── Paso 3 ──
  List<Widget> _stepFood() => [
        const _Title('¿Hay algo que no comas?'),
        const _Why('Para no recomendarte lo que no puedes o no quieres comer.'),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final e in kAvoidOptions.entries)
            FilterChip(
              label: Text(e.value),
              selected: _avoid.contains(e.key),
              showCheckmark: true,
              selectedColor: AppColors.primary.withValues(alpha: 0.25),
              checkmarkColor: AppColors.primaryText,
              onSelected: (on) => setState(
                  () => on ? _avoid.add(e.key) : _avoid.remove(e.key)),
            ),
        ]),
        const SizedBox(height: 32),
        const _Title('¿Cuántas comidas haces al día?'),
        const _Why('Repartimos tu plan en esas comidas.'),
        const SizedBox(height: 16),
        _Segmented<int>(
          values: const [3, 4, 5],
          labels: const ['3', '4', '5'],
          selected: _meals,
          onSelect: (v) => setState(() => _meals = v),
        ),
      ];
}

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          height: 1.15));
}

class _Why extends StatelessWidget {
  const _Why(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(text,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 15, height: 1.4)),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
      );
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);
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

/// Fila con valor grande y botones −/+ (sin teclado: más rápido en el gym).
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.what,
    required this.onMinus,
    required this.onPlus,
  });
  final String label;
  final String value;
  final String what;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.surface)),
        ),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          ),
          IconButton(
              tooltip: 'Bajar $what',
              onPressed: onMinus,
              icon: Icon(Icons.remove, color: AppColors.textPrimary)),
          SizedBox(
            width: 104,
            child: Text(value,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
          ),
          IconButton(
              tooltip: 'Subir $what',
              onPressed: onPlus,
              icon: Icon(Icons.add, color: AppColors.textPrimary)),
        ]),
      );
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.values,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });
  final List<T> values;
  final List<String> labels;
  final T? selected;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < values.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _Choice(
              title: labels[i],
              selected: selected == values[i],
              onTap: () => onSelect(values[i]),
              center: true,
            ),
          ),
        ],
      ]);
}

/// Opción tocable: borde de acento cuando está elegida.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
    this.center = false,
  });
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool center;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment:
                    center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}
