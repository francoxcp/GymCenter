import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../shared/widgets/app_snackbar.dart';
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
  Timer? _debounce;

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
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.adminPortal,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              l10n.userAssignmentsTitle,
              style: const TextStyle(
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
                  onChanged: (query) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      userProvider.setSearchQuery(query);
                    });
                  },
                  decoration: InputDecoration(
                    hintText: l10n.search,
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
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppL10n.of(context).assignHint,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
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
                        ? Center(
                            child: Text(
                              AppL10n.of(context).noUsersFound,
                              style: const TextStyle(
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

  const _UserAssignmentCard({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return InkWell(
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
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
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
                  if (user.assignedWorkoutId == null)
                    Text(
                      l10n.noAssignedRoutine,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.routineAssigned,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onSelected: (value) async {
                if (value == 'schedule') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssignPlansScreen(user: user),
                    ),
                  ).then((_) {
                    if (!context.mounted) return;
                    Provider.of<UserProvider>(context, listen: false)
                        .loadUsers();
                  });
                } else if (value == 'remove') {
                  final userProvider =
                      Provider.of<UserProvider>(context, listen: false);
                  try {
                    await userProvider.clearUserAssignments(user.id);
                    if (!context.mounted) return;
                    await userProvider.loadUsers();
                    if (!context.mounted) return;
                    final l10n = AppL10n.of(context);
                    AppSnackbar.info(context, l10n.routineDeleted);
                  } catch (e) {
                    if (!context.mounted) return;
                    AppSnackbar.error(context,
                        AppL10n.of(context).errorDeletingRoutine(e.toString()));
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'schedule',
                  child: Row(
                    children: [
                      Icon(
                        user.assignedWorkoutId == null
                            ? Icons.add_circle_outline
                            : Icons.edit,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user.assignedWorkoutId == null
                            ? l10n.addRoutine
                            : l10n.editRoutineMenu,
                      ),
                    ],
                  ),
                ),
                if (user.assignedWorkoutId != null)
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline,
                            size: 18, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Text(l10n.removeRoutine,
                            style: const TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
