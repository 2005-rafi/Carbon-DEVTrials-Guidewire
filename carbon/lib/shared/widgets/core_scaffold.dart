import 'package:carbon/core/router/navigation_service.dart';
import 'package:carbon/core/router/navigation_map.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/shared/widgets/app_appbar.dart';
import 'package:carbon/shared/widgets/app_bottom_nav.dart';
import 'package:carbon/shared/widgets/app_dialog.dart';
import 'package:carbon/shared/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CoreScaffold extends StatefulWidget {
  const CoreScaffold({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.body,
    this.dashboardBody,
    this.claimsBody,
    this.payoutBody,
  });

  const CoreScaffold.shell({
    super.key,
    required this.currentRoute,
    required this.dashboardBody,
    required this.claimsBody,
    required this.payoutBody,
  }) : title = '',
       body = const SizedBox.shrink();

  final String currentRoute;
  final String title;
  final Widget body;
  final Widget? dashboardBody;
  final Widget? claimsBody;
  final Widget? payoutBody;

  bool get isPersistentShell =>
      dashboardBody != null && claimsBody != null && payoutBody != null;

  @override
  State<CoreScaffold> createState() => _CoreScaffoldState();
}

class _CoreScaffoldState extends State<CoreScaffold> {
  late String _activeRoute;

  int get currentIndex => NavigationMap.indexOf(_activeRoute);

  @override
  void initState() {
    super.initState();
    _activeRoute = widget.currentRoute;
  }

  @override
  void didUpdateWidget(covariant CoreScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      _activeRoute = widget.currentRoute;
    }
  }

  String get _title {
    if (!widget.isPersistentShell) {
      return widget.title;
    }

    switch (_activeRoute) {
      case RouteNames.dashboard:
        return 'Dashboard';
      case RouteNames.claims:
        return 'Claims';
      case RouteNames.payout:
        return 'Payouts';
      default:
        return 'Carbon';
    }
  }

  Future<void> _onTabSelected(String routeName) async {
    if (widget.isPersistentShell) {
      if (routeName == _activeRoute) {
        return;
      }
      setState(() {
        _activeRoute = routeName;
      });
      return;
    }

    if (routeName == _activeRoute) {
      return;
    }

    await NavigationService.instance.pushReplacementNamed(routeName);
  }

  Future<bool> _onWillPop(BuildContext context) async {
    if (currentIndex > 0) {
      setState(() {
        _activeRoute = RouteNames.dashboard;
      });
      return false;
    }

    if (_activeRoute != RouteNames.dashboard) {
      await NavigationService.instance.pushReplacementNamed(
        RouteNames.dashboard,
      );
      return false;
    }

    return AppDialog.showExitConfirmation(context);
  }

  Future<void> _openNotifications() async {
    if (_activeRoute == RouteNames.notifications) {
      return;
    }
    await NavigationService.instance.pushReplacementNamed(
      RouteNames.notifications,
    );
  }

  Widget _buildBody() {
    if (!widget.isPersistentShell) {
      return widget.body;
    }

    final tabIndex = currentIndex >= 0 ? currentIndex : 0;
    return IndexedStack(
      index: tabIndex,
      children: <Widget>[
        widget.dashboardBody!,
        widget.claimsBody!,
        widget.payoutBody!,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        final shouldExit = await _onWillPop(context);
        if (shouldExit) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppAppBar(
          title: _title,
          actions: <Widget>[
            IconButton(
              tooltip: 'Notifications',
              onPressed: _openNotifications,
              icon: const Icon(Icons.notifications_outlined),
            ),
          ],
        ),
        drawer: AppDrawer(currentRoute: _activeRoute),
        body: SafeArea(child: _buildBody()),
        bottomNavigationBar: AppBottomNav(
          currentIndex: currentIndex,
          onTabSelected: _onTabSelected,
        ),
      ),
    );
  }
}
