import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../workouts/providers/workout_provider.dart';
import '../../workouts/models/workout.dart';
import '../../workouts/models/exercise.dart';

class PersonalRecordsScreen extends StatefulWidget {
  const PersonalRecordsScreen({super.key});

  @override
  State<PersonalRecordsScreen> createState() => _PersonalRecordsScreenState();
}

class _PersonalRecordsScreenState extends State<PersonalRecordsScreen> {
  bool _loading = true;
  List<Exercise> _exercises = [];

  /// exercise_name → all-time max weight_kg for this user
  Map<String, double> _prByName = {};

  String _search = '';
  String _filterCategory = 'Todos';
  List<String> _categories = ['Todos'];

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null || user.assignedWorkoutId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      // ── 1. Fetch exercises from assigned workout ─────────────────────────
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      Workout? workout =
          workoutProvider.getWorkoutById(user.assignedWorkoutId!);

      if (workout == null) {
        // Fallback: load directly from Supabase
        final supabase = Supabase.instance.client;
        final raw = await supabase
            .from('workouts')
            .select('*, exercises(*)')
            .eq('id', user.assignedWorkoutId!)
            .single();
        workout = Workout.fromJson(raw);
      }

      // ── 2. Fetch all-time set logs for this user ─────────────────────────
      final supabase = Supabase.instance.client;
      final logs = await supabase
          .from('exercise_set_logs')
          .select('exercise_name, weight_kg')
          .eq('user_id', user.id);

      final Map<String, double> prs = {};
      for (final log in logs as List) {
        final name = (log['exercise_name'] as String?)?.trim() ?? '';
        final w = (log['weight_kg'] as num?)?.toDouble();
        if (name.isEmpty || w == null) continue;
        if (!prs.containsKey(name) || w > prs[name]!) {
          prs[name] = w;
        }
      }

      // ── 3. Build category list ────────────────────────────────────────────
      final exercises = workout.exercises;
      final cats = <String>['Todos'];
      final seen = <String>{};
      for (final e in exercises) {
        final mg = e.muscleGroup;
        if (mg.isNotEmpty && !seen.contains(mg)) {
          seen.add(mg);
          cats.add(mg);
        }
      }

      if (mounted) {
        setState(() {
          _exercises = exercises;
          _prByName = prs;
          _categories = cats;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando PRs: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtWeight(double w) =>
      w == w.roundToDouble() ? '${w.toInt()} kg' : '${w.toStringAsFixed(1)} kg';

  List<Exercise> get _filtered {
    return _exercises.where((e) {
      final matchCat =
          _filterCategory == 'Todos' || e.muscleGroup == _filterCategory;
      final matchSearch = _search.isEmpty ||
          e.name.toLowerCase().contains(_search.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  Future<void> _showHistory(Exercise exercise) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id;
    if (userId == null) return;

    final supabase = Supabase.instance.client;
    List logs = [];
    try {
      logs = await supabase
          .from('exercise_set_logs')
          .select('set_index, weight_kg, reps, logged_at')
          .eq('user_id', userId)
          .eq('exercise_name', exercise.name)
          .order('logged_at', ascending: false)
          .limit(40);
    } catch (e) {
      debugPrint('Error loading exercise history: $e');
    }

    if (!mounted) return;

    // Agrupar por fecha (día)
    final Map<String, List<Map>> byDate = {};
    for (final log in logs) {
      final dt = DateTime.tryParse(log['logged_at'] as String? ?? '');
      if (dt == null) continue;
      final local = dt.toLocal();
      final key = '${local.day.toString().padLeft(2, '0')}/'
          '${local.month.toString().padLeft(2, '0')}/'
          '${local.year}';
      (byDate[key] ??= []).add(Map.from(log));
    }
    final sessions = byDate.entries.toList();
    final pr = _prByName[exercise.name];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.88,
        expand: false,
        builder: (_, scroll) => Container(
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.muscleGroup.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            exercise.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (pr != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.amber.withOpacity(0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🏆', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 5),
                            Text(
                              _fmtWeight(pr),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Divider(
                  color: AppColors.textSecondary.withOpacity(0.15), height: 20),
              Expanded(
                child: sessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fitness_center,
                                color: AppColors.textSecondary.withOpacity(0.4),
                                size: 40),
                            const SizedBox(height: 12),
                            const Text(
                              'Aún no hay registros\npara este ejercicio',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scroll,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: sessions.length,
                        itemBuilder: (ctx, i) {
                          final date = sessions[i].key;
                          final sets = sessions[i].value
                            ..sort((a, b) => (a['set_index'] as int? ?? 0)
                                .compareTo(b['set_index'] as int? ?? 0));
                          return _HistorySessionCard(
                              date: date, sets: sets, fmtWeight: _fmtWeight);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Records'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final filtered = _filtered;

    return Column(
      children: [
        // ── Search bar ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search exercises...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search,
                    color: AppColors.textSecondary, size: 20),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
        ),

        // ── Category chips ────────────────────────────────────────────
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            itemBuilder: (ctx, i) {
              final cat = _categories[i];
              final isSelected = _filterCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _filterCategory = cat),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color:
                          isSelected ? Colors.black : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // ── Exercise list ─────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No se encontraron ejercicios',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  backgroundColor: AppColors.cardBackground,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final exercise = filtered[i];
                      final pr = _prByName[exercise.name];
                      return _PRCard(
                        exercise: exercise,
                        pr: pr,
                        fmtWeight: _fmtWeight,
                        onHistory: () => _showHistory(exercise),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ── PR Card ────────────────────────────────────────────────────────────────────

class _PRCard extends StatelessWidget {
  final Exercise exercise;
  final double? pr;
  final String Function(double) fmtWeight;
  final VoidCallback onHistory;

  const _PRCard({
    required this.exercise,
    required this.pr,
    required this.fmtWeight,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Left: muscle group + name + history
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.muscleGroup.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onHistory,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history,
                          size: 13,
                          color: AppColors.textSecondary.withOpacity(0.8)),
                      const SizedBox(width: 4),
                      Text(
                        'Ver Historial',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right: PR weight
          if (pr != null)
            _PRWeight(text: fmtWeight(pr!))
          else
            Text(
              '—',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary.withOpacity(0.4),
              ),
            ),
        ],
      ),
    );
  }
}

/// Renders the big yellow italic weight number like in the mockup.
class _PRWeight extends StatelessWidget {
  final String text;
  const _PRWeight({required this.text});

  @override
  Widget build(BuildContext context) {
    // Split value and unit for different styling
    final parts = text.split(' ');
    final value = parts.isNotEmpty ? parts[0] : text;
    final unit = parts.length > 1 ? parts[1] : '';

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: AppColors.primary,
              height: 1,
            ),
          ),
          TextSpan(
            text: unit,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: AppColors.primary,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── History Session Card ───────────────────────────────────────────────────────

class _HistorySessionCard extends StatelessWidget {
  final String date;
  final List<Map> sets;
  final String Function(double) fmtWeight;

  const _HistorySessionCard({
    required this.date,
    required this.sets,
    required this.fmtWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          date,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: sets.map((s) {
            final w = (s['weight_kg'] as num?)?.toDouble();
            final r = s['reps'] as int?;
            final setNum = (s['set_index'] as int? ?? 0) + 1;
            if (w == null) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
              ),
              child: Text(
                r != null
                    ? 'S$setNum: ${fmtWeight(w)} × $r'
                    : 'S$setNum: ${fmtWeight(w)}',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Divider(color: AppColors.textSecondary.withOpacity(0.1)),
      ],
    );
  }
}
