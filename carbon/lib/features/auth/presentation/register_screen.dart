import 'package:animations/animations.dart';
import 'package:carbon/core/providers/auth_provider.dart';
import 'package:carbon/core/router/app_router.dart';
import 'package:carbon/core/router/navigation_service.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/core/theme/carbon_theme.dart';
import 'package:carbon/features/auth/data/auth_service.dart';
import 'package:carbon/features/auth/presentation/register_form_utils.dart';
import 'package:carbon/features/auth/presentation/widgets/registration_form.dart';
import 'package:carbon/features/auth/provider/auth_feature_provider.dart';
import 'package:carbon/shared/widgets/app_snackbar.dart';
import 'package:carbon/shared/widgets/carbon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ValueNotifier<ProfileFinalizationFormValue> _formValueNotifier =
      ValueNotifier<ProfileFinalizationFormValue>(
        const ProfileFinalizationFormValue.empty(),
      );

  int _emailShakeNonce = 0;
  bool _isHydrating = true;
  bool _redirecting = false;
  String _verifiedPhone = '';

  @override
  void initState() {
    super.initState();
    _hydrateHandshakeContext();
  }

  Future<void> _hydrateHandshakeContext() async {
    final inMemoryPhone = (ref.read(authPendingPhoneProvider) ?? '').trim();
    final resolvedPhone = inMemoryPhone.isNotEmpty
        ? inMemoryPhone
        : ((await ref.read(authServiceProvider).readPendingPhone()) ?? '')
              .trim();

    if (!mounted) {
      return;
    }

    setState(() {
      _verifiedPhone = resolvedPhone;
      _isHydrating = false;
    });

    _enforceAccessGate();
  }

  Future<void> _enforceAccessGate() async {
    if (_redirecting || !mounted) {
      return;
    }

    final verificationToken = (ref.read(authVerificationTokenProvider) ?? '')
        .trim();
    final hasPendingRegistrationSession = ref.read(
      pendingRegistrationSessionReadyProvider,
    );
    if ((verificationToken.isNotEmpty || hasPendingRegistrationSession) &&
        _verifiedPhone.isNotEmpty) {
      return;
    }

    _redirecting = true;
    AppSnackbar.show(
      context,
      'Session expired. Please restart verification from login.',
      toastType: AppToastType.error,
      position: AppToastPosition.top,
    );
    await NavigationService.instance.pushNamedAndRemoveUntil(
      RouteNames.login,
      (route) => false,
    );
  }

  bool _isDuplicateEmailError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('email') &&
        (normalized.contains('already') || normalized.contains('exists'));
  }

  bool _isSessionExpiredError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('session expired') ||
        normalized.contains('restart verification') ||
        normalized.contains('sign in again');
  }

  Future<void> _navigateToDashboardWithSharedAxis() async {
    final dashboardBuilder = AppRouter.routes[RouteNames.dashboard];
    if (dashboardBuilder == null) {
      await NavigationService.instance.pushNamedAndRemoveUntil(
        RouteNames.dashboard,
        (route) => false,
      );
      return;
    }

    final route = PageRouteBuilder<void>(
      settings: const RouteSettings(name: RouteNames.dashboard),
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return dashboardBuilder(context);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          transitionType: SharedAxisTransitionType.horizontal,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          fillColor: Theme.of(context).colorScheme.surface,
          child: child,
        );
      },
    );

    await Navigator.of(context).pushAndRemoveUntil(route, (route) => false);
  }

  Future<void> _handleFinalizeProfile() async {
    final providerLoading = ref.read(authLoadingProvider);
    if (providerLoading || _isHydrating || _redirecting) {
      return;
    }

    final isValidForm = _formKey.currentState?.validate() ?? false;
    final formValue = _formValueNotifier.value;
    if (!isValidForm || !formValue.canSubmit) {
      return;
    }

    FocusScope.of(context).unfocus();
    final ok = await ref
        .read(authActionProvider)
        .finalizeRegistrationProfile(
          fullName: formValue.fullName,
          email: formValue.email,
        );

    if (!mounted) {
      return;
    }

    if (!ok) {
      final errorText =
          ref.read(authErrorProvider) ??
          'Unable to complete profile finalization. Please try again.';

      if (_isDuplicateEmailError(errorText)) {
        setState(() {
          _emailShakeNonce += 1;
        });
        AppSnackbar.show(
          context,
          errorText,
          toastType: AppToastType.error,
          position: AppToastPosition.top,
        );
        return;
      }

      if (_isSessionExpiredError(errorText)) {
        await _enforceAccessGate();
        return;
      }

      AppSnackbar.show(
        context,
        errorText,
        toastType: ref.read(authToastTypeProvider),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    AppSnackbar.show(context, 'Account created successfully.');
    await _navigateToDashboardWithSharedAxis();
  }

  @override
  void dispose() {
    _formValueNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);
    final token = (ref.watch(authVerificationTokenProvider) ?? '').trim();
    final hasPendingRegistrationSession = ref.watch(
      pendingRegistrationSessionReadyProvider,
    );
    if (!_isHydrating &&
        !_redirecting &&
        ((token.isEmpty && !hasPendingRegistrationSession) ||
            _verifiedPhone.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _enforceAccessGate();
      });
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isHydrating) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          onPressed: isLoading
              ? null
              : () => NavigationService.instance.pushNamedAndRemoveUntil(
                  RouteNames.login,
                  (route) => false,
                ),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Complete Your Profile',
                      style: CarbonTheme.authTitle(
                        context,
                      ).copyWith(color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your mobile number is already verified. Add profile details to finalize your secure Carbon account.',
                      style: CarbonTheme.authSubtitle(context),
                    ),
                    const SizedBox(height: 22),
                    RegistrationForm(
                      verifiedPhone: _verifiedPhone,
                      enabled: !isLoading,
                      emailShakeNonce: _emailShakeNonce,
                      onFormChanged: (value) {
                        _formValueNotifier.value = value;
                      },
                    ),
                    const SizedBox(height: 20),
                    ValueListenableBuilder<ProfileFinalizationFormValue>(
                      valueListenable: _formValueNotifier,
                      builder: (context, formValue, child) {
                        final buttonState = isLoading
                            ? CarbonButtonState.loading
                            : formValue.canSubmit
                            ? CarbonButtonState.enabled
                            : CarbonButtonState.disabled;

                        return CarbonButton(
                          label: 'Create Account',
                          state: buttonState,
                          onPressed: _handleFinalizeProfile,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Need to start over? Go back to login and request a new OTP.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
