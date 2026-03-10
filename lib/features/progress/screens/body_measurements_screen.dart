import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/utils/unit_converter.dart';
import '../providers/body_measurement_provider.dart';
import '../models/body_measurement.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/shimmer_loading.dart';

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
    const units = 'metric';

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
                  onRefresh: () =>
                      Provider.of<BodyMeasurementProvider>(context,
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
                      ...measurements.map((m) => _buildMeasurementCard(m, units)),
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
                'Peso',
                latest.weight != null
                    ? UnitConverter.formatWeight(latest.weight!, units)
                    : '--',
                weightChange != 0
                    ? UnitConverter.formatWeightChange(weightChange, units)
                    : null,
                weightChange < 0 ? Colors.green : Colors.red,
              ),
              _buildStatColumn(
                'Cintura',
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
        _buildMeasurementTile('Pecho', measurement.chest, Icons.fitness_center, units),
        _buildMeasurementTile('Bícep Izq.', measurement.effectiveBicepsLeft, Icons.sports_gymnastics, units),
        _buildMeasurementTile('Bícep Der.', measurement.effectiveBicepsRight, Icons.sports_gymnastics, units),
        _buildMeasurementTile('Muslo Izq.', measurement.effectiveThighLeft, Icons.directions_run, units),
        _buildMeasurementTile('Muslo Der.', measurement.effectiveThighRight, Icons.directions_run, units),
        _buildMeasurementTile('Cadera', measurement.hips, Icons.accessibility_new, units),
        _buildMeasurementTile('Altura', measurement.height, Icons.height, units),
      ],
    );
  }

  Widget _buildMeasurementTile(String label, double? value, IconData icon, String units) {
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

    String timeAgo;
    if (difference == 0) {
      timeAgo = 'Hoy';
    } else if (difference == 1) {
      timeAgo = 'Ayer';
    } else if (difference < 30) {
      timeAgo = 'Hace $difference días';
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
                        ? UnitConverter.formatWeight(
                            measurement.weight!, units)
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
              _buildSmallMeasurement('Pecho', measurement.chest),
              _buildSmallMeasurement('Cintura', measurement.waist),
              _buildSmallMeasurement('Cadera', measurement.hips),
              _buildSmallMeasurement('B.Izq', measurement.effectiveBicepsLeft),
              _buildSmallMeasurement('B.Der', measurement.effectiveBicepsRight),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSmallMeasurement('M.Izq', measurement.effectiveThighLeft),
              _buildSmallMeasurement('M.Der', measurement.effectiveThighRight),
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

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nueva Medida',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _buildMeasurementField(
                  'Peso (kg)', weightController, Icons.monitor_weight),
              _buildMeasurementField(
                  'Altura (cm)', heightController, Icons.height),
              _buildMeasurementField(
                  'Pecho (cm)', chestController, Icons.fitness_center),
              _buildMeasurementField(
                  'Cintura (cm)', waistController, Icons.straighten),
              _buildMeasurementField(
                  'Cadera (cm)', hipsController, Icons.accessibility_new),
              // Bíceps lado a lado
              _buildPairedFields(
                'Bícep Izquierdo (cm)',
                bicepsLeftController,
                'Bícep Derecho (cm)',
                bicepsRightController,
                Icons.sports_gymnastics,
              ),
              // Muslos lado a lado
              _buildPairedFields(
                'Muslo Izquierdo (cm)',
                thighLeftController,
                'Muslo Derecho (cm)',
                thighRightController,
                Icons.directions_run,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Notas (opcional)',
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
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.textSecondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
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
                          bicepsLeft: double.tryParse(bicepsLeftController.text),
                          bicepsRight: double.tryParse(bicepsRightController.text),
                          thighLeft: double.tryParse(thighLeftController.text),
                          thighRight: double.tryParse(thighRightController.text),
                          notes: notesController.text.isEmpty
                              ? null
                              : notesController.text,
                        );

                        final success = await measurementProvider
                            .addMeasurement(newMeasurement);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Medida guardada correctamente'
                                    : 'Error al guardar medida',
                              ),
                              backgroundColor:
                                  success ? Colors.green : AppColors.error,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Guardar',
                        style: TextStyle(
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
    );
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
        keyboardType: TextInputType.number,
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
