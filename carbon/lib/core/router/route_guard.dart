import 'package:carbon/core/providers/auth_provider.dart';
import 'package:carbon/core/router/navigation_service.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/features/worker/provider/worker_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RouteGuard extends ConsumerStatefulWidget {
  const RouteGuard({
    super.key,
    required this.child,
    this.allowIncompleteProfileAccess = false,
  });

  final Widget child;
  final bool allowIncompleteProfileAccess;

  @override
  ConsumerState<RouteGuard> createState() => _RouteGuardState();
}

class VerificationRouteGuard extends ConsumerStatefulWidget {
  const VerificationRouteGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<VerificationRouteGuard> createState() =>
      _VerificationRouteGuardState();
}

class _VerificationRouteGuardState
    extends ConsumerState<VerificationRouteGuard> {
  bool _redirectScheduled = false;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final isEligible = ref.watch(profileFinalizationEligibleProvider);

    if (isAuthenticated) {
      _redirectScheduled = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        NavigationService.instance.pushNamedAndRemoveUntil(
          RouteNames.dashboard,
          (route) => false,
        );
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    if (isEligible) {
      _redirectScheduled = false;
      return widget.child;
    }

    if (!_redirectScheduled) {
      _redirectScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        NavigationService.instance.pushNamedAndRemoveUntil(
          RouteNames.login,
          (route) => false,
        );
      });
    }

    return const Scaffold(body: SizedBox.shrink());
  }
}

class _RouteGuardState extends ConsumerState<RouteGuard> {
  bool _redirectScheduled = false;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final workerSnapshot = isAuthenticated
        ? ref.watch(workerSnapshotProvider)
        : const WorkerSnapshot.empty();

    final requiresProfileCompletion =
        isAuthenticated &&
        !widget.allowIncompleteProfileAccess &&
        workerSnapshot.profile.hasIdentity &&
        workerSnapshot.profile.isIncomplete;

    if (requiresProfileCompletion) {
      if (!_redirectScheduled) {
        _redirectScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          NavigationService.instance.pushNamedAndRemoveUntil(
            RouteNames.profile,
            (route) => false,
          );
        });
      }

      return const Scaffold(body: SizedBox.shrink());
    }

    if (isAuthenticated) {
      _redirectScheduled = false;
      return widget.child;
    }

    if (!_redirectScheduled) {
      _redirectScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        NavigationService.instance.pushNamedAndRemoveUntil(
          RouteNames.login,
          (route) => false,
        );
      });
    }

    return const Scaffold(body: SizedBox.shrink());
  }
}
