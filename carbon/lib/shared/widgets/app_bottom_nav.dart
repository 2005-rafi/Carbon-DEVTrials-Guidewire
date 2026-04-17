import 'package:carbon/core/router/navigation_map.dart';
import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  final int currentIndex;
  final ValueChanged<String> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedIndex = currentIndex >= 0 ? currentIndex : 0;
    final hideSelection = currentIndex < 0;

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        indicatorColor: hideSelection
            ? Colors.transparent
            : colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          final isSelected = states.contains(WidgetState.selected);
          return Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          onTabSelected(NavigationMap.routeForIndex(index));
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_turned_in_outlined),
            label: 'Claims',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments_rounded),
            label: 'Payouts',
          ),
        ],
      ),
    );
  }
}
