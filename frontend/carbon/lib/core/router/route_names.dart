class RouteNames {
  RouteNames._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';

  static const String dashboard = '/dashboard';
  static const String policy = '/policy';
  static const String claims = '/claims';
  static const String payout = '/payout';
  static const String events = '/events';
  static const String analytics = '/analytics';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

class CoreRoutes {
  CoreRoutes._();

  static const List<String> ordered = <String>[
    RouteNames.dashboard,
    RouteNames.policy,
    RouteNames.claims,
    RouteNames.payout,
    RouteNames.events,
    RouteNames.analytics,
    RouteNames.notifications,
    RouteNames.profile,
    RouteNames.settings,
  ];

  static int indexOf(String routeName) {
    final index = ordered.indexOf(routeName);
    return index >= 0 ? index : 0;
  }
}
