import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/providers/user_provider.dart';
import '../../auth/models/user.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import 'assign_plans_screen.dart';

class UserAssignmentsListScreen extends StatefulWidget {
  const UserAssignmentsListScreen({super.key});

  @override
  State<UserAssignmentsListScreen> createState() =>
      _UserAssignmentsListScreenState();
}

class _UserAssignmentsListScreenState extends State<UserAssignmentsListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar usuarios al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              'Asignaciones de Usuarios',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: userProvider.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Buscar usuario...',
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

              // Info Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Toca un usuario para ver o editar sus asignaciones',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // User List
              Expanded(
                child: userProvider.isLoading
                    ? ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 10,
                        itemBuilder: (context, index) =>
                            const ShimmerListTile(),
                      )
                    : userProvider.filteredUsers.isEmpty
                        ? const Center(
                            child: Text(
                              'No se encontraron usuarios',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: userProvider.filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = userProvider.filteredUsers[index];
                              // Solo mostrar usuarios normales (no admins)
                              if (user.role == 'admin') {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _UserAssignmentCard(
                                  user: user,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AssignPlansScreen(user: user),
                                      ),
                                    );
                                    // Recargar usuarios después de asignar
                                    userProvider.loadUsers();
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UserAssignmentCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const _UserAssignmentCard({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (user.assignedWorkoutId != null)
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rutina asignada:',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('Nombre: ...'), // TODO: fetch workout name
                        Text(
                            'Descripción: ...'), // TODO: fetch workout description
                        Text('Duración: ...'), // TODO: fetch workout duration
                        Text(
                            'Ejercicios: ...'), // TODO: fetch workout exercises
                        SizedBox(height: 8),
                      ],
                    ),
                  if (user.assignedMealPlanId != null)
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Plan de alimentación asignado:',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('Nombre: ...'), // TODO: fetch meal plan name
                        Text(
                            'Descripción: ...'), // TODO: fetch meal plan description
                        Text('Días: ...'), // TODO: fetch meal plan days
                        Text('Comidas: ...'), // TODO: fetch meal plan meals
                        SizedBox(height: 8),
                      ],
                    ),
                  const Text('Estado: Activa'), // TODO: fetch assignment state
                ],
              ),
            );
          },
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 25,
              child: Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (user.assignedWorkoutId != null) ...[
                        const SizedBox(
                          width: 0,
                          child: null,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (user.assignedMealPlanId != null)
                        const SizedBox(
                          width: 0,
                          child: null,
                        ),
                      if (user.assignedWorkoutId == null &&
                          user.assignedMealPlanId == null)
                        const Text(
                          'Sin asignaciones',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onSelected: (value) async {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssignPlansScreen(user: user),
                    ),
                  ).then((_) {
                    // Recargar usuarios después de editar
                    Provider.of<UserProvider>(context, listen: false)
                        .loadUsers();
                  });
                } else if (value == 'remove') {
                  final userProvider =
                      Provider.of<UserProvider>(context, listen: false);
                  // Limpiar asignaciones en users y user_workout_schedule
                  await userProvider.clearUserAssignments(user.id);
                  if (!context.mounted) return;
                  // Recargar usuarios antes de mostrar el mensaje
                  userProvider.loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Asignaciones eliminadas'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Editar asignaciones'),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Quitar asignación'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
