import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_error_listener.dart';
import '../widgets/auth_submit_button.dart';

/// Navigation after a successful registration is handled by the app-level
/// auth listener in `app.dart`.
@RoutePage()
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const _minPasswordLength = 6;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      context.read<AuthBloc>().add(
            RegisterEvent(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              name: name.isNotEmpty ? name : null,
            ),
          );
    }
  }

  String? _validateEmail(String? value) => (value == null || value.isEmpty)
      ? LocaleKeys.validationRequiredField.tr()
      : null;

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return LocaleKeys.validationRequiredField.tr();
    }
    if (value.length < _minPasswordLength) {
      return LocaleKeys.validationPasswordTooShort.tr();
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return LocaleKeys.validationRequiredField.tr();
    }
    if (value != _passwordController.text) {
      return LocaleKeys.validationPasswordsDontMatch.tr();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: AuthErrorListener(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    LocaleKeys.authCreateAccount.tr(),
                    style: context.textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    LocaleKeys.authSignUpSubtitle.tr(),
                    style: context.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    controller: _nameController,
                    labelText: LocaleKeys.authName.tr(),
                    hintText: LocaleKeys.authNameHint.tr(),
                    prefixIcon: const Icon(Icons.person_outlined),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField.email(
                    controller: _emailController,
                    labelText: LocaleKeys.authEmail.tr(),
                    hintText: LocaleKeys.authEmailHint.tr(),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField.password(
                    controller: _passwordController,
                    labelText: LocaleKeys.authPassword.tr(),
                    hintText: LocaleKeys.authPasswordHint.tr(),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField.password(
                    controller: _confirmPasswordController,
                    labelText: LocaleKeys.authConfirmPassword.tr(),
                    hintText: LocaleKeys.authConfirmPasswordHint.tr(),
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AuthSubmitButton(
                    text: LocaleKeys.authRegister.tr(),
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          LocaleKeys.authAlreadyHaveAccount.tr(),
                          style: context.textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () => unawaited(context.router.maybePop()),
                        child: Text(LocaleKeys.authLogin.tr()),
                      ),
                    ],
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
