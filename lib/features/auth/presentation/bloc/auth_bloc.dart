import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Presentation-side mirror of [AuthRepository]'s session.
///
/// Besides handling user actions, it follows
/// [AuthRepository.sessionChanges], so a session that ends elsewhere (e.g. a
/// rejected refresh token) is reflected in the UI too.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<_SessionChanged>(_onSessionChanged);

    _sessionSubscription = authRepository.sessionChanges.listen(
      (user) => add(_SessionChanged(user)),
    );
  }

  final AuthRepository _authRepository;
  late final StreamSubscription<User?> _sessionSubscription;

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    switch (await _authRepository.restoreSession()) {
      case Ok(value: final User user):
        emit(Authenticated(user));
      case Ok() || Err():
        emit(const Unauthenticated());
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    _emitSignInResult(
      await _authRepository.login(email: event.email, password: event.password),
      emit,
    );
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    _emitSignInResult(
      await _authRepository.register(
        email: event.email,
        password: event.password,
        name: event.name,
      ),
      emit,
    );
  }

  /// Always ends in [Unauthenticated]: the repository ends the in-memory
  /// session even when clearing storage fails (that failure is logged by
  /// `Result.guard`). Emitting an [AuthError] here would race with the
  /// [_SessionChanged] event and surface as a stray error on the Login page.
  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await _authRepository.logout();
    emit(const Unauthenticated());
  }

  void _onSessionChanged(_SessionChanged event, Emitter<AuthState> emit) {
    emit(switch (event.user) {
      final User user => Authenticated(user),
      null => const Unauthenticated(),
    });
  }

  void _emitSignInResult(Result<User> result, Emitter<AuthState> emit) {
    switch (result) {
      case Ok(:final value):
        emit(Authenticated(value));
      case Err(:final failure):
        emit(AuthError(failure.message));
    }
  }

  @override
  Future<void> close() async {
    await _sessionSubscription.cancel();
    return super.close();
  }
}
