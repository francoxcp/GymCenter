import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/user_provider.dart';

/// Números de la semana (desde el lunes) que el dueño revisa de un vistazo.
class WeekNumbers {
  final int newMembers;
  final int expiring;
  final int expired;
  const WeekNumbers(this.newMembers, this.expiring, this.expired);

  static WeekNumbers from(List<User> users, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final members = users.where((u) => u.role == 'user');
    return WeekNumbers(
      members
          .where((u) => u.createdAt != null && !u.createdAt!.toLocal().isBefore(weekStart))
          .length,
      members.where((u) => u.membershipStatus == MembershipStatus.expiring).length,
      members.where((u) => u.membershipStatus == MembershipStatus.expired).length,
    );
  }
}

class WeeklySummaryCard extends StatelessWidget {
  final int sessions;
  final bool loading;
  const WeeklySummaryCard({super.key, required this.sessions, required this.loading});

  @override
  Widget build(BuildContext context) {
    final users = context.watch<UserProvider>().users;
    final isOwner = context.select<AuthProvider, bool>((a) => a.isAdmin);
    final w = WeekNumbers.from(users, DateTime.now());
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ESTA SEMANA',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Num(
                value: loading ? '–' : '$sessions',
                label: 'entrenos',
                accent: true,
              ),
              _Num(
                value: '${w.newMembers}',
                label: w.newMembers == 1 ? 'socio nuevo' : 'socios nuevos',
                onTap: () => context.go('/admin/members'),
              ),
              if (isOwner)
                _Num(
                  value: '${w.expiring}',
                  label: 'por vencer',
                  warn: w.expiring > 0,
                  onTap: () => context.go('/admin/members?f=por-vencer'),
                ),
            ],
          ),
          if (isOwner && w.expired > 0) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => context.go('/admin/members?f=vencidas'),
              child: Row(
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: AppColors.error, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        w.expired == 1
                            ? '1 membresía vencida: cobrar'
                            : '${w.expired} membresías vencidas: cobrar',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Num extends StatelessWidget {
  final String value;
  final String label;
  final bool accent;
  final bool warn;
  final VoidCallback? onTap;
  const _Num({
    required this.value,
    required this.label,
    this.accent = false,
    this.warn = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent
        ? AppColors.primaryText
        : warn
            ? AppColors.warning
            : AppColors.textPrimary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
