import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../config/supabase_config.dart';
import '../../profile/providers/user_provider.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../meal_plans/screens/create_meal_plan_screen.dart';
import '../../workouts/screens/create_workout_screen.dart';
import 'user_management_screen.dart';
import 'user_assignments_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _totalUsers = 0;
  int _totalSessions = 0;
  List<int> _dailySessions = [0, 0, 0, 0, 0, 0, 0];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Cargar usuarios
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUsers();

      // Obtener total de usuarios
      final usersResponse =
          await SupabaseConfig.client.from('users').select('id');

      final totalUsers = (usersResponse as List).length;

      // Obtener sesiones de los últimos 7 días
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 6));
      final startOfDay =
          DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);

      final sessionsResponse = await SupabaseConfig.client
          .from('workout_sessions')
          .select('completed_at')
          .gte('completed_at', startOfDay.toIso8601String());

      final sessions = sessionsResponse as List;

      // Calcular sesiones por día
      final dailyCounts = List<int>.filled(7, 0);
      for (var session in sessions) {
        final completedAt = DateTime.parse(session['completed_at']);
        final daysDiff = now.difference(completedAt).inDays;
        if (daysDiff >= 0 && daysDiff < 7) {
          dailyCounts[6 -
              daysDiff]++; // Invertido para que el más reciente esté a la derecha
        }
      }

      setState(() {
        _totalUsers = totalUsers;
        _totalSessions = sessions.length;
        _dailySessions = dailyCounts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADMIN PORTAL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Chamos Fitness Center',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, left: 8),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'AD',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Actividad Semanal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Últimos 7 días',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _isLoading
                    ? const Row(
                        children: [
                          Expanded(
                            child: ShimmerCard(height: 100),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ShimmerCard(height: 100),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.people,
                              title: 'USUARIOS',
                              value: _totalUsers.toString(),
                              change: '',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.bolt,
                              iconColor: AppColors.primary,
                              title: 'SESIONES',
                              value: _totalSessions.toString(),
                              change: 'Últimos 7 días',
                              isNegative: false,
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: AppSpacing.xl),
                _isLoading
                    ? Container(
                        height: 200,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(AppSpacing.lg),
                        ),
                        child: const ShimmerCard(height: 180),
                      )
                    : Container(
                        height: 200,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(AppSpacing.lg),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _buildChartBars(),
                        ),
                      ),
                const SizedBox(height: AppSpacing.xxl),
                const Text(
                  'GESTIÓN RÁPIDA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _QuickActionButton(
                  icon: Icons.people,
                  iconColor: Colors.blue,
                  title: 'Gestión de Usuarios',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserManagementScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _QuickActionButton(
                  icon: Icons.assignment_ind,
                  iconColor: Colors.orange,
                  title: 'Asignaciones de Usuarios',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserAssignmentsListScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _QuickActionButton(
                  icon: Icons.restaurant_menu,
                  iconColor: AppColors.primary,
                  title: 'Crear Nuevo Plan Alimenticio',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateMealPlanScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _QuickActionButton(
                  icon: Icons.fitness_center,
                  title: 'Nueva Rutina de Entrenamiento',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateWorkoutScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChartBars() {
    final labels = ['LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB', 'DOM'];
    final maxSessions = _dailySessions.isEmpty
        ? 1
        : _dailySessions.reduce((a, b) => a > b ? a : b);
    const maxHeight = 160.0;
    final now = DateTime.now();
    final todayIndex = (now.weekday - 1) % 7; // 0 = Lunes, 6 = Domingo

    return List.generate(7, (index) {
      final sessions = _dailySessions[index];
      final height =
          maxSessions > 0 ? (sessions / maxSessions * maxHeight) : 20.0;
      final isToday = index == todayIndex;

      return _ChartBar(
        label: labels[index],
        height: height < 20 ? 20 : height,
        isActive: isToday,
        count: sessions,
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String value;
  final String change;
  final bool isNegative;

  const _StatCard({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.value,
    required this.change,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor ?? Colors.white,
            size: 24,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            change,
            style: TextStyle(
              fontSize: 12,
              color: isNegative ? Colors.red : AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final String label;
  final double height;
  final bool isActive;
  final int count;

  const _ChartBar({
    required this.label,
    required this.height,
    this.isActive = false,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (count > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        Container(
          width: 30,
          height: height,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.white24,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.white).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
