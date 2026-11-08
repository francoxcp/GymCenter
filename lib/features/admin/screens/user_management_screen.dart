import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../shared/widgets/app_snackbar.dart';
import 'member_hub_screen.dart' show showResetPasswordDialog;
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
            Text(
              AppL10n.of(context).adminPortal,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              AppL10n.of(context).userManagement,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateMemberDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(AppL10n.of(context).isEn ? 'New member' : 'Nuevo socio'),
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
                    prefixIcon: Icon(
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: AppL10n.of(context).filterAll,
                      isSelected: _filterRole == 'all',
                      onTap: () => setState(() => _filterRole = 'all'),
                    ),
                    const SizedBox(width: 8),
                    if (!context.read<AuthProvider>().isIndependent) ...[
                    _FilterChip(
                      label: AppL10n.of(context).filterAdmins,
                      isSelected: _filterRole == 'admin',
                      onTap: () => setState(() => _filterRole = 'admin'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: AppL10n.of(context).isEn ? 'Trainers' : 'Entrenadores',
                      isSelected: _filterRole == 'trainer',
                      onTap: () => setState(() => _filterRole = 'trainer'),
                    ),
                    const SizedBox(width: 8),
                    ],
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
                    if (!context.read<AuthProvider>().isIndependent) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.sports,
                        label: AppL10n.of(context).isEn ? 'Trainers' : 'Entrenadores',
                        value: userProvider.users
                            .where((u) => u.role == 'trainer')
                            .length
                            .toString(),
                      ),
                    ),
                    ],
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
    final trainerNames = {
      for (final u in userProvider.users)
        if (u.role == 'trainer' || u.role == 'admin') u.id: u.name,
    };

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
              Icon(
                Icons.person_off,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                userProvider.searchQuery.isEmpty && _filterRole == 'all'
                    ? AppL10n.of(context).noRegisteredUsers
                    : AppL10n.of(context).noUsersFound,
                style: TextStyle(
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
                style: TextStyle(
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
          trainerName: trainerNames[user.trainerId],
          onTap: () => _showUserOptions(user),
        );
      },
    );
  }

  void _showUserOptions(User user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    final isOwner = authProvider.isAdmin;
    // Entrenador independiente: no hay entrenadores ni otros dueños
    final manageRoles = isOwner && !authProvider.isIndependent;
    final isEn = AppL10n.of(context).isEn;

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
                leading: Icon(Icons.insights, color: AppColors.primaryText),
                title: Text(AppL10n.of(context).isEn
                    ? 'Training control'
                    : 'Control de entrenamiento'),
                onTap: () {
                  Navigator.pop(context);
                  this.context.push(
                      '/admin/user-progress/${user.id}?name=${Uri.encodeQueryComponent(user.name)}');
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text(AppL10n.of(context).editUserLabel),
                onTap: () {
                  Navigator.pop(context);
                  _showEditUserDialog(user);
                },
              ),
              // Contraseña temporal (el correo gratuito no llega a los socios)
              if (user.id != currentUserId &&
                  user.role != 'admin' &&
                  (isOwner || user.trainerId == currentUserId))
                ListTile(
                  leading: Icon(Icons.lock_reset, color: AppColors.primaryText),
                  title: Text(isEn ? 'Reset password' : 'Restablecer contraseña'),
                  subtitle: Text(
                    isEn ? 'Also activates the account' : 'También activa la cuenta',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    showResetPasswordDialog(this.context, user);
                  },
                ),
              // ── Solo el dueño gestiona roles y entrenadores ──
              if (manageRoles && user.role == 'user')
                ListTile(
                  leading: Icon(Icons.sports, color: AppColors.primaryText),
                  title: Text(isEn ? 'Assign trainer' : 'Asignar entrenador'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAssignTrainerDialog(user);
                  },
                ),
              if (manageRoles && user.id != currentUserId && user.role != 'admin')
                ListTile(
                  leading: Icon(Icons.sports_gymnastics,
                      color: Colors.lightBlueAccent),
                  title: Text(user.role == 'trainer'
                      ? (isEn ? 'Remove trainer role' : 'Quitar rol de entrenador')
                      : (isEn ? 'Make trainer' : 'Hacer entrenador')),
                  onTap: () {
                    Navigator.pop(context);
                    _setRole(user, user.role == 'trainer' ? 'user' : 'trainer');
                  },
                ),
              if (manageRoles && user.id != currentUserId)
                ListTile(
                  leading: Icon(Icons.admin_panel_settings,
                      color: Colors.orange),
                  title: Text(user.role == 'admin'
                      ? (isEn ? 'Remove owner role' : 'Quitar rol de dueño')
                      : (isEn ? 'Make owner (full access)' : 'Hacer dueño (acceso total)')),
                  onTap: () {
                    Navigator.pop(context);
                    _setRole(user, user.role == 'admin' ? 'user' : 'admin');
                  },
                ),
              if (isOwner && user.id != currentUserId)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text(AppL10n.of(context).deleteUser,
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
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(AppL10n.of(dialogContext).editUser),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: AppL10n.of(dialogContext).nameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppL10n.of(dialogContext).cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final userProvider =
                  Provider.of<UserProvider>(dialogContext, listen: false);
              try {
                await userProvider.updateUser(
                  user.id,
                  name: nameController.text,
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) {
                  AppSnackbar.success(context, AppL10n.of(context).userUpdated);
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  AppSnackbar.error(dialogContext,
                      AppL10n.of(dialogContext).genericError(e.toString()));
                }
              }
            },
            child: Text(AppL10n.of(dialogContext).save),
          ),
        ],
      ),
    ).then((_) {
      nameController.dispose();
    });
  }

  bool _isProcessing = false;

  Future<void> _setRole(User user, String newRole) async {
    if (_isProcessing) return;
    final isEn = AppL10n.of(context).isEn;
    // Dar acceso total requiere confirmación explícita
    if (newRole == 'admin') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text(isEn ? 'Give full access?' : '¿Dar acceso total?'),
          content: Text(isEn
              ? '${user.name} will be able to see and manage ALL members, trainers and routines, and change roles.'
              : '${user.name} podrá ver y gestionar a TODOS los socios, entrenadores y rutinas, y cambiar roles.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppL10n.of(ctx).cancel)),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(isEn ? 'Yes, make owner' : 'Sí, hacer dueño')),
          ],
        ),
      );
      if (ok != true) return;
    }
    if (!mounted) return;
    setState(() => _isProcessing = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      await userProvider.updateUser(user.id, role: newRole);
      if (mounted) {
        final label = switch (newRole) {
          'admin' => isEn ? 'owner' : 'dueño',
          'trainer' => isEn ? 'trainer' : 'entrenador',
          _ => isEn ? 'member' : 'socio',
        };
        AppSnackbar.success(
            context, isEn ? '${user.name} is now $label' : '${user.name} ahora es $label');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
            context, AppL10n.of(context).genericError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// El dueño asigna (o quita) el entrenador de un socio.
  void _showAssignTrainerDialog(User user) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isEn = AppL10n.of(context).isEn;
    final trainers = userProvider.users
        .where((u) => u.role == 'trainer' || u.role == 'admin')
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                isEn ? 'Trainer for ${user.name}' : 'Entrenador de ${user.name}',
                style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person_off_outlined,
                  color: AppColors.textSecondary),
              title: Text(isEn ? 'No trainer' : 'Sin entrenador'),
              trailing: user.trainerId == null
                  ? Icon(Icons.check, color: AppColors.primaryText)
                  : null,
              onTap: () => _assignTrainer(ctx, user, null),
            ),
            ...trainers.map((t) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  title: Text(t.name),
                  subtitle: Text(
                      t.role == 'admin'
                          ? (isEn ? 'Owner' : 'Dueño')
                          : (isEn ? 'Trainer' : 'Entrenador'),
                      style: TextStyle(color: AppColors.textSecondary)),
                  trailing: user.trainerId == t.id
                      ? Icon(Icons.check, color: AppColors.primaryText)
                      : null,
                  onTap: () => _assignTrainer(ctx, user, t.id),
                )),
            if (trainers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  isEn
                      ? 'There are no trainers yet. Use "Make trainer" on a user first.'
                      : 'Aún no hay entrenadores. Primero usa "Hacer entrenador" en un usuario.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignTrainer(
      BuildContext sheetContext, User user, String? trainerId) async {
    Navigator.pop(sheetContext);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      await userProvider.assignTrainer(user.id, trainerId);
      if (mounted) {
        AppSnackbar.success(
            context,
            AppL10n.of(context).isEn
                ? 'Trainer updated'
                : 'Entrenador actualizado');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
            context, AppL10n.of(context).genericError(e.toString()));
      }
    }
  }

  /// Alta de socio por un entrenador o el dueño (Edge Function create-member).
  void _showCreateMemberDialog() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isEn = AppL10n.of(context).isEn;
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final trainers = userProvider.users
        .where((u) => u.role == 'trainer' || u.role == 'admin')
        .toList();
    String? trainerId = auth.isTrainer ? auth.currentUser?.id : null;
    bool saving = false;
    String? error;

    String errorText(String code) {
      switch (code) {
        case 'email_exists':
          return isEn ? 'That email is already registered.' : 'Ese correo ya está registrado.';
        case 'invalid_email':
          return isEn ? 'Invalid email.' : 'Correo no válido.';
        case 'weak_password':
          return isEn ? 'Password must have at least 8 characters.' : 'La contraseña debe tener al menos 8 caracteres.';
        case 'invalid_name':
          return isEn ? 'Enter the member name.' : 'Escribe el nombre del socio.';
        case 'member_limit':
          return isEn
              ? 'Your plan reached its member limit. Contact the platform to upgrade.'
              : 'Tu plan llegó al máximo de socios. Escríbenos para ampliarlo.';
        case 'organization_suspended':
          return isEn ? 'Your account is paused.' : 'Tu cuenta está en pausa por un pago pendiente.';
        default:
          return isEn ? 'Could not create the member.' : 'No se pudo crear el socio.';
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text(isEn ? 'New member' : 'Nuevo socio'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: isEn ? 'Full name' : 'Nombre completo',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: isEn ? 'Email' : 'Correo electrónico',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: isEn ? 'Temporary password' : 'Contraseña temporal',
                    helperText: isEn
                        ? 'Give it to the member; they can change it in Settings.'
                        : 'Dásela al socio; podrá cambiarla en Configuración.',
                    helperMaxLines: 2,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (auth.isAdmin) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    // ignore: deprecated_member_use
                    value: trainerId,
                    decoration: InputDecoration(
                      labelText: isEn ? 'Trainer' : 'Entrenador',
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                          value: null,
                          child: Text(isEn ? 'No trainer' : 'Sin entrenador')),
                      ...trainers.map((t) => DropdownMenuItem<String?>(
                          value: t.id, child: Text(t.name))),
                    ],
                    onChanged: (v) => setDialogState(() => trainerId = v),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: TextStyle(color: AppColors.error)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: Text(AppL10n.of(dialogContext).cancel),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() {
                        saving = true;
                        error = null;
                      });
                      final code = await userProvider.createMember(
                        name: nameCtrl.text,
                        email: emailCtrl.text,
                        password: passCtrl.text,
                        trainerId: trainerId,
                      );
                      if (code == null) {
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (mounted) {
                          AppSnackbar.success(
                              context,
                              isEn
                                  ? 'Member created. Share the email and temporary password.'
                                  : 'Socio creado. Compártele el correo y la contraseña temporal.');
                        }
                      } else {
                        setDialogState(() {
                          saving = false;
                          error = errorText(code);
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEn ? 'Create' : 'Crear'),
            ),
          ],
        ),
      ),
    ).then((_) {
      nameCtrl.dispose();
      emailCtrl.dispose();
      passCtrl.dispose();
    });
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
                            AppSnackbar.error(context,
                                AppL10n.of(context).genericError(e.toString()));
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: isDeleting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
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
          Icon(icon, color: AppColors.primaryText, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
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
  final String? trainerName;

  const _UserCard({
    required this.user,
    required this.onTap,
    this.trainerName,
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
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              user.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (user.role == 'trainer') ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppL10n.of(context).isEn ? 'TRAINER' : 'ENTRENADOR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
            if (user.role == 'admin') ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppL10n.of(context).adminBadge,
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
              style: TextStyle(color: AppColors.textSecondary),
            ),
            if (trainerName != null)
              Text(
                '${AppL10n.of(context).isEn ? 'Trainer' : 'Entrenador'}: $trainerName',
                style: TextStyle(fontSize: 12, color: AppColors.primaryText),
              ),
            const SizedBox(height: 4),
            Text(
              AppL10n.of(context)
                  .levelAndWorkoutsInfo(user.level, user.completedWorkouts),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.more_vert, color: AppColors.primaryText),
      ),
    );
  }
}
