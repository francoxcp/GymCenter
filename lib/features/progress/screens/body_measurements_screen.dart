import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/navigation/safe_pop.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/body_measurement.dart';
import '../providers/body_measurement_provider.dart';

const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
String fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
String fmtNum(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

/// Medidas corporales. Sin [memberId] son las propias; el entrenador la abre
/// con el id de su socio y también puede registrar.
class BodyMeasurementsScreen extends StatelessWidget {
  final String? memberId;
  final String? memberName;
  const BodyMeasurementsScreen({super.key, this.memberId, this.memberName});

  @override
  Widget build(BuildContext context) {
    if (memberId == null) return _Body(memberName: null);
    return ChangeNotifierProvider(
      create: (_) => BodyMeasurementProvider(memberId: memberId),
      child: _Body(memberName: memberName),
    );
  }
}

class _Body extends StatefulWidget {
  final String? memberName;
  const _Body({required this.memberName});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<BodyMeasurementProvider>().loadMeasurements());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BodyMeasurementProvider>();
    final list = p.measurements;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/progress'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Medidas', style: TextStyle(fontWeight: FontWeight.w900)),
            if (widget.memberName != null)
              Text(widget.memberName!,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-measure',
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => showMeasurementForm(context, p),
        icon: const Icon(Icons.straighten),
        label: const Text('Registrar', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: p.isLoading && list.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: p.loadMeasurements,
              child: list.isEmpty
                  ? ListView(children: [_Empty(onAdd: () => showMeasurementForm(context, p))])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      children: [
                        _WeightHero(provider: p),
                        const SizedBox(height: 24),
                        _sectionTitle('ÚLTIMAS MEDIDAS'),
                        const SizedBox(height: 8),
                        _LatestGrid(provider: p),
                        const SizedBox(height: 24),
                        _sectionTitle('HISTORIAL'),
                        for (final m in list) _HistoryRow(m: m, provider: p),
                      ],
                    ),
            ),
    );
  }
}

Widget _sectionTitle(String t) => Text(t,
    style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2));

class _Empty extends StatelessWidget {
  final VoidCallback onAdd;
  const _Empty({required this.onAdd});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
        child: Column(children: [
          Icon(Icons.straighten, size: 48, color: AppColors.primaryText),
          const SizedBox(height: 16),
          Text('Sin medidas todavía',
              style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('La primera es la más importante: con ella se nota el cambio. '
              'Solo llena las que tengas, ninguna es obligatoria.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
            child: const Text('Registrar la primera', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ]),
      );
}

class _Delta extends StatelessWidget {
  final double? change;
  final MeasureField field;
  final String suffix;
  const _Delta({required this.change, required this.field, this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    final c = change;
    if (c == null || c.abs() < 0.05) {
      return Text(c == null ? '' : 'igual$suffix',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12));
    }
    final good = field.lowerIsBetter ? c < 0 : null;
    final color = good == null
        ? AppColors.textSecondary
        : good
            ? AppColors.success
            : AppColors.warning;
    return Text('${c > 0 ? '+' : '−'}${fmtNum(c.abs())} ${field.unit}$suffix',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700));
  }
}

class _WeightHero extends StatelessWidget {
  final BodyMeasurementProvider provider;
  const _WeightHero({required this.provider});

