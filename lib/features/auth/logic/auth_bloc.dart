import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(const AuthState.unknown()) {
    on<AuthSubscriptionRequested>((_, emit) async {
      await emit.forEach<User?>(
        _repo.authStateChanges(),
        onData: (user) => user == null
            ? const AuthState.unauthenticated()
            : AuthState.authenticated(user),
      );
    });

    on<AuthSignOutRequested>((_, emit) async {
      await _repo.signOut();
    });
  }
}
