import 'package:flutter/material.dart';
import '../../../shared/web/web_bridge.dart';
import '../../../shared/widgets/install_guide_sheet.dart';
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
import '../../../shared/widgets/app_snackbar.dart';
import '../widgets/trainer_link_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
    }
  }

  void _onFieldChanged() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final changed = _nameController.text.trim() != auth.currentUser?.name;
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _nameController.dispose();
    super.dispose();
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
      }).eq('id', userId);

      await authProvider.refreshUser();
      if (!mounted) return;
      setState(() => _hasChanges = false);
      AppSnackbar.success(context, AppL10n.of(context).profileUpdated);
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
            context, AppL10n.of(context).errorSavingMsg(e.toString()));
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
              leading: Icon(Icons.photo_camera, color: AppColors.textPrimary),
              title: Text(AppL10n.of(context).takePhoto,
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.textPrimary),
              title: Text(AppL10n.of(context).galleryLabel,
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.cancel, color: AppColors.textSecondary),
              title: Text(AppL10n.of(context).cancel,
                  style: TextStyle(color: AppColors.textSecondary)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppL10n.of(context);
    setState(() => _isUploadingPhoto = true);

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
        photoUrl = await storageService.uploadProfilePhoto(
            userId: userId, imageBytes: bytes);
      } else {
        final file = File(image.path);
        photoUrl = await storageService.uploadProfilePhoto(
            userId: userId, imageFile: file);
      }

      if (photoUrl != null) {
        await SupabaseConfig.client
            .from('users')
            .update({'photo_url': photoUrl}).eq('id', userId);

        authProvider
            .updateUser(authProvider.currentUser!.copyWith(photoUrl: photoUrl));

        if (mounted) {
          AppSnackbar.success(context, l10n.photoUpdated);
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, '${l10n.uploadPhotoError}: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppL10n.of(context).myProfile)),
        body: Center(
          child: Text(AppL10n.of(context).noAuthUser,
              style: TextStyle(color: AppColors.textPrimary)),
        ),
      );
    }

    // ...variables eliminadas porque ya no se usan...

    final l10n = AppL10n.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.goBackTooltip,
          onPressed: () => context.go('/home'),
        ),
        title: Text(l10n.myProfile),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -- Cabecera: foto + campos editables ------------------
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
                              border: Border.all(
                                  color: AppColors.primaryText, width: 3),
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
                                          style: TextStyle(
                                            fontSize: 38,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryText,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      _getInitials(currentUser.name),
                                      style: TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploadingPhoto
                                  ? null
                                  : _handleProfilePhotoChange,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: _isUploadingPhoto
                                    ? Padding(
                                        padding: EdgeInsets.all(8),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Icon(Icons.camera_alt,
                                        color: Colors.black, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        currentUser.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Campo nombre editable
                      CustomTextField(
                        controller: _nameController,
                        hintText: l10n.fullName,
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.enterYourName;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

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

                const SizedBox(height: 16),

                // -- Menú -------------------------------------------------
                _MenuItem(
                  icon: Icons.emoji_events_outlined,
                  title: l10n.personalRecords,
                  onTap: () => context.push('/personal-records'),
                ),
                const SizedBox(height: 10),
                if (kIsWeb && !WebBridge.isStandalone) ...[
                  _MenuItem(
                    icon: Icons.install_mobile,
                    title: 'Instalar la app',
                    onTap: () => showInstallGuide(context),
                  ),
                  const SizedBox(height: 10),
                ],
                _MenuItem(
                  icon: Icons.history,
                  title: AppL10n.of(context).workoutHistoryMenu,
                  onTap: () => context.push('/workout-history'),
                ),
                const SizedBox(height: 10),
                // Los socios ya tienen Progreso en la barra inferior
                if (context.read<AuthProvider>().isStaff) ...[
                  _MenuItem(
                    icon: Icons.show_chart,
                    title: AppL10n.of(context).myProgress,
                    onTap: () => context.push('/progress'),
                  ),
                  const SizedBox(height: 10),
                ],
                // Vínculo con el entrenador (socio) o código (entrenador)
                const TrainerLinkCard(),
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

                // -- Cerrar sesión -----------------------------------------
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final auth = context.read<AuthProvider>();
                      await auth.logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: Icon(Icons.logout, color: Colors.red),
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
                      side: BorderSide(color: Colors.red),
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
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
