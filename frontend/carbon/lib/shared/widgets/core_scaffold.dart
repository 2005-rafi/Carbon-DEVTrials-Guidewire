import 'package:carbon/core/router/navigation_service.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/shared/widgets/app_appbar.dart';
import 'package:carbon/shared/widgets/app_dialog.dart';
import 'package:carbon/shared/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CoreScaffold extends StatelessWidget {
  const CoreScaffold({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.body,
    this.appBarActions,
    this.bottomNavigationBar,
  });

  final String currentRoute;
  final String title;
  final Widget body;
  final List<Widget>? appBarActions;
  final Widget? bottomNavigationBar;

  Future<bool> _onWillPop(BuildContext context) async {
    if (currentRoute != RouteNames.dashboard) {
      await NavigationService.instance.pushReplacementNamed(
        RouteNames.dashboard,
      );
      return false;
    }

    return AppDialog.showExitConfirmation(context);
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
        appBar: AppAppBar(title: title, actions: appBarActions),
        drawer: AppDrawer(currentRoute: currentRoute),
        body: SafeArea(child: body),
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
