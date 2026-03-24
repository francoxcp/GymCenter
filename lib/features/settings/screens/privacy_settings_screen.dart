import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../shared/services/biometric_service.dart';
import '../providers/preferences_provider.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final service = BiometricService();
    final available = await service.isAvailable();
    final enabled = await service.isEnabled();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final service = BiometricService();
    if (value) {
      // Verificar identidad antes de activar
      final authenticated = await service.authenticate(
        reason: 'Verifica tu identidad para activar el bloqueo',
      );
      if (!authenticated) return;
    }
    await service.setEnabled(value);
    if (!mounted) return;
    setState(() => _biometricEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final prefsProvider = Provider.of<PreferencesProvider>(context);
    final prefs = prefsProvider.preferences;

    final analyticsEnabled = prefs?.privacyAnalytics ?? true;
    final personalizationEnabled = prefs?.privacyPersonalization ?? true;
    final workoutInsights = prefs?.privacyWorkoutInsights ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.privacy),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.isEn
                        ? 'Your privacy matters. Control how your data is used within the app.'
                        : 'Tu privacidad importa. Controla cómo se usan tus datos dentro de la app.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Security section
          if (_biometricAvailable) ...[
            _buildSectionTitle(l10n.isEn ? 'SECURITY' : 'SEGURIDAD'),
            _buildSwitchTile(
              title: l10n.isEn ? 'Biometric Lock' : 'Bloqueo Biométrico',
              subtitle: l10n.isEn
                  ? 'Require fingerprint or Face ID when opening the app'
                  : 'Requiere huella o Face ID al abrir la app',
              icon: Icons.fingerprint,
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            ),
            const SizedBox(height: 24),
          ],

          // Data usage section
          _buildSectionTitle(l10n.dataUsageSection),
          _buildSwitchTile(
            title: l10n.analyticsTitle,
            subtitle: l10n.analyticsSubtitle,
            icon: Icons.bar_chart_outlined,
            value: analyticsEnabled,
            onChanged: (v) {
              prefsProvider.updatePrivacySetting('privacy_analytics', v);
            },
          ),
          _buildSwitchTile(
            title: l10n.personalizationTitle,
            subtitle: l10n.personalizationSubtitle,
            icon: Icons.tune_outlined,
            value: personalizationEnabled,
            onChanged: (v) {
              prefsProvider.updatePrivacySetting('privacy_personalization', v);
            },
          ),
          _buildSwitchTile(
            title: l10n.workoutInsightsTitle,
            subtitle: l10n.workoutInsightsSubtitle,
            icon: Icons.fitness_center_outlined,
            value: workoutInsights,
            onChanged: (v) {
              prefsProvider.updatePrivacySetting('privacy_workout_insights', v);
            },
          ),
          const SizedBox(height: 24),

          // Your data section
          _buildSectionTitle(l10n.yourDataSection),
          _buildInfoTile(
            title: l10n.whatWeCollectTitle,
            subtitle: l10n.whatWeCollectSubtitle,
            icon: Icons.info_outline,
          ),
          _buildInfoTile(
            title: l10n.howWeStoreTitle,
            subtitle: l10n.howWeStoreSubtitle,
            icon: Icons.lock_outline,
          ),
          _buildInfoTile(
            title: l10n.thirdPartiesTitle,
            subtitle: l10n.thirdPartiesSubtitle,
            icon: Icons.block_outlined,
          ),
          const SizedBox(height: 24),

          // Legal section
          _buildSectionTitle(l10n.legalSection),
          _buildNavTile(
            title: l10n.privacyPolicy,
            subtitle: l10n.privacyPolicySubtitle,
            icon: Icons.policy_outlined,
            onTap: () => context.push('/privacy-policy'),
          ),
          _buildNavTile(
            title: l10n.termsAndConditions,
            subtitle: l10n.termsSubtitle,
            icon: Icons.description_outlined,
            onTap: () => context.push('/terms-and-conditions'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.textSecondary, size: 20),
        onTap: onTap,
      ),
    );
  }
}
