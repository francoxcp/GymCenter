import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/utils/unit_converter.dart';
import '../../settings/providers/preferences_provider.dart';
import '../providers/body_measurement_provider.dart';
import '../models/body_measurement.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/app_snackbar.dart';

class BodyMeasurementsScreen extends StatefulWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  State<BodyMeasurementsScreen> createState() => _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState extends State<BodyMeasurementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BodyMeasurementProvider>(context, listen: false)
          .loadMeasurements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final measurementProvider = Provider.of<BodyMeasurementProvider>(context);
    final measurements = measurementProvider.measurements;
    final prefsProvider =
        Provider.of<PreferencesProvider>(context, listen: false);
    final units =
        (prefsProvider.preferences?.language == 'en') ? 'imperial' : 'metric';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(AppL10n.of(context).bodyMeasurementsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMeasurementDialog(),
          ),
        ],
      ),
      body: measurementProvider.isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 6,
              itemBuilder: (context, index) => const ShimmerCard(height: 140),
            )
          : measurements.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => Provider.of<BodyMeasurementProvider>(context,
                          listen: false)
                      .loadMeasurements(),
                  color: AppColors.primary,
                  backgroundColor: AppColors.cardBackground,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildCurrentStats(measurements, units),
                      const SizedBox(height: 24),
                      Text(
                        AppL10n.of(context).measurementHistory,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...measurements
                          .map((m) => _buildMeasurementCard(m, units)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCurrentStats(List<BodyMeasurement> measurements, String units) {
    if (measurements.isEmpty) return const SizedBox();

    final latest = measurements.first;
    final oldest = measurements.last;

    final weightChange = (latest.weight ?? 0) - (oldest.weight ?? 0);
    final waistChange = (latest.waist ?? 0) - (oldest.waist ?? 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppL10n.of(context).currentMeasurements,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                AppL10n.of(context).weightLabel,
                latest.weight != null
                    ? UnitConverter.formatWeight(latest.weight!, units)
                    : '--',
                weightChange != 0
                    ? UnitConverter.formatWeightChange(weightChange, units)
                    : null,
                weightChange < 0 ? Colors.green : Colors.red,
              ),
              _buildStatColumn(
                AppL10n.of(context).waistLabel,
                latest.waist != null
                    ? UnitConverter.formatLength(latest.waist!, units)
                    : '--',
                waistChange != 0
                    ? UnitConverter.formatLengthChange(waistChange, units)
                    : null,
                waistChange < 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMeasurementGrid(latest, units),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
      String label, String value, String? change, Color? changeColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (change != null)
          Text(
            change,
            style: TextStyle(
              fontSize: 12,
              color: changeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildMeasurementGrid(BodyMeasurement measurement, String units) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.82,
      children: [
        _buildMeasurementTile(AppL10n.of(context).chestLabel, measurement.chest,
            Icons.fitness_center, units),
        _buildMeasurementTile(AppL10n.of(context).leftBicep,
            measurement.effectiveBicepsLeft, Icons.sports_gymnastics, units),
        _buildMeasurementTile(AppL10n.of(context).rightBicep,
            measurement.effectiveBicepsRight, Icons.sports_gymnastics, units),
        _buildMeasurementTile(AppL10n.of(context).leftThigh,
            measurement.effectiveThighLeft, Icons.directions_run, units),
        _buildMeasurementTile(AppL10n.of(context).rightThigh,
            measurement.effectiveThighRight, Icons.directions_run, units),
        _buildMeasurementTile(AppL10n.of(context).hipLabel, measurement.hips,
            Icons.accessibility_new, units),
        _buildMeasurementTile(AppL10n.of(context).heightLabel,
            measurement.height, Icons.height, units),
      ],
    );
  }

  Widget _buildMeasurementTile(
      String label, double? value, IconData icon, String units) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 4),
          Text(
            value != null ? UnitConverter.lengthValue(value, units) : '--',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            value != null ? UnitConverter.lengthUnit(units) : '',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.primary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard(BodyMeasurement measurement, String units) {
    final date = measurement.date;
    final dateStr = '${date.day}/${date.month}/${date.year}';
    final now = DateTime.now();
    final difference = now.difference(measurement.date).inDays;

    final l10n = AppL10n.of(context);
    String timeAgo;
    if (difference == 0) {
      timeAgo = l10n.todayLabel;
    } else if (difference == 1) {
      timeAgo = l10n.yesterdayLabel;
    } else if (difference < 30) {
      timeAgo = l10n.daysAgo(difference);
    } else {
      timeAgo = dateStr;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timeAgo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  Text(
                    measurement.weight != null
                        ? UnitConverter.formatWeight(measurement.weight!, units)
                        : '--',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSmallMeasurement(l10n.chestLabel, measurement.chest),
              _buildSmallMeasurement(l10n.waistLabel, measurement.waist),
              _buildSmallMeasurement(l10n.hipLabel, measurement.hips),
              _buildSmallMeasurement(
                  l10n.leftBicepShort, measurement.effectiveBicepsLeft),
              _buildSmallMeasurement(
                  l10n.rightBicepShort, measurement.effectiveBicepsRight),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSmallMeasurement(
                  l10n.leftThighShort, measurement.effectiveThighLeft),
              _buildSmallMeasurement(
                  l10n.rightThighShort, measurement.effectiveThighRight),
              const SizedBox(width: 40),
              const SizedBox(width: 40),
              const SizedBox(width: 40),
            ],
          ),
          if (measurement.notes != null && measurement.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                measurement.notes!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallMeasurement(String label, double? value) {
    return Column(
      children: [
        Text(
          value != null ? value.toStringAsFixed(1) : '--',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.straighten,
              size: 100,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              AppL10n.of(context).noMeasurementsYet,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppL10n.of(context).noMeasurementsBody,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            PrimaryButton(
              text: AppL10n.of(context).addFirstMeasurement,
              onPressed: () => _showAddMeasurementDialog(),
              width: 220,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMeasurementDialog() {
    final weightController = TextEditingController();
    final heightController = TextEditingController();
    final chestController = TextEditingController();
    final waistController = TextEditingController();
    final hipsController = TextEditingController();
    final bicepsLeftController = TextEditingController();
    final bicepsRightController = TextEditingController();
    final thighLeftController = TextEditingController();
    final thighRightController = TextEditingController();
    final notesController = TextEditingController();

    bool hasContent() {
      return weightController.text.isNotEmpty ||
          heightController.text.isNotEmpty ||
          chestController.text.isNotEmpty ||
          waistController.text.isNotEmpty ||
          hipsController.text.isNotEmpty ||
          bicepsLeftController.text.isNotEmpty ||
          bicepsRightController.text.isNotEmpty ||
          thighLeftController.text.isNotEmpty ||
          thighRightController.text.isNotEmpty ||
          notesController.text.isNotEmpty;
    }

    Future<bool> confirmDiscard(BuildContext ctx) async {
      if (!hasContent()) return true;
      final shouldPop = await showDialog<bool>(
        context: ctx,
        builder: (context) {
          final l10n = AppL10n.of(context);
          return AlertDialog(
            title: Text(l10n.discardMeasurementsTitle),
            content: Text(
              l10n.discardMeasurementsBody,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(l10n.discardLabel),
              ),
            ],
          );
        },
      );
      return shouldPop == true;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (await confirmDiscard(context)) {
            if (context.mounted) Navigator.of(context).pop();
          }
        },
        child: Dialog(
          backgroundColor: AppColors.cardBackground,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppL10n.of(context).newMeasurement,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                _buildMeasurementField(AppL10n.of(context).weightUnit('kg'),
                    weightController, Icons.monitor_weight),
                _buildMeasurementField(AppL10n.of(context).heightUnit('cm'),
                    heightController, Icons.height),
                _buildMeasurementField(
                    AppL10n.of(context)
                        .measureUnit(AppL10n.of(context).chestLabel, 'cm'),
                    chestController,
                    Icons.fitness_center),
                _buildMeasurementField(
                    AppL10n.of(context)
                        .measureUnit(AppL10n.of(context).waistLabel, 'cm'),
                    waistController,
                    Icons.straighten),
                _buildMeasurementField(
                    AppL10n.of(context)
                        .measureUnit(AppL10n.of(context).hipLabel, 'cm'),
                    hipsController,
                    Icons.accessibility_new),
                // B�ceps lado a lado
                _buildPairedFields(
                  AppL10n.of(context)
                      .measureUnit(AppL10n.of(context).leftBicepFull, 'cm'),
                  bicepsLeftController,
                  AppL10n.of(context)
                      .measureUnit(AppL10n.of(context).rightBicepFull, 'cm'),
                  bicepsRightController,
                  Icons.sports_gymnastics,
                ),
                // Muslos lado a lado
                _buildPairedFields(
                  AppL10n.of(context)
                      .measureUnit(AppL10n.of(context).leftThighFull, 'cm'),
                  thighLeftController,
                  AppL10n.of(context)
                      .measureUnit(AppL10n.of(context).rightThighFull, 'cm'),
                  thighRightController,
                  Icons.directions_run,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: AppL10n.of(context).notesOptional,
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          if (await confirmDiscard(context)) {
                            if (context.mounted) Navigator.of(context).pop();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side:
                              const BorderSide(color: AppColors.textSecondary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppL10n.of(context).cancel,
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Validar que al menos un campo num�rico tenga valor
                          final controllers = [
                            weightController,
                            heightController,
                            chestController,
                            waistController,
                            hipsController,
                            bicepsLeftController,
                            bicepsRightController,
                            thighLeftController,
                            thighRightController,
                          ];
                          final hasAnyValue = controllers.any(
                            (c) => c.text.trim().isNotEmpty,
                          );
                          if (!hasAnyValue) {
                            AppSnackbar.error(context,
                                AppL10n.of(context).enterAtLeastOneMeasure);
                            return;
                          }
                          // Validar que los valores sean num�ricos positivos
                          for (final c in controllers) {
                            if (c.text.trim().isNotEmpty) {
                              final val = double.tryParse(c.text.trim());
                              if (val == null || val <= 0) {
                                AppSnackbar.error(context,
                                    AppL10n.of(context).valuesMustBePositive);
                                return;
                              }
                            }
                          }

                          // Validar rangos m�ximos razonables
                          final maxRanges = <TextEditingController, double>{
                            weightController: 300,
                            heightController: 250,
                            chestController: 200,
                            waistController: 200,
                            hipsController: 200,
                            bicepsLeftController: 80,
                            bicepsRightController: 80,
                            thighLeftController: 120,
                            thighRightController: 120,
                          };
                          for (final entry in maxRanges.entries) {
                            final text = entry.key.text.trim();
                            if (text.isNotEmpty) {
                              final val = double.tryParse(text);
                              if (val != null && val > entry.value) {
                                AppSnackbar.error(
                                    context,
                                    AppL10n.of(context)
                                        .valueTooHigh(entry.value.toInt()));
                                return;
                              }
                            }
                          }

                          final measurementProvider =
                              Provider.of<BodyMeasurementProvider>(
                            context,
                            listen: false,
                          );

                          // Crear nueva medida
                          final newMeasurement = BodyMeasurement(
                            id: '',
                            userId: '',
                            date: DateTime.now(),
                            weight: double.tryParse(weightController.text),
                            height: double.tryParse(heightController.text),
                            chest: double.tryParse(chestController.text),
                            waist: double.tryParse(waistController.text),
                            hips: double.tryParse(hipsController.text),
                            bicepsLeft:
                                double.tryParse(bicepsLeftController.text),
                            bicepsRight:
                                double.tryParse(bicepsRightController.text),
                            thighLeft:
                                double.tryParse(thighLeftController.text),
                            thighRight:
                                double.tryParse(thighRightController.text),
                            notes: notesController.text.isEmpty
                                ? null
                                : notesController.text,
                          );

                          final success = await measurementProvider
                              .addMeasurement(newMeasurement);

                          if (context.mounted) {
                            Navigator.pop(context);
                            if (success) {
                              HapticFeedback.mediumImpact();
                              AppSnackbar.success(
                                  context, AppL10n.of(context).measureSaved);
                            } else {
                              AppSnackbar.error(context,
                                  AppL10n.of(context).errorSavingMeasure);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppL10n.of(context).save,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      weightController.dispose();
      heightController.dispose();
      chestController.dispose();
      waistController.dispose();
      hipsController.dispose();
      bicepsLeftController.dispose();
      bicepsRightController.dispose();
      thighLeftController.dispose();
      thighRightController.dispose();
      notesController.dispose();
    });
  }

  Widget _buildMeasurementField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.primary),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPairedFields(
    String leftLabel,
    TextEditingController leftController,
    String rightLabel,
    TextEditingController rightController,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: leftController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: leftLabel,
                labelStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: rightController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: rightLabel,
                labelStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
