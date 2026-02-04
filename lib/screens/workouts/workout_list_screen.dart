import 'package:flutter/material.dart';
import 'create_workout_screen.dart';
import 'edit_workout_screen.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/workout_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/filter_chip_button.dart';

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  final _searchController = TextEditingController();
  int _currentIndex = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHAMOS FITNESS CENTER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Lista de Rutinas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar rutinas por nombre...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    FilterChipButton(
                      label: 'Todos',
                      isSelected: workoutProvider.selectedFilter == 'Todos',
                      onTap: () => workoutProvider.setFilter('Todos'),
                    ),
                    const SizedBox(width: 8),
                    FilterChipButton(
                      label: 'Principiante',
                      isSelected:
                          workoutProvider.selectedFilter == 'Principiante',
                      onTap: () => workoutProvider.setFilter('Principiante'),
                    ),
                    const SizedBox(width: 8),
                    FilterChipButton(
                      label: 'Intermedio',
                      isSelected:
                          workoutProvider.selectedFilter == 'Intermedio',
                      onTap: () => workoutProvider.setFilter('Intermedio'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Workout List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: workoutProvider.filteredWorkouts.length,
                  itemBuilder: (context, index) {
                    final workout = workoutProvider.filteredWorkouts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: isAdmin
                            ? () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditWorkoutScreen(workout: workout),
                                  ),
                                );
                                if (result == true) {
                                  workoutProvider.loadWorkouts(
                                      forceRefresh: true);
                                }
                              }
                            : () =>
                                context.push('/workout-detail/${workout.id}'),
                        child: _WorkoutCard(
                          title: workout.name,
                          duration: workout.duration,
                          exerciseCount: workout.exerciseCount,
                          level: workout.level,
                          isClickable: true,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // End of List
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Fin de la lista',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final workoutProvider =
                    Provider.of<WorkoutProvider>(context, listen: false);

                final result = await navigator.push(
                  MaterialPageRoute(
                    builder: (context) => const CreateWorkoutScreen(),
                  ),
                );

                if (result == true) {
                  await workoutProvider.loadWorkouts(forceRefresh: true);
                }
              },
              backgroundColor: AppColors.primary,
              child: const Icon(
                Icons.add,
                color: Colors.black,
                size: 32,
              ),
            )
          : null,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final String title;
  final int duration;
  final int exerciseCount;
  final String level;
  final bool isClickable;

  const _WorkoutCard({
    required this.title,
    required this.duration,
    required this.exerciseCount,
    required this.level,
    this.isClickable = false,
  });

  Color _getLevelColor() {
    switch (level) {
      case 'Principiante':
        return AppColors.badgePrincipiante;
      case 'Intermedio':
        return AppColors.badgeIntermedio;
      case 'Avanzado':
        return AppColors.badgeAvanzado;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBackground,
            AppColors.cardBackground.withOpacity(0.6),
            AppColors.primary.withOpacity(0.1),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _getLevelColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                level.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$duration min',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.fitness_center,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$exerciseCount ejercicios',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isClickable)
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.primary,
                      size: 32,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