  @override
  Widget build(BuildContext context) {
    final w = provider.latestOf(MeasureField.weight);
    final points = [
      for (final m in provider.measurements.reversed)
        if (m.weight != null) (m.date, m.weight!)
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('PESO'),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(w == null ? '—' : fmtNum(w),
                  style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      fontFeatures: const [FontFeature.tabularFigures()])),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('kg',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Delta(
                      change: provider.changeOf(MeasureField.weight),
                      field: MeasureField.weight,
                      suffix: ' vs anterior'),
                  _Delta(
                      change: provider.totalChangeOf(MeasureField.weight),
                      field: MeasureField.weight,
                      suffix: ' desde el inicio'),
                ],
              ),
            ],
          ),
          if (points.length >= 2) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 90,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => [
                        for (final s in spots)
                          LineTooltipItem(
                              '${fmtNum(s.y)} kg\n${fmtDate(points[s.x.toInt()].$1)}',
                              TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                      ],
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < points.length; i++)
                          FlSpot(i.toDouble(), points[i].$2)
                      ],
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                          show: true, color: AppColors.primary.withValues(alpha: 0.12)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LatestGrid extends StatelessWidget {
  final BodyMeasurementProvider provider;
  const _LatestGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    final fields = MeasureField.values
        .where((f) => f != MeasureField.weight && provider.latestOf(f) != null)
        .toList();
    if (fields.isEmpty) {
      return Text('Solo hay peso registrado. Agrega cintura, cadera o brazos en la próxima.',
          style: TextStyle(color: AppColors.textSecondary));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final f in fields)
          LayoutBuilder(builder: (context, _) {
            final width = (MediaQuery.of(context).size.width - 40 - 8) / 2;
            return Container(
              width: width,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.label,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text.rich(TextSpan(children: [
                    TextSpan(
                        text: fmtNum(provider.latestOf(f)!),
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900)),
                    TextSpan(
                        text: ' ${f.unit}',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ])),
                  _Delta(change: provider.changeOf(f), field: f),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final BodyMeasurement m;
  final BodyMeasurementProvider provider;
  const _HistoryRow({required this.m, required this.provider});

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().currentUser?.id;
    final count = MeasureField.values.where((f) => m.valueOf(f) != null).length;
    final by = m.recordedBy == null || m.recordedBy == m.userId
        ? (m.userId == me ? 'Tú' : 'El socio')
        : (m.recordedBy == me ? 'Tú' : 'Tu entrenador');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => showMeasurementForm(context, provider, existing: m),
      title: Text(fmtDate(m.date),
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      subtitle: Text(
          '${m.weight != null ? '${fmtNum(m.weight!)} kg · ' : ''}$count ${count == 1 ? 'medida' : 'medidas'} · $by',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
    );
  }
}

/// Formulario por grupos (Cuerpo, Tronco, Brazos, Piernas). Ninguna medida
/// es obligatoria; el valor anterior aparece de guía.
Future<void> showMeasurementForm(
  BuildContext context,
  BodyMeasurementProvider provider, {
  BodyMeasurement? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _MeasurementForm(provider: provider, existing: existing),
  );
}

class _MeasurementForm extends StatefulWidget {
  final BodyMeasurementProvider provider;
  final BodyMeasurement? existing;
  const _MeasurementForm({required this.provider, this.existing});

  @override
  State<_MeasurementForm> createState() => _MeasurementFormState();
}

class _MeasurementFormState extends State<_MeasurementForm> {
  late final Map<MeasureField, TextEditingController> _c = {
    for (final f in MeasureField.values)
      f: TextEditingController(
          text: widget.existing?.valueOf(f) == null ? '' : fmtNum(widget.existing!.valueOf(f)!))
  };
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  late DateTime _date = widget.existing?.date ?? DateTime.now();
  final _form = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    _notes.dispose();
    super.dispose();
  }

  double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final values = {for (final e in _c.entries) e.key: _parse(e.value.text)};
    if (values.values.every((v) => v == null)) {
      AppSnackbar.error(context, 'Anota al menos una medida');
      return;
    }
    setState(() => _saving = true);
    final m = BodyMeasurement.fromValues(
      id: widget.existing?.id ?? '',
      userId: widget.existing?.userId ?? '',
      date: _date,
      values: values,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      recordedBy: widget.existing?.recordedBy,
    );
    final ok = await widget.provider.saveMeasurement(m);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
      AppSnackbar.success(context, 'Medidas guardadas');
    } else {
      AppSnackbar.error(context, widget.provider.error ?? 'No se pudo guardar');
    }
  }

  Future<void> _delete() async {
    final e = widget.existing;
    if (e == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('¿Borrar esta medición?'),
        content: Text('${fmtDate(e.date)}. No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text('Borrar', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true) return;
    final done = await widget.provider.deleteMeasurement(e.id);
    if (mounted && done) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.88,
          child: Form(
            key: _form,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                  child: Row(children: [
                    Expanded(
                      child: Text(widget.existing == null ? 'Registrar medidas' : 'Corregir medidas',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                    ),
                    if (widget.existing != null)
                      IconButton(
                          tooltip: 'Borrar',
                          onPressed: _delete,
                          icon: Icon(Icons.delete_outline, color: AppColors.error)),
                    IconButton(
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close)),
                  ]),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) setState(() => _date = d);
                        },
                        icon: const Icon(Icons.event, size: 18),
                        label: Text(fmtDate(_date)),
                      ),
                      Text('Llena solo las que tengas. En gris, la medida anterior.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      for (final g in MeasureField.groups) ...[
                        const SizedBox(height: 16),
                        _sectionTitle(g.toUpperCase()),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final f in MeasureField.values.where((f) => f.group == g))
                              SizedBox(
                                width: (MediaQuery.of(context).size.width - 40 - 10) / 2,
                                child: TextFormField(
                                  controller: _c[f],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                                  ],
                                  decoration: InputDecoration(
                                    labelText: f.label,
                                    suffixText: f.unit,
                                    hintText: widget.provider.latestOf(f) == null
                                        ? null
                                        : fmtNum(widget.provider.latestOf(f)!),
                                    isDense: true,
                                    filled: true,
                                    fillColor: AppColors.inputFill,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none),
                                  ),
                                  validator: (s) {
                                    if (s == null || s.trim().isEmpty) return null;
                                    final v = _parse(s);
                                    if (v == null) return 'Número inválido';
                                    if (v < f.min || v > f.max) {
                                      return 'Entre ${fmtNum(f.min)} y ${fmtNum(f.max)}';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextField(
                        controller: _notes,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Notas (opcional)',
                          filled: true,
                          fillColor: AppColors.inputFill,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary),
                      child: _saving
                          ? const SizedBox(
                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
