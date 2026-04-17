import 'package:carbon/core/providers/auth_provider.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationService {
  NavigationService._();

  static final NavigationService instance = NavigationService._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState? get _navigator => navigatorKey.currentState;

  static const Set<String> _publicRoutes = <String>{
    RouteNames.splash,
    RouteNames.login,
    RouteNames.register,
    RouteNames.otp,
  };

  bool _isProtectedRoute(String routeName) {
    return !_publicRoutes.contains(routeName);
  }

  bool _isSessionValid() {
    final context = navigatorKey.currentContext;
    if (context == null) {
      return true;
    }
    final container = ProviderScope.containerOf(context, listen: false);
    return container.read(isAuthenticatedProvider);
  }

  Future<T?> _redirectToLogin<T extends Object?>() {
    return _navigator?.pushNamedAndRemoveUntil<T>(
          RouteNames.login,
          (route) => false,
        ) ??
        Future<T?>.value(null);
  }

  bool _shouldGuardRoute(String routeName) {
    return _isProtectedRoute(routeName) && !_isSessionValid();
  }

  Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    if (_shouldGuardRoute(routeName)) {
      return _redirectToLogin<T>();
    }

    return _navigator?.pushNamed<T>(routeName, arguments: arguments) ??
        Future<T?>.value(null);
  }

  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    if (_shouldGuardRoute(routeName)) {
      return _redirectToLogin<T>();
    }

    return _navigator?.pushReplacementNamed<T, TO>(
          routeName,
          result: result,
          arguments: arguments,
        ) ??
        Future<T?>.value(null);
  }

  Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String newRouteName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    if (_shouldGuardRoute(newRouteName)) {
      return _redirectToLogin<T>();
    }

    return _navigator?.pushNamedAndRemoveUntil<T>(
          newRouteName,
          predicate,
          arguments: arguments,
        ) ??
        Future<T?>.value(null);
  }

  bool pop<T extends Object?>([T? result]) {
    if (_navigator == null || !_navigator!.canPop()) {
      return false;
    }
    _navigator!.pop<T>(result);
    return true;
  }
}
