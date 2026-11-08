import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/share_helper.dart';
import '../services/organization_service.dart';

/// Muestra un enlace de invitación listo para copiar o enviar por WhatsApp.
Future<void> showInviteLinkSheet(
  BuildContext context, {
  required String token,
  required String title,
  required String hint,
  required String shareText,
}) {
  final url = OrganizationService.inviteUrl(token);
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(title,
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 6),
            Text(hint, style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
            const SizedBox(height: 16),
            // El código grande es lo que se dicta por teléfono si hace falta
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(children: [
                SelectableText(token,
                    onTap: () =>
                        ShareHelper.copy(ctx, token, okMessage: 'Código copiado'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 30,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                SelectableText(url,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ShareHelper.whatsapp('$shareText\n$url'),
              icon: const Icon(Icons.chat),
              label: const Text('Enviar por WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ShareHelper.shareOther('$shareText\n$url'),
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Otra app'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ShareHelper.copy(ctx, url, okMessage: 'Enlace copiado'),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar enlace'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    ),
  );
}
