import 'package:flutter/material.dart';
import '../../core/l10n/app_l10n.dart';

/// Rol desde el punto de vista de la navegación.
enum NavRole { member, trainer, owner }

/// Una pestaña de la barra inferior.
class NavTabSpec {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String Function(AppL10n) label;

  /// Rutas que "pertenecen" a la pestaña (coincidencia por prefijo; gana el
  /// prefijo más largo, así /admin/members no cae en /admin).
  final List<String> prefixes;

  const NavTabSpec({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.prefixes,
  });
}

const _workoutPrefixes = [
  '/workouts',
  '/workout-detail',
  '/today-workout',
  '/workout-history',
  '/workout-calendar',
];

const _profilePrefixes = [
  '/profile',
  '/edit-profile',
  '/settings',
  '/privacy-settings',
  '/terms-and-conditions',
  '/privacy-policy',
];

final _profileTab = NavTabSpec(
  path: '/profile',
  icon: Icons.person_outline,
  activeIcon: Icons.person,
  label: (l) => l.navProfile,
  prefixes: _profilePrefixes,
);

final _membersTab = NavTabSpec(
  path: '/admin/members',
  icon: Icons.groups_outlined,
  activeIcon: Icons.groups,
  label: (l) => l.navMembers,
  prefixes: const [
    '/admin/members',
    '/admin/users',
    '/admin/assignments',
    '/admin/user-progress',
    '/admin/memberships',
  ],
);

final _workoutsTab = NavTabSpec(
  path: '/workouts',
  icon: Icons.fitness_center_outlined,
  activeIcon: Icons.fitness_center,
  label: (l) => l.navWorkouts,
  prefixes: const [..._workoutPrefixes, '/admin/create-workout'],
);

final List<NavTabSpec> memberTabs = [
  NavTabSpec(
    path: '/home',
    icon: Icons.bolt_outlined,
    activeIcon: Icons.bolt,
    label: (l) => l.navToday,
    prefixes: const ['/home', ..._workoutPrefixes],
  ),
  NavTabSpec(
    path: '/progress',
    icon: Icons.show_chart_outlined,
    activeIcon: Icons.show_chart,
    label: (l) => l.navProgress,
    prefixes: const [
      '/progress',
      '/training-control',
      '/body-measurements',
      '/achievements',
      '/personal-records',
    ],
  ),
  _profileTab,
];

final List<NavTabSpec> trainerTabs = [
  NavTabSpec(
    path: '/admin/today',
    icon: Icons.bolt_outlined,
    activeIcon: Icons.bolt,
    label: (l) => l.navToday,
    prefixes: const ['/admin/today', '/admin/activity', '/admin'],
  ),
  _membersTab,
  _workoutsTab,
  _profileTab,
];

final List<NavTabSpec> ownerTabs = [
  NavTabSpec(
    path: '/admin',
    icon: Icons.grid_view_outlined,
    activeIcon: Icons.grid_view,
    label: (l) => l.navPanel,
    prefixes: const ['/admin'],
  ),
  _membersTab,
  _workoutsTab,
  NavTabSpec(
    path: '/admin/organization',
    icon: Icons.storefront_outlined,
    activeIcon: Icons.storefront,
    label: (l) => l.navGym,
    prefixes: const ['/admin/organization'],
  ),
  _profileTab,
];

List<NavTabSpec> tabsFor(NavRole role) => switch (role) {
      NavRole.member => memberTabs,
      NavRole.trainer => trainerTabs,
      NavRole.owner => ownerTabs,
    };

/// Índice de la pestaña activa para [location] (prefijo más largo).
int tabIndexFor(List<NavTabSpec> tabs, String location) {
  var best = 0;
  var bestLen = -1;
  for (var i = 0; i < tabs.length; i++) {
    for (final p in tabs[i].prefixes) {
      final matches = location == p || location.startsWith('$p/');
      if (matches && p.length > bestLen) {
        best = i;
        bestLen = p.length;
      }
    }
  }
  return best;
}
