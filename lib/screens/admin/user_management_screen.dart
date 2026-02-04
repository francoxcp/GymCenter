import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import 'assign_plans_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  String _filterRole = 'Todos';

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
              'Gestión de Usuarios',
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
                    hintText: 'Buscar por nombre o email...',
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
                      label: 'Todos',
                      isSelected: _filterRole == 'Todos',
                      onTap: () => setState(() => _filterRole = 'Todos'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Admins',
                      isSelected: _filterRole == 'admin',
                      onTap: () => setState(() => _filterRole = 'admin'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Usuarios',
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
                        label: 'Total Usuarios',
                        value: userProvider.users.length.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.admin_panel_settings,
                        label: 'Administradores',
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
                    ? const Center(child: CircularProgressIndicator())
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
    if (_filterRole != 'Todos') {
      users = users.where((u) => u.role == _filterRole).toList();
    }

    if (users.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron usuarios',
          style: TextStyle(color: AppColors.textSecondary),
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
                leading: const Icon(Icons.assignment, color: AppColors.primary),
                title: const Text('Asignar Planes'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssignPlansScreen(user: user),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Editar Usuario'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditUserDialog(user);
                },
              ),
              if (user.id != currentUserId)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings,
                      color: Colors.orange),
                  title: Text(
                      user.role == 'admin' ? 'Quitar Admin' : 'Hacer Admin'),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleAdminRole(user);
                  },
                ),
              if (user.id != currentUserId)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Eliminar Usuario',
                      style: TextStyle(color: Colors.red)),
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
        title: const Text('Editar Usuario'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Usuario actualizado correctamente')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _toggleAdminRole(User user) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final newRole = user.role == 'admin' ? 'user' : 'admin';

    try {
      await userProvider.updateUser(user.id, role: newRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newRole == 'admin'
                  ? '${user.name} es ahora administrador'
                  : 'Permisos de admin removidos de ${user.name}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _confirmDeleteUser(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de eliminar a ${user.name}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);
              try {
                await userProvider.deleteUser(user.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Usuario eliminado correctamente')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
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
              'Nivel: ${user.level} • ${user.completedWorkouts} entrenamientos',
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
