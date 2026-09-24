import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_button.dart';
import '../bloc/auth_bloc.dart';

/// Primary form button that shows a spinner while [AuthBloc] is busy.
///
/// Uses [BlocSelector] so it rebuilds only when the loading flag flips, not on
/// every auth state change.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthBloc, AuthState, bool>(
      selector: (state) => state is AuthLoading,
      builder: (context, isLoading) => AppButton.primary(
        text: text,
        isExpanded: true,
        isLoading: isLoading,
        onPressed: onPressed,
      ),
    );
  }
}
