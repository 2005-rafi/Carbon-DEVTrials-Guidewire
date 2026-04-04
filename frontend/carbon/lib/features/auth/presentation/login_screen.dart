import 'package:carbon/core/router/navigation_service.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/core/constants/app_constants.dart';
import 'package:carbon/features/auth/presentation/login_form_utils.dart';
import 'package:carbon/features/auth/provider/auth_feature_provider.dart';
import 'package:carbon/shared/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  LoginUiState _uiState = LoginUiState.idle;
  String? _inlineError;

  Future<void> _handleLogin() async {
    if (_uiState == LoginUiState.loading) {
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() {
        _uiState = LoginUiState.failure;
      });
      AppSnackbar.show(
        context,
        'Please correct the highlighted fields.',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _uiState = LoginUiState.loading;
      _inlineError = null;
    });

    final normalizedPhone = LoginFormValidators.normalizePhone(
      _phoneController.text,
    );

    final ok = await ref
        .read(authActionProvider)
        .login(normalizedPhone, _passwordController.text);

    if (!mounted) {
      return;
    }

    if (!ok) {
      final errorText =
          ref.read(authErrorProvider) ??
          'Unable to sign in. Please check your credentials.';

      setState(() {
        _uiState = LoginUiState.failure;
        _inlineError = errorText;
      });

      AppSnackbar.show(context, errorText, isError: true);
      return;
    }

    setState(() {
      _uiState = LoginUiState.success;
      _inlineError = null;
    });

    await NavigationService.instance.pushNamedAndRemoveUntil(
      RouteNames.dashboard,
      (route) => false,
    );
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
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerLoading = ref.watch(authLoadingProvider);
    final authError = ref.watch(authErrorProvider);
    final isLoading = _uiState == LoginUiState.loading || providerLoading;
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
                        style: textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue protected earnings with secure access.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.74),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _phoneController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[
                          AutofillHints.telephoneNumber,
                        ],
                        maxLength: 15,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        inputFormatters: <TextInputFormatter>[
                          PhoneMaskTextInputFormatter(),
                        ],
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: LoginFormValidators.validatePhone,
                        onChanged: (_) => _clearFailureState(),
                        buildCounter:
                            (
                              BuildContext context, {
                              required int currentLength,
                              required bool isFocused,
                              required int? maxLength,
                            }) {
                              return null;
                            },
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          hintText: '+91 98765 43210',
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: colorScheme.primary,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !isLoading,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const <String>[AutofillHints.password],
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: LoginFormValidators.validatePassword,
                        onChanged: (_) => _clearFailureState(),
                        onFieldSubmitted: (_) {
                          if (!isLoading) {
                            _handleLogin();
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: colorScheme.primary,
                          ),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (activeError != null)
                        _buildInlineError(context, activeError),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: colorScheme.tertiary,
                                ),
                              )
                            : Text(
                                'Sign In Securely',
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: colorScheme.secondary,
                        ),
                        onPressed: isLoading
                            ? null
                            : () => NavigationService.instance.pushNamed(
                                RouteNames.register,
                              ),
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
