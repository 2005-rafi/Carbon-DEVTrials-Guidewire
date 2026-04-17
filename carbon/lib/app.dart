import 'package:carbon/core/router/app_router.dart';
import 'package:carbon/core/router/navigation_service.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/core/theme/app_theme.dart';
import 'package:carbon/core/theme/theme_provider.dart';
import 'package:carbon/features/auth/provider/auth_feature_provider.dart';
import 'package:carbon/features/worker/provider/worker_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> with WidgetsBindingObserver {
  bool _resumeSyncInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    if (_resumeSyncInProgress) {
      return;
    }

    _resumeSyncInProgress = true;
    ref
        .read(authActionProvider)
        .handleAppResumed()
        .then((_) => ref.read(workerActionProvider).refreshIfAuthenticated())
        .whenComplete(() => _resumeSyncInProgress = false);
  }

  @override
  Widget build(BuildContext context) {
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
