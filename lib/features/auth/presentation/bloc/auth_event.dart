part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Restores a persisted session. Dispatched once, from the splash screen.
final class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

final class LoginEvent extends AuthEvent {
  const LoginEvent({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class RegisterEvent extends AuthEvent {
  const RegisterEvent({
    required this.email,
    required this.password,
    this.name,
  });

  final String email;
  final String password;
  final String? name;

  @override
  List<Object?> get props => [email, password, name];
}

final class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

/// Internal: the repository's session changed outside of a user action.
final class _SessionChanged extends AuthEvent {
  const _SessionChanged(this.user);

  final User? user;

  @override
  List<Object?> get props => [user];
}
