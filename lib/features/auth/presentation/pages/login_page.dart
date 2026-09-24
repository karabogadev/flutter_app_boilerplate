import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_error_listener.dart';
import '../widgets/auth_submit_button.dart';

/// Navigation after a successful login is handled by the app-level auth
/// listener in `app.dart`; this page only renders the form and errors.
@RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        LoginEvent(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  String? _required(String? value) => (value == null || value.isEmpty)
      ? LocaleKeys.validationRequiredField.tr()
      : null;

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return LocaleKeys.validationRequiredField.tr();
    }
    return value.trim().isValidEmail
        ? null
        : LocaleKeys.validationInvalidEmail.tr();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthErrorListener(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    LocaleKeys.authWelcomeBack.tr(),
                    style: context.textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    LocaleKeys.authSignInSubtitle.tr(),
                    style: context.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppTextField.email(
                    controller: _emailController,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField.password(
                    controller: _passwordController,
                    validator: _required,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Navigate to forgot password
                      },
                      child: Text(LocaleKeys.authForgotPassword.tr()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AuthSubmitButton(
                    text: LocaleKeys.authLogin.tr(),
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          LocaleKeys.authDontHaveAccount.tr(),
                          style: context.textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () => unawaited(
                          context.router.push(const RegisterRoute()),
                        ),
                        child: Text(LocaleKeys.authRegister.tr()),
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
