import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/exercise.dart';

/// Ejercicio del catálogo con valores por defecto razonables.
class LibraryExercise {
  final String name;
  final String muscle;
  final int sets;
  final int reps;
  final int rest;

  const LibraryExercise(this.name, this.muscle,
      {this.sets = 3, this.reps = 12, this.rest = 60});

  Exercise toExercise() => Exercise(
        id: '',
        name: name,
        sets: sets,
        reps: reps,
        restSeconds: rest,
        muscleGroup: muscle,
      );
}

const kMuscleGroups = [
  'Pecho',
  'Espalda',
  'Piernas',
  'Glúteos',
  'Hombros',
  'Bíceps',
  'Tríceps',
  'Core',
  'Cardio',
];

/// Catálogo base del gimnasio. El grupo muscular alimenta la progresión
/// inteligente (+10 lbs en piernas) y la detección de cardio.
const kExerciseLibrary = <LibraryExercise>[
  // Pecho
  LibraryExercise('Press de banca con barra', 'Pecho', reps: 10, rest: 90),
  LibraryExercise('Press inclinado con mancuernas', 'Pecho', reps: 10, rest: 90),
  LibraryExercise('Press declinado', 'Pecho', reps: 10, rest: 90),
  LibraryExercise('Aperturas con mancuernas', 'Pecho'),
  LibraryExercise('Cruce de poleas', 'Pecho'),
  LibraryExercise('Press en máquina (pecho)', 'Pecho'),
  LibraryExercise('Fondos en paralelas', 'Pecho', reps: 10),
  LibraryExercise('Flexiones', 'Pecho', reps: 15),
  // Espalda
  LibraryExercise('Dominadas', 'Espalda', reps: 8, rest: 90),
  LibraryExercise('Jalón al pecho', 'Espalda', reps: 10),
  LibraryExercise('Remo con barra', 'Espalda', reps: 10, rest: 90),
  LibraryExercise('Remo con mancuerna', 'Espalda', reps: 10),
  LibraryExercise('Remo sentado en polea', 'Espalda'),
  LibraryExercise('Pullover en polea', 'Espalda'),
  LibraryExercise('Peso muerto', 'Espalda', sets: 4, reps: 6, rest: 120),
  LibraryExercise('Hiperextensiones', 'Espalda', reps: 15),
  // Piernas
  LibraryExercise('Sentadilla con barra', 'Piernas', sets: 4, reps: 8, rest: 120),
  LibraryExercise('Sentadilla goblet', 'Piernas', reps: 12, rest: 90),
  LibraryExercise('Prensa de piernas', 'Piernas', sets: 4, reps: 10, rest: 90),
  LibraryExercise('Zancadas con mancuernas', 'Piernas', reps: 10),
  LibraryExercise('Sentadilla búlgara', 'Piernas', reps: 10, rest: 90),
  LibraryExercise('Extensión de cuádriceps', 'Piernas'),
  LibraryExercise('Curl femoral acostado', 'Piernas'),
  LibraryExercise('Peso muerto rumano', 'Piernas', reps: 10, rest: 90),
  LibraryExercise('Elevación de talones (pantorrilla)', 'Piernas', reps: 15),
  // Glúteos
  LibraryExercise('Hip thrust con barra', 'Glúteos', sets: 4, reps: 10, rest: 90),
  LibraryExercise('Patada de glúteo en polea', 'Glúteos', reps: 15),
  LibraryExercise('Abducción en máquina', 'Glúteos', reps: 15),
  LibraryExercise('Puente de glúteo', 'Glúteos', reps: 15),
  // Hombros
  LibraryExercise('Press militar con barra', 'Hombros', reps: 8, rest: 90),
  LibraryExercise('Press de hombro con mancuernas', 'Hombros', reps: 10),
  LibraryExercise('Elevaciones laterales', 'Hombros', reps: 15),
  LibraryExercise('Elevaciones frontales', 'Hombros'),
  LibraryExercise('Pájaros (deltoides posterior)', 'Hombros', reps: 15),
  LibraryExercise('Face pull', 'Hombros', reps: 15),
  LibraryExercise('Encogimientos (trapecio)', 'Hombros'),
  // Bíceps
  LibraryExercise('Curl con barra', 'Bíceps', reps: 10),
  LibraryExercise('Curl alterno con mancuernas', 'Bíceps'),
  LibraryExercise('Curl martillo', 'Bíceps'),
  LibraryExercise('Curl predicador', 'Bíceps', reps: 10),
  LibraryExercise('Curl en polea', 'Bíceps'),
  // Tríceps
  LibraryExercise('Extensión de tríceps en polea', 'Tríceps'),
  LibraryExercise('Press francés', 'Tríceps', reps: 10),
  LibraryExercise('Fondos en banco', 'Tríceps'),
  LibraryExercise('Patada de tríceps', 'Tríceps'),
  LibraryExercise('Press cerrado', 'Tríceps', reps: 10, rest: 90),
  // Core
  LibraryExercise('Plancha (segundos)', 'Core', reps: 30, rest: 45),
  LibraryExercise('Crunch abdominal', 'Core', reps: 20, rest: 45),
  LibraryExercise('Elevación de piernas colgado', 'Core', reps: 12),
  LibraryExercise('Rueda abdominal', 'Core', reps: 10),
  LibraryExercise('Russian twist', 'Core', reps: 20, rest: 45),
  LibraryExercise('Plancha lateral (segundos)', 'Core', reps: 30, rest: 45),
  // Cardio
  LibraryExercise('Caminadora (minutos)', 'Cardio', sets: 1, reps: 15, rest: 0),
  LibraryExercise('Bicicleta estática (minutos)', 'Cardio', sets: 1, reps: 15, rest: 0),
  LibraryExercise('Elíptica (minutos)', 'Cardio', sets: 1, reps: 15, rest: 0),
  LibraryExercise('Remo ergómetro (minutos)', 'Cardio', sets: 1, reps: 10, rest: 0),
  LibraryExercise('Saltar la cuerda', 'Cardio', reps: 60, rest: 45),
  LibraryExercise('Burpees', 'Cardio', reps: 12, rest: 60),
];

