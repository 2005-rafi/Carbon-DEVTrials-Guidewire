import 'package:carbon/core/router/route_names.dart';

class NavigationMap {
  NavigationMap._();

  static const List<String> bottomTabRoutes = <String>[
    RouteNames.dashboard,
    RouteNames.claims,
    RouteNames.payouts,
  ];

  static int indexOf(String routeName) {
    final index = bottomTabRoutes.indexOf(routeName);
    return index >= 0 ? index : -1;
  }

  static String routeForIndex(int index) {
    if (index < 0 || index >= bottomTabRoutes.length) {
      return RouteNames.dashboard;
    }
    return bottomTabRoutes[index];
  }

  static bool isBottomTabRoute(String routeName) {
    return indexOf(routeName) >= 0;
  }
}
