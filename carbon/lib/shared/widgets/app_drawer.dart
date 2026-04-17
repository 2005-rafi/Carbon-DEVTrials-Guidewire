import 'package:carbon/core/router/navigation_service.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/features/auth/provider/auth_feature_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key, required this.currentRoute});

  final String currentRoute;

  static const List<_DrawerItem> _coreItems = <_DrawerItem>[
    _DrawerItem('Policy', RouteNames.policy, Icons.policy_outlined),
    _DrawerItem('Analytics', RouteNames.analytics, Icons.insights_outlined),
    _DrawerItem('Events', RouteNames.events, Icons.warning_amber_outlined),
  ];

  static const List<_DrawerItem> _accountItems = <_DrawerItem>[
    _DrawerItem('Profile', RouteNames.profile, Icons.person_outline),
    _DrawerItem('Settings', RouteNames.settings, Icons.settings_outlined),
    _DrawerItem(
      'Notifications',
      RouteNames.notifications,
      Icons.notifications_outlined,
    ),
  ];

  Future<void> _openRoute(BuildContext context, String routeName) async {
    Navigator.of(context).pop();
    if (routeName == currentRoute) {
      return;
    }
    await NavigationService.instance.pushReplacementNamed(routeName);
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Text(
        label,
        style: textTheme.labelMedium?.copyWith(
          color: colorScheme.tertiary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, _DrawerItem item) {
    return ListTile(
      leading: Icon(item.icon),
      title: Text(item.label),
      selected: item.routeName == currentRoute,
      onTap: () => _openRoute(context, item.routeName),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            const DrawerHeader(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Carbon',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              selected: currentRoute == RouteNames.dashboard,
              onTap: () => _openRoute(context, RouteNames.dashboard),
            ),
            _buildSectionLabel(context, 'Core'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  for (final item in _coreItems) _buildItem(context, item),
                  _buildSectionLabel(context, 'Account'),
                  for (final item in _accountItems) _buildItem(context, item),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await ref.read(authActionProvider).logout();
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pop();
                await NavigationService.instance.pushNamedAndRemoveUntil(
                  RouteNames.login,
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem(this.label, this.routeName, this.icon);

  final String label;
  final String routeName;
  final IconData icon;
}
