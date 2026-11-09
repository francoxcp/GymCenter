import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/utils/app_validators.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../config/supabase_config.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/services/secure_screen_service.dart';
import '../../../shared/navigation/safe_pop.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

/// Vacío o 7–20 dígitos/espacios con + opcional (igual que el CHECK de la BD).
bool validPhone(String? v) {
  final t = (v ?? '').trim();
  return t.isEmpty || RegExp(r'^\+?[0-9 ]{7,20}$').hasMatch(t);
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedLevel = 'Principiante';
  bool _isLoading = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    SecureScreenService.enable();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';
      _selectedLevel = user.level;
    }
  }

  @override
  void dispose() {
    SecureScreenService.disable();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    try {
      if (userId == null) throw Exception('Usuario no autenticado');

      final name = AppValidators.sanitize(_nameController.text, maxLength: 100);
      if (AppValidators.hasInjectionRisk(name)) {
        AppSnackbar.error(context, 'Nombre no válido');
        return;
      }

      final phone = _phoneController.text.trim();
      await SupabaseConfig.client.from('users').update({
        'name': name,
        'level': _selectedLevel,
        'phone': phone.isEmpty ? null : phone,
      }).eq('id', userId);

      await authProvider.refreshUser();

      if (mounted) {
        HapticFeedback.mediumImpact();
        AppSnackbar.success(context, AppL10n.of(context).profileUpdated);
        context.popOrGo('/profile');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
            context, AppL10n.of(context).errorSaving(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.currentUser;
        final hasChanges = _nameController.text != (user?.name ?? '') ||
            _phoneController.text.trim() != (user?.phone ?? '') ||
            _selectedLevel != (user?.level ?? 'Principiante');

        if (!hasChanges) {
          if (context.mounted) context.popOrGo('/profile');
          return;
        }

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppL10n.of(context).discardChangesTitle),
            content: Text(
              AppL10n.of(context).discardProfileBody,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppL10n.of(context).cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(AppL10n.of(context).exitLabel),
              ),
            ],
          ),
        );

        if (shouldPop == true && context.mounted) {
          context.popOrGo('/profile');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(AppL10n.of(context).editProfile),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto de perfil
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.cardBackground,
                          border:
                              Border.all(color: AppColors.primaryText, width: 3),
                        ),
                        child: currentUser?.photoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  currentUser!.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.person,
                                    size: 60,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.textSecondary,
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _handleProfilePhotoChange,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: _isUploadingPhoto
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.textPrimary,
                                    ),
                                  )
                                : Icon(
                                    Icons.camera_alt,
                                    color: AppColors.textPrimary,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Información personal
                Text(
                  AppL10n.of(context).personalInfo,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _nameController,
                  hintText: AppL10n.of(context).fullName,
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppL10n.of(context).enterYourName;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _phoneController,
                  hintText: AppL10n.of(context).isEn
                      ? 'WhatsApp (optional)'
                      : 'WhatsApp (opcional)',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => validPhone(v)
                      ? null
                      : (AppL10n.of(context).isEn
                          ? 'Digits only, e.g. 8888 8888'
                          : 'Solo números, ej.: 8888 8888'),
                ),
                const SizedBox(height: 16),

                Text(
                  'Email: ${currentUser?.email}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Nivel de entrenamiento
                Text(
                  AppL10n.of(context).trainingLevelSection,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                _buildLevelSelector(),
                const SizedBox(height: 16),

                // Tip: medidas corporales disponibles en sección aparte
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primaryText.withValues(alpha: 0.25),
                        width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.straighten,
                          color: AppColors.primaryText, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppL10n.of(context).bodyMeasurementsTip,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Botón cambiar contraseña
                OutlinedButton(
                  onPressed: () => context.push('/change-password'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryText),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, color: AppColors.primaryText),
                      const SizedBox(width: 8),
                      Text(
                        AppL10n.of(context).changePassword,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Botón guardar
                PrimaryButton(
                  text: AppL10n.of(context).saveChanges,
                  onPressed: _isLoading ? null : _saveProfile,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        return Expanded(
          child: GestureDetector(
            onTap: () =>
                setState(() => _selectedLevel = level['name'] as String),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? (level['color'] as Color).withValues(alpha: 0.2)
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? (level['color'] as Color)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Text(
                level['name'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Manejar cambio de foto de perfil
  Future<void> _handleProfilePhotoChange() async {
    final ImagePicker picker = ImagePicker();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Mostrar opciones
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(AppL10n.of(context).takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppL10n.of(context).galleryLabel),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: Text(AppL10n.of(context).cancel),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      // Seleccionar imagen
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() => _isUploadingPhoto = false);
        return;
      }

      // Validar formato de imagen
      // En web (iPhone/Android) el nombre del archivo puede no traer
      // extensión: se acepta si el tipo MIME es una imagen soportada.
      final extension = image.name.contains('.')
          ? image.name.split('.').last.toLowerCase()
          : '';
      final mime = (image.mimeType ?? '').toLowerCase();
      const allowedMimes = {'image/jpeg', 'image/png', 'image/webp'};
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension) &&
          !(kIsWeb && allowedMimes.contains(mime))) {
        setState(() => _isUploadingPhoto = false);
        if (!mounted) return;
        AppSnackbar.error(context, AppL10n.of(context).unsupportedFormat);
        return;
      }

      // Validar tamaño (máx 5 MB)
      final fileSize = await image.length();
      if (fileSize > 5 * 1024 * 1024) {
        setState(() => _isUploadingPhoto = false);
        if (!mounted) return;
        AppSnackbar.error(context, AppL10n.of(context).imageTooLarge);
        return;
      }

      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final storageService = StorageService();

      // Subir según plataforma
      String? photoUrl;
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        photoUrl = await storageService.uploadProfilePhoto(
          userId: userId,
          imageBytes: bytes,
        );
      } else {
        final file = File(image.path);
        photoUrl = await storageService.uploadProfilePhoto(
          userId: userId,
          imageFile: file,
        );
      }

      if (photoUrl != null) {
        // Guardar URL en la tabla users
        await SupabaseConfig.client
            .from('users')
            .update({'photo_url': photoUrl}).eq('id', userId);

        // Actualizar estado local
        authProvider.updateUser(
          authProvider.currentUser!.copyWith(photoUrl: photoUrl),
        );

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content:
                Text(mounted ? AppL10n.of(context).profilePhotoUpdated : ''),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al cambiar foto: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(mounted
              ? AppL10n.of(context).errorUploadingPhoto(e.toString())
              : e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploadingPhoto = false);
    }
  }
}
