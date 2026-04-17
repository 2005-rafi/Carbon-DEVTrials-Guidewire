import 'package:carbon/features/auth/presentation/register_form_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({
    super.key,
    required this.verifiedPhone,
    required this.enabled,
    required this.emailShakeNonce,
    required this.onFormChanged,
  });

  final String verifiedPhone;
  final bool enabled;
  final int emailShakeNonce;
  final ValueChanged<ProfileFinalizationFormValue> onFormChanged;

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  late final AnimationController _emailShakeController;
  late final Animation<double> _emailShakeAnimation;

  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController(text: widget.verifiedPhone);

    _emailShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _emailShakeAnimation =
        TweenSequence<double>(<TweenSequenceItem<double>>[
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
        ]).animate(
          CurvedAnimation(parent: _emailShakeController, curve: Curves.easeOut),
        );

    _fullNameController.addListener(_notifyFormChanged);
    _emailController.addListener(_notifyFormChanged);
    _notifyFormChanged();
  }

  @override
  void didUpdateWidget(covariant RegistrationForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verifiedPhone != widget.verifiedPhone) {
      _phoneController.text = widget.verifiedPhone;
    }
    if (oldWidget.emailShakeNonce != widget.emailShakeNonce) {
      _emailShakeController.forward(from: 0);
      HapticFeedback.heavyImpact();
    }
  }

  void _notifyFormChanged() {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();

    final isEmailValid = RegisterFormValidators.isValidEmail(email);
    final isValid =
        RegisterFormValidators.validateFullName(fullName) == null &&
        RegisterFormValidators.validateEmail(email) == null;
    final isDirty = fullName.isNotEmpty || email.isNotEmpty;

    widget.onFormChanged(
      ProfileFinalizationFormValue(
        fullName: fullName,
        email: email,
        isEmailValid: isEmailValid,
        isDirty: isDirty,
        isValid: isValid,
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required BuildContext context,
    required String label,
    required String hint,
    required Widget prefixIcon,
    Widget? suffixIcon,
    Color? fillColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor ?? colorScheme.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.42),
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

  Widget _buildEmailSuffixIcon() {
    final email = _emailController.text.trim();
    final isValid = RegisterFormValidators.isValidEmail(email);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: isValid
          ? const Icon(
              Icons.verified_rounded,
              key: ValueKey<String>('email_valid'),
              color: Color(0xFF2E7D32),
            )
          : const Icon(
              Icons.alternate_email_rounded,
              key: ValueKey<String>('email_idle'),
            ),
    );
  }

  Widget _buildVerifiedPhoneBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.verified_user_rounded,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Verified',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_notifyFormChanged);
    _emailController.removeListener(_notifyFormChanged);
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _emailShakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextFormField(
          controller: _fullNameController,
          focusNode: _fullNameFocus,
          enabled: widget.enabled,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          autofillHints: const <String>[AutofillHints.name],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: RegisterFormValidators.validateFullName,
          onFieldSubmitted: (_) => _emailFocus.requestFocus(),
          decoration: _fieldDecoration(
            context: context,
            label: 'Full Name',
            hint: 'Avery Johnson',
            prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedBuilder(
          animation: _emailShakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_emailShakeAnimation.value, 0),
              child: child,
            );
          },
          child: TextFormField(
            controller: _emailController,
            focusNode: _emailFocus,
            enabled: widget.enabled,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.email],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: RegisterFormValidators.validateEmail,
            decoration: _fieldDecoration(
              context: context,
              label: 'Email Address',
              hint: 'you@carbon.com',
              prefixIcon: Icon(
                Icons.alternate_email_rounded,
                color: colorScheme.primary,
              ),
              suffixIcon: _buildEmailSuffixIcon(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _phoneController,
          enabled: true,
          readOnly: true,
          showCursor: false,
          enableInteractiveSelection: false,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          decoration: _fieldDecoration(
            context: context,
            label: 'Mobile Number',
            hint: '',
            fillColor: colorScheme.surfaceContainerHigh,
            prefixIcon: Icon(Icons.phone_outlined, color: colorScheme.primary),
            suffixIcon: _buildVerifiedPhoneBadge(context),
          ),
        ),
      ],
    );
  }
}
