import 'dart:async';

import 'package:carbon/core/router/navigation_service.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/core/theme/carbon_theme.dart';
import 'package:carbon/features/auth/data/auth_models.dart';
import 'package:carbon/features/auth/presentation/login_form_utils.dart';
import 'package:carbon/features/auth/provider/auth_feature_provider.dart';
import 'package:carbon/shared/widgets/app_appbar.dart';
import 'package:carbon/shared/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OtpAuthFlow { login, register }

class OtpScreenArgs {
  const OtpScreenArgs({
    required this.phone,
    required this.flow,
    this.fullName,
    this.email,
  });

  final String phone;
  final OtpAuthFlow flow;
  final String? fullName;
  final String? email;
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  static const int _resendCooldownDurationSeconds = 60;
  static const String _demoBypassOtp = '123456';
  static const String _demoBypassLogin = '9988776655';
  static const String _demoBypassSecret = 'carbon_pass123';

  late final List<TextEditingController> _digitControllers;
  late final List<FocusNode> _digitFocusNodes;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  Timer? _resendTimer;
  Timer? _clipboardTimer;
  bool _autoSubmitting = false;
  int _resendCooldownSeconds = 0;
  String? _clipboardOtp;
  bool _clipboardReadBlocked = false;
  bool _clipboardErrorNotified = false;

  String get _otpValue =>
      _digitControllers.map((controller) => controller.text.trim()).join();

  bool get _isOtpComplete => _otpValue.length == 6;

