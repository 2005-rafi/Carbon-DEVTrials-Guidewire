import 'package:animations/animations.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/core/constants/app_constants.dart';
import 'package:carbon/core/theme/carbon_theme.dart';
import 'package:carbon/features/auth/presentation/login_form_utils.dart';
import 'package:carbon/features/auth/presentation/otp_screen.dart';
import 'package:carbon/features/auth/provider/auth_feature_provider.dart';
import 'package:carbon/shared/widgets/carbon_button.dart';
import 'package:carbon/shared/widgets/carbon_input.dart';
import 'package:carbon/shared/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  CountryDialCode _selectedCountry = LoginFormValidators.india;
  LoginUiState _uiState = LoginUiState.idle;
  String? _inlineError;

  bool get _isPhoneValid => LoginFormValidators.isValidForCountry(
    _phoneController.text,
    country: _selectedCountry,
  );

  String get _normalizedPhone => LoginFormValidators.normalizePhoneForApi(
    _phoneController.text,
    country: _selectedCountry,
  );

  CarbonButtonState _resolveButtonState(bool providerLoading) {
    if (_uiState == LoginUiState.loading || providerLoading) {
      return CarbonButtonState.loading;
    }

    return _isPhoneValid
        ? CarbonButtonState.enabled
        : CarbonButtonState.disabled;
  }

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _shakeAnimation = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0, end: 10),
          weight: 1,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 10, end: -10),
          weight: 2,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: -10, end: 6),
          weight: 1,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 6, end: 0),
          weight: 1,
        ),
      ],
    ).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));
  }

  void _triggerValidationError({required String message}) {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
    setState(() {
      _uiState = LoginUiState.failure;
      _inlineError = message;
    });
  }

  Future<void> _navigateToOtpWithSharedAxis(
    String normalizedPhone, {
    OtpAuthFlow flow = OtpAuthFlow.login,
  }) async {
    final route = PageRouteBuilder<void>(
      settings: RouteSettings(
        name: RouteNames.otp,
        arguments: OtpScreenArgs(phone: normalizedPhone, flow: flow),
      ),
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const OtpScreen();
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

    await Navigator.of(context).push(route);
  }

  Future<void> _handleContinueToOtp() async {
    if (_uiState == LoginUiState.loading) {
      return;
    }

    final isValid =
        (_formKey.currentState?.validate() ?? false) &&
        LoginFormValidators.isValidForCountry(
          _phoneController.text,
          country: _selectedCountry,
        );
    if (!isValid) {
      _triggerValidationError(message: 'Enter a valid mobile number.');
      AppSnackbar.show(
        context,
        'Enter a valid mobile number.',
        toastType: AppToastType.error,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _uiState = LoginUiState.loading;
      _inlineError = null;
    });

    final normalizedPhone = _normalizedPhone;

    final ok = await ref.read(authActionProvider).sendOtp(normalizedPhone);

    if (!mounted) {
      return;
    }

    if (!ok) {
      final errorText =
          ref.read(authErrorProvider) ??
          'Unable to send OTP. Please try again in a moment.';

      setState(() {
        _uiState = LoginUiState.failure;
        _inlineError = errorText;
      });
      _shakeController.forward(from: 0);
      HapticFeedback.heavyImpact();
      AppSnackbar.show(
        context,
        errorText,
        toastType: ref.read(authToastTypeProvider),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _uiState = LoginUiState.success;
      _inlineError = null;
    });
    _showOtpDispatchFeedback();

    await _navigateToOtpWithSharedAxis(normalizedPhone);
    if (!mounted) {
      return;
    }

    setState(() {
      _uiState = LoginUiState.idle;
    });
  }

  Future<void> _handleCreateAccount() async {
    if (_uiState == LoginUiState.loading) {
      return;
    }

    final isValid =
        (_formKey.currentState?.validate() ?? false) &&
        LoginFormValidators.isValidForCountry(
          _phoneController.text,
          country: _selectedCountry,
        );
    if (!isValid) {
      _triggerValidationError(
        message: 'Enter a valid mobile number to create your account.',
      );
      AppSnackbar.show(
        context,
        'Enter a valid mobile number to create your account.',
        toastType: AppToastType.error,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _uiState = LoginUiState.loading;
      _inlineError = null;
    });

    final normalizedPhone = _normalizedPhone;
    final ok = await ref.read(authActionProvider).sendOtp(normalizedPhone);
    if (!mounted) {
      return;
    }

    if (!ok) {
      final errorText =
          ref.read(authErrorProvider) ??
          'Unable to send OTP. Please try again in a moment.';

      setState(() {
        _uiState = LoginUiState.failure;
        _inlineError = errorText;
      });
      _shakeController.forward(from: 0);
      HapticFeedback.heavyImpact();
      AppSnackbar.show(
        context,
        errorText,
        toastType: ref.read(authToastTypeProvider),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _uiState = LoginUiState.success;
      _inlineError = null;
    });
    _showOtpDispatchFeedback();

    await _navigateToOtpWithSharedAxis(
      normalizedPhone,
      flow: OtpAuthFlow.register,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _uiState = LoginUiState.idle;
    });
  }

  void _clearFailureState() {
    if (_uiState != LoginUiState.failure && _inlineError == null) {
      return;
    }

    setState(() {
      _uiState = LoginUiState.idle;
      _inlineError = null;
    });
    ref.read(authActionProvider).clearError();
  }

  void _showOtpDispatchFeedback() {
    final feedback = ref.read(otpSendFeedbackProvider);
    if (feedback == null) {
      return;
    }

    if (feedback.notificationShown) {
      AppSnackbar.show(
        context,
        'OTP sent. Check your notification tray and copy the code quickly.',
        toastType: AppToastType.success,
        position: AppToastPosition.top,
      );
      return;
    }

    if (!feedback.otpFoundInResponse) {
      AppSnackbar.show(
        context,
        'OTP sent. Notification preview is unavailable; use the OTP from your primary channel.',
        toastType: AppToastType.warning,
        position: AppToastPosition.top,
      );
      return;
    }

    if (feedback.notificationFailureReason == 'permission_denied') {
      AppSnackbar.show(
        context,
        'OTP sent. Notification permission is disabled, so enter OTP manually.',
        toastType: AppToastType.warning,
        position: AppToastPosition.top,
      );
      return;
    }

    AppSnackbar.show(
      context,
      'OTP sent. If notification does not appear, enter the code manually.',
      toastType: AppToastType.warning,
      position: AppToastPosition.top,
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: <Widget>[
        Hero(
          tag: 'carbon-brand-mark',
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.35),
              ),
            ),
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            child: ClipOval(
              child: Image.asset(
                AppConstants.splashLogoPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.eco_outlined,
                    color: colorScheme.primary,
                    size: 34,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Carbon',
          style: textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildInlineError(BuildContext context, String errorText) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorText,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerLoading = ref.watch(authLoadingProvider);
    final authError = ref.watch(authErrorProvider);
    final buttonState = _resolveButtonState(providerLoading);
    final isLoading = buttonState == CarbonButtonState.loading;
    final activeError = _inlineError ?? authError;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: 4),
                      _buildBrandHeader(context),
                      const SizedBox(height: 18),
                      Text(
                        'Welcome Back',
                        style: CarbonTheme.authTitle(
                          context,
                        ).copyWith(color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue protected earnings with secure access.',
                        style: CarbonTheme.authSubtitle(context),
                      ),
                      const SizedBox(height: 18),
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: child,
                          );
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(
                              width: 120,
                              child: DropdownButtonFormField<CountryDialCode>(
                                initialValue: _selectedCountry,
                                items: LoginFormValidators.supportedCountries
                                    .map(
                                      (country) =>
                                          DropdownMenuItem<CountryDialCode>(
                                            value: country,
                                            child: Text(country.dialCode),
                                          ),
                                    )
                                    .toList(growable: false),
                                onChanged: isLoading
                                    ? null
                                    : (value) {
                                        if (value == null) {
                                          return;
                                        }
                                        setState(() {
                                          _selectedCountry = value;
                                        });
                                      },
                                decoration: InputDecoration(
                                  labelText: 'Code',
                                  filled: true,
                                  fillColor:
                                      colorScheme.surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CarbonInput(
                                controller: _phoneController,
                                enabled: !isLoading,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                autofillHints: const <String>[
                                  AutofillHints.telephoneNumber,
                                ],
                                maxLength: 11,
                                inputFormatters: <TextInputFormatter>[
                                  PhoneMaskTextInputFormatter(),
                                  LengthLimitingTextInputFormatter(11),
                                ],
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: (value) =>
                                    LoginFormValidators.validatePhone(
                                      value,
                                      country: _selectedCountry,
                                    ),
                                onChanged: (_) {
                                  _clearFailureState();
                                  setState(() {});
                                },
                                onFieldSubmitted: (_) {
                                  if (_resolveButtonState(providerLoading) ==
                                      CarbonButtonState.enabled) {
                                    _handleContinueToOtp();
                                  }
                                },
                                labelText: 'Mobile Number',
                                hintText: '98765 43210',
                                prefix: Icon(
                                  Icons.phone_outlined,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A one-time password will be sent to your mobile number. If notifications are unavailable, enter the code manually.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      if (activeError != null)
                        _buildInlineError(context, activeError),
                      const SizedBox(height: 18),
                      CarbonButton(
                        label: 'Continue',
                        state: buttonState,
                        onPressed: _handleContinueToOtp,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: colorScheme.secondary,
                        ),
                        onPressed: isLoading ? null : _handleCreateAccount,
                        child: Text(
                          'New user? Create account',
                          style: textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