/// Resultado del selector: ejercicios elegidos o petición de crear uno propio.
class LibraryResult {
  final List<Exercise> exercises;
  final bool createCustom;
  const LibraryResult(this.exercises, {this.createCustom = false});
}

/// Biblioteca con buscador, filtro por músculo y selección múltiple.
Future<LibraryResult?> showExerciseLibrary(BuildContext context) {
  return showModalBottomSheet<LibraryResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _LibrarySheet(),
  );
}

class _LibrarySheet extends StatefulWidget {
  const _LibrarySheet();

  @override
  State<_LibrarySheet> createState() => _LibrarySheetState();
}

class _LibrarySheetState extends State<_LibrarySheet> {
  String _query = '';
  String? _muscle;
  final List<LibraryExercise> _selected = [];

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');

  @override
  Widget build(BuildContext context) {
    final q = _norm(_query.trim());
    final items = kExerciseLibrary
        .where((e) => _muscle == null || e.muscle == _muscle)
        .where((e) => q.isEmpty || _norm(e.name).contains(q))
        .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('Biblioteca de ejercicios',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar ejercicio…',
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _filterChip('Todos', null),
                for (final m in kMuscleGroups) _filterChip(m, m),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length + 1,
              itemBuilder: (_, i) {
                if (i == items.length) {
                  return ListTile(
                    leading: Icon(Icons.add_circle_outline,
                        color: AppColors.primary),
                    title: Text('Crear ejercicio personalizado',
                        style: TextStyle(color: AppColors.primary)),
                    subtitle: Text('Con nombre propio y video',
                        style: TextStyle(color: AppColors.textSecondary)),
                    onTap: () => Navigator.pop(
                        context, const LibraryResult([], createCustom: true)),
                  );
                }
                final e = items[i];
                final selected = _selected.contains(e);
                return CheckboxListTile(
                  value: selected,
                  activeColor: AppColors.primary,
                  checkColor: Colors.black,
                  onChanged: (_) => setState(() {
                    selected ? _selected.remove(e) : _selected.add(e);
                  }),
                  title: Text(e.name,
                      style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                      '${e.muscle} · ${e.sets}×${e.reps}${e.rest > 0 ? ' · ${e.rest}s' : ''}',
                      style: TextStyle(color: AppColors.textSecondary)),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.pop(
                            context,
                            LibraryResult(_selected
                                .map((e) => e.toExercise())
                                .toList()),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _selected.isEmpty
                        ? 'Selecciona ejercicios'
                        : 'Agregar ${_selected.length} ejercicio${_selected.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _muscle == value,
          onSelected: (_) => setState(() => _muscle = value),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
              color: _muscle == value ? Colors.black : AppColors.textPrimary),
        ),
      );
}

/// Ajuste rápido de series, reps, descanso y peso con botones +/−.
Future<Exercise?> showQuickExerciseEditor(
    BuildContext context, Exercise exercise) {
  return showModalBottomSheet<Exercise>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _QuickEditor(exercise: exercise),
  );
}

class _QuickEditor extends StatefulWidget {
  final Exercise exercise;
  const _QuickEditor({required this.exercise});

