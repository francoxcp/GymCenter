import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../config/supabase_config.dart';
import '../../../shared/services/storage_service.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedLevel = 'Principiante';
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _nameController.addListener(_onFieldChanged);
  }

  void _loadUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _selectedLevel = user.level;
    }
  }

  void _onFieldChanged() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final changed = _nameController.text.trim() != auth.currentUser?.name ||
        _selectedLevel != auth.currentUser?.level;
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _nameController.dispose();
    super.dispose();
  }

  Color _getLevelColor(String level) {
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

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    try {
      if (userId == null) throw Exception('Usuario no autenticado');

      await SupabaseConfig.client.from('users').update({
        'name': _nameController.text.trim(),
        'level': _selectedLevel,
      }).eq('id', userId);

      await authProvider.refreshUser();
      setState(() => _hasChanges = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppL10n.of(context).profileUpdated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppL10n.of(context).errorSavingMsg(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleProfilePhotoChange() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.white),
              title: Text(AppL10n.of(context).takePhoto, style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: Text(AppL10n.of(context).galleryLabel, style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: AppColors.textSecondary),
              title: Text(AppL10n.of(context).cancel, style: const TextStyle(color: AppColors.textSecondary)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    setState(() => _isUploadingPhoto = true);
    // ignore: use_build_context_synchronously
    final messenger = ScaffoldMessenger.of(context);
    // ignore: use_build_context_synchronously
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image == null) return;

      final userId = authProvider.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final storageService = StorageService();
      String? photoUrl;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        photoUrl = await storageService.uploadProfilePhoto(userId: userId, imageBytes: bytes);
      } else {
        final file = File(image.path);
        photoUrl = await storageService.uploadProfilePhoto(userId: userId, imageFile: file);
      }

      if (photoUrl != null) {
        await SupabaseConfig.client
            .from('users')
            .update({'photo_url': photoUrl}).eq('id', userId);

        authProvider.updateUser(authProvider.currentUser!.copyWith(photoUrl: photoUrl));

        messenger.showSnackBar(
          SnackBar(content: Text(AppL10n.of(context).photoUpdated), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${AppL10n.of(context).uploadPhotoError}: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Widget _buildLevelSelector() {
    final levels = [
      {'name': 'Principiante', 'color': AppColors.badgePrincipiante},
      {'name': 'Intermedio', 'color': AppColors.badgeIntermedio},
      {'name': 'Avanzado', 'color': AppColors.badgeAvanzado},
    ];

    return Row(
      children: levels.map((level) {
        final isSelected = _selectedLevel == level['name'];
        final col = level['color'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedLevel = level['name'] as String);
              _onFieldChanged();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: isSelected ? col.withOpacity(0.2) : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? col : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Text(
                level['name'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppL10n.of(context).myProfile)),
        body: Center(
          child: Text(AppL10n.of(context).noAuthUser, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    // ...variables eliminadas porque ya no se usan...

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Text(AppL10n.of(context).myProfile),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cabecera: foto + campos editables ──────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Foto de perfil
                      Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 3),
                              color: AppColors.background,
                            ),
                            child: currentUser.photoUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      currentUser.photoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          _getInitials(currentUser.name),
                                          style: const TextStyle(
                                            fontSize: 38,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      _getInitials(currentUser.name),
                                      style: const TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploadingPhoto ? null : _handleProfilePhotoChange,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: _isUploadingPhoto
                                    ? const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Icon(Icons.camera_alt, color: Colors.black, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        currentUser.email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Campo nombre editable
                      CustomTextField(
                        controller: _nameController,
                        hintText: 'Nombre completo',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa tu nombre';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Selector de nivel
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppL10n.of(context).trainingLevel,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary.withOpacity(0.8),
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildLevelSelector(),

                      const SizedBox(height: 20),

                      // Botón guardar — aparece solo cuando hay cambios
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _hasChanges
                            ? PrimaryButton(
                                key: const ValueKey('save-btn'),
                                text: AppL10n.of(context).saveChanges,
                                onPressed: _isSaving ? null : _saveProfile,
                                isLoading: _isSaving,
                              )
                            : const SizedBox.shrink(key: ValueKey('no-btn')),
                      ),
                    ],
                  ),
                ),

                // ── Menú ─────────────────────────────────────────────────
                _MenuItem(
                  icon: Icons.history,
                  title: AppL10n.of(context).workoutHistoryMenu,
                  onTap: () => context.push('/workout-history'),
                ),
                const SizedBox(height: 10),
                _MenuItem(
                  icon: Icons.show_chart,
                  title: AppL10n.of(context).myProgress,
                  onTap: () => context.push('/progress'),
                ),
                const SizedBox(height: 10),
                _MenuItem(
                  icon: Icons.straighten,
                  title: AppL10n.of(context).bodyMeasurementsLabel,
                  onTap: () => context.push('/body-measurements'),
                ),
                const SizedBox(height: 10),
                _MenuItem(
                  icon: Icons.lock_outline,
                  title: AppL10n.of(context).changePasswordMenu,
                  onTap: () => context.push('/change-password'),
                ),
                const SizedBox(height: 10),
                _MenuItem(
                  icon: Icons.settings,
                  title: AppL10n.of(context).configurationMenu,
                  onTap: () => context.push('/settings'),
                ),

                const SizedBox(height: 32),

                // ── Cerrar sesión ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final auth = context.read<AuthProvider>();
                      await auth.logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: Text(
                      AppL10n.of(context).logOutLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSpecialtiesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Especialidades',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Fuerza
              _buildSpecialtyItem(
                icon: Icons.fitness_center,
                color: Colors.red,
                title: 'Fuerza',
                description:
                    'Entrenamiento enfocado en aumentar la fuerza máxima mediante ejercicios compuestos con pesos pesados y bajas repeticiones. Ideal para desarrollar potencia y masa muscular.',
              ),

              const SizedBox(height: 16),

              // Volumen
              _buildSpecialtyItem(
                icon: Icons.trending_up,
                color: Colors.blue,
                title: 'Volumen',
                description:
                    'Rutinas diseñadas para hipertrofia muscular con mayor cantidad de series y repeticiones moderadas. Perfecto para quienes buscan aumentar el tamaño muscular.',
              ),

              const SizedBox(height: 16),

              // Resistencia
              _buildSpecialtyItem(
                icon: Icons.timer,
                color: Colors.green,
                title: 'Resistencia',
                description:
                    'Programas de alta intensidad con descansos cortos para mejorar la capacidad cardiovascular y la resistencia muscular. Combina fuerza con acondicionamiento físico.',
              ),

              const SizedBox(height: 20),

              // Nota informativa
              Container(
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
                        'Estas especialidades definen el enfoque de tus rutinas de entrenamiento.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialtyItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 28,
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
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
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
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
