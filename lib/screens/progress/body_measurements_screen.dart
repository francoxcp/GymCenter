import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/body_measurement_provider.dart';
import '../../models/body_measurement.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/shimmer_loading.dart';
import 'package:intl/intl.dart';

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Medidas Corporales'),
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
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildCurrentStats(measurements),
                    const SizedBox(height: 24),
                    const Text(
                      'Historial',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...measurements.map((m) => _buildMeasurementCard(m)),
                  ],
                ),
    );
  }

  Widget _buildCurrentStats(List<BodyMeasurement> measurements) {
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
          const Text(
            'Medidas Actuales',
            style: TextStyle(
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
                '${latest.weight?.toStringAsFixed(1) ?? '--'} kg',
                weightChange != 0
                    ? '${weightChange > 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg'
                    : null,
                weightChange < 0 ? Colors.green : Colors.red,
              ),
              _buildStatColumn(
                'Cintura',
                '${latest.waist?.toStringAsFixed(1) ?? '--'} cm',
                waistChange != 0
                    ? '${waistChange > 0 ? '+' : ''}${waistChange.toStringAsFixed(1)} cm'
                    : null,
                waistChange < 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMeasurementGrid(latest),
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

  Widget _buildMeasurementGrid(BodyMeasurement measurement) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildMeasurementTile('Pecho', measurement.chest, Icons.fitness_center),
        _buildMeasurementTile(
            'Bíceps', measurement.biceps, Icons.sports_gymnastics),
        _buildMeasurementTile(
            'Muslos', measurement.thighs, Icons.directions_run),
        _buildMeasurementTile(
            'Cadera', measurement.hips, Icons.accessibility_new),
        _buildMeasurementTile('Altura', measurement.height, Icons.height),
      ],
    );
  }

  Widget _buildMeasurementTile(String label, double? value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 4),
          Text(
            value != null ? value.toStringAsFixed(1) : '--',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard(BodyMeasurement measurement) {
    final dateStr = DateFormat('dd MMM yyyy', 'es').format(measurement.date);
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
                    '${measurement.weight?.toStringAsFixed(1) ?? '--'} kg',
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
              _buildSmallMeasurement('Bíceps', measurement.biceps),
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
            const Text(
              'Sin medidas registradas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Comienza a registrar tus medidas\npara hacer seguimiento de tu progreso',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            PrimaryButton(
              text: 'Añadir primera medida',
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
    final bicepsController = TextEditingController();
    final thighsController = TextEditingController();
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
              _buildMeasurementField(
                  'Bíceps (cm)', bicepsController, Icons.sports_gymnastics),
              _buildMeasurementField(
                  'Muslos (cm)', thighsController, Icons.directions_run),
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
                          biceps: double.tryParse(bicepsController.text),
                          thighs: double.tryParse(thighsController.text),
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
}
