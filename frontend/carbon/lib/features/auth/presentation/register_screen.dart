import 'package:carbon/core/router/navigation_service.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/features/auth/presentation/register_form_utils.dart';
import 'package:carbon/features/auth/provider/auth_feature_provider.dart';
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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  RegisterUiState _uiState = RegisterUiState.idle;
  String? _inlineError;

  void _hideServiceBanner() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
  }

  bool _isServiceUnreachableError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('unable to reach the server') ||
        normalized.contains('service is currently unreachable') ||
        normalized.contains('connection') ||
        normalized.contains('timed out') ||
        normalized.contains('network');
  }

  void _showServiceBanner(String message) {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    messenger
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          backgroundColor: colorScheme.errorContainer,
          leading: Icon(
            Icons.wifi_off_rounded,
            color: colorScheme.onErrorContainer,
          ),
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: messenger.hideCurrentMaterialBanner,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: colorScheme.onErrorContainer,
              ),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
  }

  void _clearFailureState() {
    if (_uiState != RegisterUiState.failure && _inlineError == null) {
      return;
    }

    _hideServiceBanner();
    setState(() {
      _uiState = RegisterUiState.idle;
      _inlineError = null;
    });
    ref.read(authActionProvider).clearError();
  }

  void _onPasswordChanged() {
    _clearFailureState();
    if (_confirmPasswordController.text.isNotEmpty) {
      _formKey.currentState?.validate();
    }
  }

  Future<void> _handleRegister() async {
    if (_uiState == RegisterUiState.loading) {
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() {
        _uiState = RegisterUiState.failure;
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _uiState = RegisterUiState.loading;
      _inlineError = null;
    });

    final normalizedPhone = RegisterFormValidators.normalizePhoneForApi(
      _phoneController.text,
    );

    final ok = await ref
        .read(authActionProvider)
        .register(
          fullName: _nameController.text.trim(),
          phoneNumber: normalizedPhone,
          password: _passwordController.text,
        );

    if (!mounted) {
      return;
    }

    if (!ok) {
      final errorText =
          ref.read(authErrorProvider) ??
          'Unable to create account right now. Please try again.';
      final serviceDown = _isServiceUnreachableError(errorText);

      if (serviceDown) {
        _showServiceBanner(errorText);
      } else {
        _hideServiceBanner();
      }

      setState(() {
        _uiState = RegisterUiState.failure;
        _inlineError = serviceDown ? null : errorText;
      });
      return;
    }

    _hideServiceBanner();
    setState(() {
      _uiState = RegisterUiState.success;
      _inlineError = null;
    });

    await Navigator.of(context).pushReplacementNamed(RouteNames.otp);
  }

  InputDecoration _buildInputDecoration({
    required BuildContext context,
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: colorScheme.primary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 1.4),
      ),
      errorMaxLines: 2,
    );
  }

  Widget _buildInputFields(BuildContext context, {required bool isLoading}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextFormField(
          controller: _nameController,
          enabled: !isLoading,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const <String>[AutofillHints.name],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: RegisterFormValidators.validateFullName,
          onChanged: (_) => _clearFailureState(),
          decoration: _buildInputDecoration(
            context: context,
            label: 'Full Name',
            hint: 'Avery Johnson',
            icon: Icons.person_outline,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _phoneController,
          enabled: !isLoading,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const <String>[AutofillHints.telephoneNumber],
          maxLength: 15,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          inputFormatters: <TextInputFormatter>[
            IndianPhoneMaskTextInputFormatter(),
          ],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: RegisterFormValidators.validatePhone,
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
          decoration: _buildInputDecoration(
            context: context,
            label: 'Mobile Number',
            hint: '+91 98765 43210',
            icon: Icons.phone_outlined,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _passwordController,
          enabled: !isLoading,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          autofillHints: const <String>[AutofillHints.newPassword],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: RegisterFormValidators.validatePassword,
          onChanged: (_) => _onPasswordChanged(),
          decoration: _buildInputDecoration(
            context: context,
            label: 'Password',
            hint: 'Minimum 6 characters',
            icon: Icons.lock_outline,
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
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
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _confirmPasswordController,
          enabled: !isLoading,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          autofillHints: const <String>[AutofillHints.newPassword],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) => RegisterFormValidators.validateConfirmPassword(
            value,
            _passwordController.text,
          ),
          onChanged: (_) => _clearFailureState(),
          onFieldSubmitted: (_) {
            if (!isLoading) {
              _handleRegister();
            }
          },
          decoration: _buildInputDecoration(
            context: context,
            label: 'Confirm Password',
            hint: 'Re-enter password',
            icon: Icons.verified_user_outlined,
            suffixIcon: IconButton(
              tooltip: _obscureConfirmPassword
                  ? 'Show confirm password'
                  : 'Hide confirm password',
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              onPressed: isLoading
                  ? null
                  : () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionStack(BuildContext context, {required bool isLoading}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_inlineError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _inlineError!,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            ),
          ),
        FilledButton(
          onPressed: isLoading ? null : _handleRegister,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color: colorScheme.tertiary,
                  ),
                )
              : Text('Register', style: textTheme.labelLarge),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: isLoading
              ? null
              : () => NavigationService.instance.pushReplacementNamed(
                  RouteNames.login,
                ),
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: colorScheme.secondary,
          ),
          child: Text(
            'Already have an account? Login',
            style: textTheme.labelLarge,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _hideServiceBanner();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerLoading = ref.watch(authLoadingProvider);
    final isLoading = _uiState == RegisterUiState.loading || providerLoading;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          onPressed: isLoading
              ? null
              : () {
                  Navigator.of(context).maybePop();
                },
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: <Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'Start Your Journey',
                            style: textTheme.headlineLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Build your Carbon profile and secure every shift with trusted coverage.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.74,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildInputFields(context, isLoading: isLoading),
                          const SizedBox(height: 24),
                          _buildActionStack(context, isLoading: isLoading),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
