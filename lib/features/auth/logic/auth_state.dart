part of 'auth_bloc.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;

  const AuthState._(this.status, this.user);
  const AuthState.unknown() : this._(AuthStatus.unknown, null);
  const AuthState.authenticated(User u) : this._(AuthStatus.authenticated, u);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated, null);

  @override
  List<Object?> get props => [status, user?.uid];
}
