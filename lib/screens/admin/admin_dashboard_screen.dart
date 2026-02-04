import 'package:flutter/material.dart';
import '../../config/theme/app_theme.dart';
import '../meal_plans/create_meal_plan_screen.dart';
import '../workouts/create_workout_screen.dart';
import 'user_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

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
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Activity Summary
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

              const SizedBox(height: 20),

              // Stats Cards
              const Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people,
                      title: 'USUARIOS',
                      value: '1,284',
                      change: '+24%',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.bolt,
                      iconColor: AppColors.primary,
                      title: 'SESIONES',
                      value: '452',
                      change: '-20.3%',
                      isNegative: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Chart
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _ChartBar(label: 'LUN', height: 80, isActive: false),
                    _ChartBar(label: 'MAR', height: 120, isActive: false),
                    _ChartBar(label: 'MIE', height: 160, isActive: true),
                    _ChartBar(label: 'JUE', height: 100, isActive: false),
                    _ChartBar(label: 'VIE', height: 140, isActive: false),
                    _ChartBar(label: 'SAB', height: 70, isActive: false),
                    _ChartBar(label: 'DOM', height: 50, isActive: false),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Quick Actions
              const Text(
                'GESTIÓN RÁPIDA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 16),

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

              const SizedBox(height: 12),

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

              const SizedBox(height: 12),

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

              const SizedBox(height: 32),

              // Recent Plans
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PLANES RECIENTES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Ver todos',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _RecentPlanCard(
                imageUrl: '',
                title: 'Definición Pro - Keto',
                subtitle: 'Plan nutricional',
                onTap: () {},
              ),

              const SizedBox(height: 12),

              _RecentPlanCard(
                imageUrl: '',
                title: 'Hipertrofia Nivel 3',
                subtitle: 'Programa de entrenamiento',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.background, width: 1),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomNavItem(
                icon: Icons.grid_view, label: 'Panel', isActive: true),
            _BottomNavItem(icon: Icons.restaurant_menu, label: 'Planes'),
            _BottomNavItem(icon: Icons.fitness_center, label: 'Rutinas'),
            _BottomNavItem(icon: Icons.bar_chart, label: 'Métricas'),
            _BottomNavItem(icon: Icons.person, label: 'Ajustes'),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor ?? Colors.white,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
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

  const _ChartBar({
    required this.label,
    required this.height,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: height,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.white24,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.white).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentPlanCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RecentPlanCard({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.fastfood,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
