import 'package:carbon/core/router/navigation_service.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.currentRoute});

  final String currentRoute;

  static const List<_DrawerItem> _items = <_DrawerItem>[
    _DrawerItem('Dashboard', RouteNames.dashboard, Icons.dashboard_outlined),
    _DrawerItem('Policy', RouteNames.policy, Icons.policy_outlined),
    _DrawerItem(
      'Claims',
      RouteNames.claims,
      Icons.assignment_turned_in_outlined,
    ),
    _DrawerItem('Payout', RouteNames.payout, Icons.payments_outlined),
    _DrawerItem('Events', RouteNames.events, Icons.warning_amber_outlined),
    _DrawerItem('Analytics', RouteNames.analytics, Icons.insights_outlined),
    _DrawerItem(
      'Notifications',
      RouteNames.notifications,
      Icons.notifications_outlined,
    ),
    _DrawerItem('Profile', RouteNames.profile, Icons.person_outline),
    _DrawerItem('Settings', RouteNames.settings, Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
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
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = _items[index];
                  return ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.label),
                    selected: item.routeName == currentRoute,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (item.routeName == currentRoute) {
                        return;
                      }
                      NavigationService.instance.pushReplacementNamed(
                        item.routeName,
                      );
                    },
                  );
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.of(context).pop();
                NavigationService.instance.pushNamedAndRemoveUntil(
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
