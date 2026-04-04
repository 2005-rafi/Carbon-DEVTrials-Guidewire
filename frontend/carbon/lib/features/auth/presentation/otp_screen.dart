import 'package:carbon/core/router/navigation_service.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/features/auth/provider/auth_feature_provider.dart';
import 'package:carbon/shared/widgets/app_appbar.dart';
import 'package:carbon/shared/widgets/app_button.dart';
import 'package:carbon/shared/widgets/app_snackbar.dart';
import 'package:carbon/shared/widgets/app_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  String? _otpValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'OTP is required';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(text)) {
      return 'Enter a valid 6-digit OTP';
    }
    return null;
  }

  Future<void> _handleVerify() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      AppSnackbar.show(context, 'Please enter a valid OTP.', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();

    final ok = await ref
        .read(authActionProvider)
        .verifyOtp(_otpController.text.trim());

    if (!mounted) {
      return;
    }

    if (!ok) {
      AppSnackbar.show(
        context,
        ref.read(authErrorProvider) ?? 'OTP verification failed.',
        isError: true,
      );
      return;
    }

    AppSnackbar.show(context, 'OTP verified successfully.');
    await NavigationService.instance.pushNamedAndRemoveUntil(
      RouteNames.dashboard,
      (route) => false,
    );
  }

  Future<void> _handleResend() async {
    FocusScope.of(context).unfocus();

    final ok = await ref.read(authActionProvider).resendOtp();
    if (!mounted) {
      return;
    }

    if (!ok) {
      AppSnackbar.show(
        context,
        ref.read(authErrorProvider) ?? 'Unable to resend OTP.',
        isError: true,
      );
      return;
    }

    AppSnackbar.show(context, 'A new OTP has been sent.');
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SizedBox(height: 12),
                        Text(
                          'Enter Verification Code',
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please enter the 6-digit OTP sent to your registered contact.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.75,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outline.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: AppTextField(
                            controller: _otpController,
                            labelText: 'OTP',
                            hintText: '6-digit code',
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            maxLength: 6,
                            maxLines: 1,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            prefixIcon: Icon(
                              Icons.verified_user_outlined,
                              color: colorScheme.primary,
                            ),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: _otpValidator,
                            onFieldSubmitted: (_) {
                              if (!isLoading) {
                                _handleVerify();
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: isLoading
                              ? 'Verifying OTP...'
                              : 'Verify & Go To Dashboard',
                          onPressed: isLoading ? null : _handleVerify,
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.secondary,
                            side: BorderSide(color: colorScheme.secondary),
                          ),
                          onPressed: isLoading ? null : _handleResend,
                          child: const Text('Resend OTP'),
                        ),
                        const SizedBox(height: 4),
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
                        const SizedBox(height: 12),
                      ],
                    ),
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
