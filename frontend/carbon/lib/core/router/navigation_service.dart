import 'package:flutter/material.dart';

class NavigationService {
  NavigationService._();

  static final NavigationService instance = NavigationService._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState? get _navigator => navigatorKey.currentState;

  Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return _navigator?.pushNamed<T>(routeName, arguments: arguments) ??
        Future<T?>.value(null);
  }

  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
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
