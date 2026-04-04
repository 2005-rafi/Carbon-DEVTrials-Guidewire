import 'package:carbon/core/router/route_names.dart';
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
import 'package:flutter/material.dart';

class AppRouter {
  AppRouter._();

  static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
    RouteNames.splash: (_) => const SplashScreen(),
    RouteNames.login: (_) => const LoginScreen(),
    RouteNames.register: (_) => const RegisterScreen(),
    RouteNames.otp: (_) => const OtpScreen(),
    RouteNames.dashboard: (_) => const DashboardScreen(),
    RouteNames.policy: (_) => const PolicyScreen(),
    RouteNames.claims: (_) => const ClaimsScreen(),
    RouteNames.payout: (_) => const PayoutScreen(),
    RouteNames.events: (_) => const EventsScreen(),
    RouteNames.analytics: (_) => const AnalyticsScreen(),
    RouteNames.notifications: (_) => const NotificationScreen(),
    RouteNames.profile: (_) => const ProfileScreen(),
    RouteNames.settings: (_) => const SettingsScreen(),
  };
}