  @override
  void initState() {
    super.initState();
    _digitControllers = List<TextEditingController>.generate(
      6,
      (_) => TextEditingController(),
    );
    _digitFocusNodes = List<FocusNode>.generate(6, (_) => FocusNode());

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _shakeAnimation = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0, end: 9),
          weight: 1,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 9, end: -9),
          weight: 2,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: -9, end: 6),
          weight: 1,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 6, end: 0),
          weight: 1,
        ),
      ],
    ).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));

    _refreshClipboardOtp();
    _clipboardTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _refreshClipboardOtp();
    });
    _startResendCooldown();
  }

  OtpScreenArgs _resolveArgs() {
    final raw = ModalRoute.of(context)?.settings.arguments;
    if (raw is OtpScreenArgs) {
      return raw;
    }

    return const OtpScreenArgs(phone: '', flow: OtpAuthFlow.login);
  }

  void _triggerOtpError() {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
  }

  void _handleOtpChanged(int index, String value, {required bool isLoading}) {
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) {
      _digitControllers[index].text = '';
      if (index > 0) {
        _digitFocusNodes[index - 1].requestFocus();
      }
      _refreshClipboardOtp();
      return;
    }

    if (cleaned.length > 1) {
      _applyOtpString(cleaned);
      if (!isLoading) {
        _attemptAutoSubmit(isLoading: isLoading);
      }
      return;
    }

    _digitControllers[index].text = cleaned;
    _digitControllers[index].selection = TextSelection.collapsed(
      offset: _digitControllers[index].text.length,
    );

    if (index < _digitFocusNodes.length - 1) {
      _digitFocusNodes[index + 1].requestFocus();
    }

    _refreshClipboardOtp();
    if (!isLoading) {
      _attemptAutoSubmit(isLoading: isLoading);
    }
  }

  void _applyOtpString(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < _digitControllers.length; i++) {
      _digitControllers[i].text = i < digits.length ? digits[i] : '';
      _digitControllers[i].selection = TextSelection.collapsed(
        offset: _digitControllers[i].text.length,
      );
    }

    final focusIndex = digits.length >= 6 ? 5 : digits.length;
    if (focusIndex >= 0 && focusIndex < _digitFocusNodes.length) {
      _digitFocusNodes[focusIndex].requestFocus();
    }
  }

  Future<void> _attemptAutoSubmit({required bool isLoading}) async {
    if (isLoading || _autoSubmitting || !_isOtpComplete) {
      return;
    }

    _autoSubmitting = true;
    try {
      await _handleVerify();
    } finally {
      _autoSubmitting = false;
    }
  }

  Future<void> _handleVerify() async {
    final args = _resolveArgs();
    if (args.phone.trim().isEmpty) {
      AppSnackbar.show(
        context,
        'Session context missing. Please restart login.',
        toastType: AppToastType.error,
      );
      await NavigationService.instance.pushNamedAndRemoveUntil(
        RouteNames.login,
        (route) => false,
      );
      return;
    }

    final otp = _otpValue;
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _triggerOtpError();
      AppSnackbar.show(
        context,
        'Please enter a valid 6-digit OTP.',
        toastType: AppToastType.invalidOtp,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final isLoading = ref.read(authLoadingProvider);
    if (isLoading) {
      return;
    }

    final authAction = ref.read(authActionProvider);

    if (args.flow == OtpAuthFlow.login && otp == _demoBypassOtp) {
      final demoLoginOk = await authAction.login(
        _demoBypassLogin,
        _demoBypassSecret,
      );
      if (!mounted) {
        return;
      }

      if (!demoLoginOk) {
        _triggerOtpError();
        AppSnackbar.show(
          context,
          ref.read(authErrorProvider) ??
              'Demo sign-in is unavailable right now. Please try again.',
          toastType: ref.read(authToastTypeProvider),
        );
        return;
      }

      HapticFeedback.mediumImpact();
      AppSnackbar.show(
        context,
        'Demo OTP accepted. Signed in to shared demo account.',
        toastType: AppToastType.success,
      );
      await NavigationService.instance.pushNamedAndRemoveUntil(
        RouteNames.dashboard,
        (route) => false,
      );
      return;
    }

    final ok = args.flow == OtpAuthFlow.register
        ? await authAction.verifyRegistrationOtp(otp: otp)
        : await authAction.verifyOtp(otp);

    if (!mounted) {
      return;
    }

    if (!ok) {
      _triggerOtpError();
      AppSnackbar.show(
        context,
        ref.read(authErrorProvider) ?? 'OTP verification failed.',
        toastType: ref.read(authToastTypeProvider),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    if (args.flow == OtpAuthFlow.register) {
      AppSnackbar.show(context, 'Phone verified. Complete your profile.');
      await NavigationService.instance.pushReplacementNamed(
        RouteNames.register,
      );
      return;
    }

    AppSnackbar.show(context, 'Authentication successful.');
    await NavigationService.instance.pushNamedAndRemoveUntil(
      RouteNames.dashboard,
      (route) => false,
    );
  }

  Future<void> _handleResend() async {
    if (_resendCooldownSeconds > 0) {
      AppSnackbar.show(
        context,
        'Please wait $_resendCooldownSeconds seconds before requesting a new OTP.',
        toastType: AppToastType.rateLimit,
      );
      return;
    }

    final args = _resolveArgs();
    if (args.phone.trim().isEmpty) {
      AppSnackbar.show(
        context,
        'Phone context missing. Please restart login.',
        toastType: AppToastType.error,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final ok = await ref.read(authActionProvider).resendOtp();
    if (!mounted) {
      return;
    }

    if (!ok) {
      final errorText = ref.read(authErrorProvider) ?? 'Unable to resend OTP.';
      final isSessionExpired =
          errorText.toLowerCase().contains('session expired') ||
          errorText.toLowerCase().contains('restart login');
      if (isSessionExpired) {
        AppSnackbar.show(
          context,
          errorText,
          toastType: AppToastType.error,
          position: AppToastPosition.top,
        );
        await NavigationService.instance.pushNamedAndRemoveUntil(
          RouteNames.login,
          (route) => false,
        );
        return;
      }

      AppSnackbar.show(
        context,
        errorText,
        toastType: ref.read(authToastTypeProvider),
      );
      return;
    }

    AppSnackbar.show(context, 'A new OTP has been sent.');
    _startResendCooldown();
  }

  Future<void> _refreshClipboardOtp() async {
    String clipboardText = '';
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      clipboardText = (clipboardData?.text ?? '').trim();
      _clipboardReadBlocked = false;
    } on PlatformException {
      _clipboardReadBlocked = true;
      if (!_clipboardErrorNotified && mounted) {
        _clipboardErrorNotified = true;
        AppSnackbar.show(
          context,
          'Clipboard access is unavailable. Enter OTP manually.',
          toastType: AppToastType.warning,
          position: AppToastPosition.top,
        );
      }
    }

    if (!mounted) {
      return;
    }

    if (clipboardText.isEmpty) {
      if (_clipboardOtp != null) {
        setState(() {
          _clipboardOtp = null;
        });
      }
      return;
    }

    final match = RegExp(r'\b\d{6}\b').firstMatch(clipboardText);
    final otp = match?.group(0);

    if (!mounted) {
      return;
    }

    if ((otp ?? '').isEmpty) {
      if (_clipboardOtp != null) {
        setState(() {
          _clipboardOtp = null;
        });
      }
      return;
    }

    if (_clipboardOtp != otp) {
      setState(() {
        _clipboardOtp = otp;
      });
    }
  }

  Future<void> _handlePasteOtp() async {
    if (_clipboardReadBlocked) {
      AppSnackbar.show(
        context,
        'Clipboard access is unavailable on this device. Enter OTP manually.',
        toastType: AppToastType.warning,
      );
      return;
    }

    final otp = _clipboardOtp;
    if (otp == null || otp.isEmpty) {
      await _refreshClipboardOtp();
      return;
    }

    _applyOtpString(otp);
    HapticFeedback.lightImpact();
    AppSnackbar.show(context, 'OTP pasted from clipboard.');

    if (!mounted) {
      return;
    }

    await _attemptAutoSubmit(isLoading: ref.read(authLoadingProvider));
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() {
      _resendCooldownSeconds = _resendCooldownDurationSeconds;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendCooldownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _resendCooldownSeconds = 0;
        });
        return;
      }

      setState(() {
        _resendCooldownSeconds -= 1;
      });
    });
  }

  String _buildOtpFeedbackMessage(OtpSendResponse feedback) {
    if (feedback.notificationShown) {
      return 'Notification sent. Use Copy OTP for faster sign-in.';
    }

    switch ((feedback.notificationFailureReason ?? '').trim()) {
      case 'permission_denied':
        return 'Notification permission is disabled. Enter OTP manually or enable notifications.';
      case 'otp_missing_from_response':
        return 'OTP sent successfully, but this backend did not return OTP in response. Use your primary OTP channel.';
      case 'notification_mode_disabled':
        return 'OTP sent. Device notification preview is disabled for this build. Enter OTP manually.';
      default:
        return 'OTP sent. If notification is unavailable, use OTP from your primary channel.';
    }
  }

  Color _resolveOtpFeedbackBackground(
    OtpSendResponse feedback,
    ColorScheme colorScheme,
  ) {
    if (feedback.notificationShown) {
      return colorScheme.primaryContainer;
    }

    if ((feedback.notificationFailureReason ?? '').trim() ==
        'permission_denied') {
      return colorScheme.errorContainer;
    }

    return colorScheme.secondaryContainer;
  }

  Color _resolveOtpFeedbackForeground(
    OtpSendResponse feedback,
    ColorScheme colorScheme,
  ) {
    if (feedback.notificationShown) {
      return colorScheme.onPrimaryContainer;
    }

    if ((feedback.notificationFailureReason ?? '').trim() ==
        'permission_denied') {
      return colorScheme.onErrorContainer;
    }

    return colorScheme.onSecondaryContainer;
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _clipboardTimer?.cancel();
    _shakeController.dispose();
    for (final controller in _digitControllers) {
      controller.dispose();
    }
    for (final node in _digitFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = _resolveArgs();
    final isLoading = ref.watch(authLoadingProvider);
    final otpFeedback = ref.watch(otpSendFeedbackProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maskedPhone = args.phone.trim().isEmpty
        ? 'your registered mobile number'
        : LoginFormValidators.maskPhoneForOtp(args.phone);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const AppAppBar(title: 'Verify OTP'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Stack(
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const SizedBox(height: 12),
                          Text(
                            'Enter Verification Code',
                            style: CarbonTheme.authTitle(
                              context,
                            ).copyWith(color: colorScheme.primary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please enter the 6-digit OTP sent to your registered contact.',
                            style: CarbonTheme.authSubtitle(context),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Use the latest OTP sent to $maskedPhone.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.72,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (otpFeedback != null)
                            Builder(
                              builder: (context) {
                                final text = _buildOtpFeedbackMessage(
                                  otpFeedback,
                                );
                                final background =
                                    _resolveOtpFeedbackBackground(
                                      otpFeedback,
                                      colorScheme,
                                    );
                                final foreground =
                                    _resolveOtpFeedbackForeground(
                                      otpFeedback,
                                      colorScheme,
                                    );

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: background,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    text,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: foreground,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 22),
                          AnimatedBuilder(
                            animation: _shakeAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(_shakeAnimation.value, 0),
                                child: child,
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List<Widget>.generate(6, (index) {
                                return SizedBox(
                                  width: 46,
                                  child: TextField(
                                    controller: _digitControllers[index],
                                    focusNode: _digitFocusNodes[index],
                                    enabled: !isLoading,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: CarbonTheme.otpDigit(context),
                                    maxLength: 1,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      counterText: '',
                                      filled: true,
                                      fillColor:
                                          colorScheme.surfaceContainerHighest,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onChanged: (value) => _handleOtpChanged(
                                      index,
                                      value,
                                      isLoading: isLoading,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          if (isLoading)
                            Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Verifying OTP...',
                                    style: textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 18),
                          Opacity(
                            opacity: _resendCooldownSeconds > 0 ? 0.45 : 1,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.secondary,
                                side: BorderSide(color: colorScheme.secondary),
                              ),
                              onPressed: isLoading || _resendCooldownSeconds > 0
                                  ? null
                                  : _handleResend,
                              child: Text(
                                _resendCooldownSeconds > 0
                                    ? 'Resend OTP in ${_resendCooldownSeconds.toString().padLeft(2, '0')}s'
                                    : 'Resend OTP',
                              ),
                            ),
                          ),
                          if (_resendCooldownSeconds > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'You can request another OTP after the countdown completes.',
                                textAlign: TextAlign.center,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.72,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.tertiary,
                            ),
                            onPressed: isLoading
                                ? null
                                : () => NavigationService.instance
                                      .pushReplacementNamed(RouteNames.login),
                            child: const Text('Back to Login'),
                          ),
                          if (args.flow == OtpAuthFlow.login)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Demo OTP Bypass',
                                    style: textTheme.titleSmall?.copyWith(
                                      color: colorScheme.onTertiaryContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Use OTP: $_demoBypassOtp',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onTertiaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'This signs in with a shared demo account so features load.',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: isLoading
                                          ? null
                                          : () async {
                                              _applyOtpString(_demoBypassOtp);
                                              await _attemptAutoSubmit(
                                                isLoading: ref.read(
                                                  authLoadingProvider,
                                                ),
                                              );
                                            },
                                      child: const Text('Use Demo OTP'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                      ),
                      if ((_clipboardOtp ?? '').isNotEmpty && !_isOtpComplete)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: ActionChip(
                            label: const Text('Paste OTP'),
                            avatar: const Icon(
                              Icons.content_paste_rounded,
                              size: 18,
                            ),
                            onPressed: isLoading ? null : _handlePasteOtp,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
