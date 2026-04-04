import 'package:carbon/core/router/app_router.dart';
import 'package:carbon/core/router/navigation_service.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/core/theme/app_theme.dart';
import 'package:carbon/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Carbon',
      navigatorKey: NavigationService.instance.navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: RouteNames.splash,
      routes: AppRouter.routes,
    );
  }
}