  @override
  State<_QuickEditor> createState() => _QuickEditorState();
}

class _QuickEditorState extends State<_QuickEditor> {
  late int sets = widget.exercise.sets;
  late int reps = widget.exercise.reps;
  late int rest = widget.exercise.restSeconds;
  late double weight = widget.exercise.weight;

  Widget _row(String label, String value, VoidCallback onMinus,
          VoidCallback onPlus) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
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
            width: 72,
            child: Text(value,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          IconButton(
              tooltip: 'Más $label',
              onPressed: onPlus,
              icon: Icon(Icons.add_circle_outline,
                  color: AppColors.primary)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(e.name,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _row('Series', '$sets', () => setState(() => sets = (sets - 1).clamp(1, 20)),
                () => setState(() => sets = (sets + 1).clamp(1, 20))),
            _row('Reps', '$reps', () => setState(() => reps = (reps - 1).clamp(1, 200)),
                () => setState(() => reps = (reps + 1).clamp(1, 200))),
            _row('Descanso', '${rest}s',
                () => setState(() => rest = (rest - 15).clamp(0, 600)),
                () => setState(() => rest = (rest + 15).clamp(0, 600))),
            _row(
                'Peso',
                weight <= 0 ? '—' : '${weight.toStringAsFixed(0)} lbs',
                () => setState(() => weight = (weight - 5).clamp(0, 1000)),
                () => setState(() => weight = (weight + 5).clamp(0, 1000))),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                Exercise(
                  id: e.id,
                  name: e.name,
                  description: e.description,
                  sets: sets,
                  reps: reps,
                  restSeconds: rest,
                  videoUrl: e.videoUrl,
                  thumbnailUrl: e.thumbnailUrl,
                  muscleGroup: e.muscleGroup,
                  difficulty: e.difficulty,
                  weight: weight,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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

/// Copia de un ejercicio (para el botón Duplicar).
Exercise duplicateExercise(Exercise e) => Exercise(
      id: '',
      name: e.name,
      description: e.description,
      sets: e.sets,
      reps: e.reps,
      restSeconds: e.restSeconds,
      videoUrl: e.videoUrl,
      thumbnailUrl: e.thumbnailUrl,
      muscleGroup: e.muscleGroup,
      difficulty: e.difficulty,
      weight: e.weight,
    );
