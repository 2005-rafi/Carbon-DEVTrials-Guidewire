import 'dart:async';

import 'package:carbon/core/constants/app_constants.dart';
import 'package:carbon/core/providers/auth_provider.dart';
import 'package:carbon/core/router/navigation_service.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  Timer? _navigationTimer;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4050),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.9,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    _navigationTimer = Timer(AppConstants.splashDuration, _navigateNext);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _navigateNext() {
    if (_didNavigate) {
      return;
    }

    _didNavigate = true;
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    final target = isAuthenticated ? RouteNames.dashboard : RouteNames.login;

    NavigationService.instance.pushReplacementNamed(target);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _navigateNext,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final logoSize = (constraints.maxWidth * 0.34).clamp(
                  88.0,
                  132.0,
                );

                return Container(
                  width: double.infinity,
                  color: colorScheme.surface,
                  child: Stack(
                    children: <Widget>[
                      Center(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: (constraints.maxHeight - 128).clamp(
                                220.0,
                                constraints.maxHeight,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                FadeTransition(
                                  opacity: _fade,
                                  child: ScaleTransition(
                                    scale: _scale,
                                    child: Image.asset(
                                      AppConstants.splashLogoPath,
                                      width: logoSize,
                                      height: logoSize,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.shield_outlined,
                                              size: logoSize,
                                              color: colorScheme.primary,
                                            );
                                          },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                FadeTransition(
                                  opacity: _fade,
                                  child: SlideTransition(
                                    position: _slide,
                                    child: Text(
                                      'CARBON',
                                      textAlign: TextAlign.center,
                                      style: textTheme.headlineMedium?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.8,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                FadeTransition(
                                  opacity: _fade,
                                  child: Text(
                                    AppConstants.appTagline,
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 28,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            CircularProgressIndicator(
                              color: colorScheme.primary,
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Initializing...',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
