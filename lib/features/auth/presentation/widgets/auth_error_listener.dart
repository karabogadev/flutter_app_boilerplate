import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../bloc/auth_bloc.dart';

/// Shows [AuthError]s as a snackbar.
///
/// Only the topmost route reacts, so when Register is pushed over Login the
/// error isn't shown twice.
class AuthErrorListener extends StatelessWidget {
  const AuthErrorListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, current) => current is AuthError,
      listener: (context, state) {
        if (state is AuthError && (ModalRoute.isCurrentOf(context) ?? true)) {
          context.showSnackBar(state.failure.localizedMessage, isError: true);
        }
      },
      child: child,
    );
  }
}
