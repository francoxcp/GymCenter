import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../profile/providers/user_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user.dart';
import '../../../shared/widgets/shimmer_loading.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  String _filterRole = 'all';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ADMIN PORTAL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              AppL10n.of(context).userManagement,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);
              userProvider.loadUsers();
              AppSnackbar.info(context, AppL10n.of(context).reloadingUsers);
            },
            tooltip: AppL10n.of(context).reloadUsersTooltip,
          ),
        ],
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
                    hintText: AppL10n.of(context).search,
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
                    _FilterChip(
                      label: AppL10n.of(context).filterAll,
                      isSelected: _filterRole == 'all',
                      onTap: () => setState(() => _filterRole = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: AppL10n.of(context).filterAdmins,
                      isSelected: _filterRole == 'admin',
                      onTap: () => setState(() => _filterRole = 'admin'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: AppL10n.of(context).filterUsers,
                      isSelected: _filterRole == 'user',
                      onTap: () => setState(() => _filterRole = 'user'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Stats Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people,
                        label: AppL10n.of(context).totalUsersLabel,
                        value: userProvider.users.length.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.admin_panel_settings,
                        label: AppL10n.of(context).administratorsLabel,
                        value: userProvider.users
                            .where((u) => u.role == 'admin')
                            .length
                            .toString(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Users List
              Expanded(
                child: userProvider.isLoading
                    ? ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 10,
                        itemBuilder: (context, index) =>
                            const ShimmerListTile(),
                      )
                    : _buildUsersList(userProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUsersList(UserProvider userProvider) {
    List<User> users = userProvider.filteredUsers;

    // Apply role filter
    if (_filterRole != 'all') {
      users = users.where((u) => u.role == _filterRole).toList();
    }

    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_off,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                userProvider.searchQuery.isEmpty && _filterRole == 'all'
                    ? AppL10n.of(context).noRegisteredUsers
                    : AppL10n.of(context).noUsersFound,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userProvider.searchQuery.isNotEmpty
                    ? AppL10n.of(context).tryAnotherSearch
                    : _filterRole != 'all'
                        ? AppL10n.of(context).noUsersWithRole
                        : AppL10n.of(context).usersWillAppear,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(AppL10n.of(context).reloadLabel),
                onPressed: () {
                  Provider.of<UserProvider>(context, listen: false).loadUsers();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _UserCard(
          user: user,
          onTap: () => _showUserOptions(user),
        );
      },
    );
  }

  void _showUserOptions(User user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: Text(AppL10n.of(context).editUserLabel),
                onTap: () {
                  Navigator.pop(context);
                  _showEditUserDialog(user);
                },
              ),
              if (user.id != currentUserId)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings,
                      color: Colors.orange),
                  title: Text(user.role == 'admin'
                      ? AppL10n.of(context).removeAdmin
                      : AppL10n.of(context).makeAdmin),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleAdminRole(user);
                  },
                ),
              if (user.id != currentUserId)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(AppL10n.of(context).deleteUser,
                      style: const TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteUser(user);
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showEditUserDialog(User user) {
    final nameController = TextEditingController(text: user.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(AppL10n.of(context).editUser),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: AppL10n.of(context).nameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppL10n.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);
              try {
                await userProvider.updateUser(
                  user.id,
                  name: nameController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  AppSnackbar.success(context, AppL10n.of(context).userUpdated);
                }
              } catch (e) {
                if (context.mounted) {
                  AppSnackbar.error(context, 'Error: $e');
                }
              }
            },
            child: Text(AppL10n.of(context).save),
          ),
        ],
      ),
    ).then((_) {
      nameController.dispose();
    });
  }

  bool _isProcessing = false;

  void _toggleAdminRole(User user) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final newRole = user.role == 'admin' ? 'user' : 'admin';

    try {
      await userProvider.updateUser(user.id, role: newRole);
      if (mounted) {
        final l10n = AppL10n.of(context);
        AppSnackbar.success(
          context,
          newRole == 'admin'
              ? l10n.userNowAdmin(user.name)
              : l10n.adminRemovedFrom(user.name),
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _confirmDeleteUser(User user) {
    showDialog(
      context: context,
      builder: (context) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: Text(AppL10n.of(context).confirmDeletion),
            content: Text(
              AppL10n.of(context).confirmDeleteUser(user.name),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(context),
                child: Text(AppL10n.of(context).cancel),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setState(() => isDeleting = true);
                        final userProvider =
                            Provider.of<UserProvider>(context, listen: false);
                        try {
                          await userProvider.deleteUser(user.id);
                          if (context.mounted) {
                            Navigator.pop(context);
                            AppSnackbar.success(
                                context, AppL10n.of(context).userDeleted);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            AppSnackbar.error(context, 'Error: $e');
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(AppL10n.of(context).deleteLabel),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(
            user.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              user.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (user.role == 'admin') ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              AppL10n.of(context)
                  .levelAndWorkoutsInfo(user.level, user.completedWorkouts),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.more_vert, color: AppColors.primary),
      ),
    );
  }
}
