import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/core/router/route_guard.dart';
import 'package:carbon/features/analytics/presentation/analytics_screen.dart';
import 'package:carbon/features/auth/presentation/login_screen.dart';
import 'package:carbon/features/auth/presentation/otp_screen.dart';
import 'package:carbon/features/auth/presentation/register_screen.dart';
import 'package:carbon/features/claims/presentation/claims_screen.dart';
import 'package:carbon/features/dashboard/presentation/dashboard_screen.dart';
import 'package:carbon/features/events/presentation/events_screen.dart';
import 'package:carbon/features/notifications/presentation/notification_screen.dart';
import 'package:carbon/features/payout/presentation/payout_screen.dart';
import 'package:carbon/features/policy/presentation/policy_screen.dart';
import 'package:carbon/features/profile/presentation/profile_screen.dart';
import 'package:carbon/features/splash/presentation/splash_screen.dart';
import 'package:carbon/features/settings/presentation/settings_screen.dart';
import 'package:carbon/shared/widgets/core_scaffold.dart';
import 'package:flutter/material.dart';

class AppRouter {
  AppRouter._();

  static Widget _coreShell(String initialRoute) {
    return RouteGuard(
      child: CoreScaffold.shell(
        currentRoute: initialRoute,
        dashboardBody: const DashboardScreen(),
        claimsBody: const ClaimsScreen(),
        payoutBody: const PayoutScreen(),
      ),
    );
  }

  static Widget _guarded(
    Widget child, {
    bool allowIncompleteProfileAccess = false,
  }) {
    return RouteGuard(
      allowIncompleteProfileAccess: allowIncompleteProfileAccess,
      child: child,
    );
  }

  static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
    RouteNames.splash: (_) => const SplashScreen(),
    RouteNames.login: (_) => const LoginScreen(),
    RouteNames.register: (_) =>
        const VerificationRouteGuard(child: RegisterScreen()),
    RouteNames.otp: (_) => const OtpScreen(),
    RouteNames.dashboard: (_) => _coreShell(RouteNames.dashboard),
    RouteNames.claims: (_) => _coreShell(RouteNames.claims),
    RouteNames.payout: (_) => _coreShell(RouteNames.payout),
    RouteNames.policy: (_) => _guarded(const PolicyScreen()),
    RouteNames.events: (_) => _guarded(const EventsScreen()),
    RouteNames.analytics: (_) => _guarded(const AnalyticsScreen()),
    RouteNames.notifications: (_) => _guarded(const NotificationScreen()),
    RouteNames.profile: (_) =>
        _guarded(const ProfileScreen(), allowIncompleteProfileAccess: true),
    RouteNames.settings: (_) =>
        _guarded(const SettingsScreen(), allowIncompleteProfileAccess: true),
  };
}
