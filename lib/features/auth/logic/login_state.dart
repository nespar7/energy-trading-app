part of 'login_cubit.dart';

enum LoginStatus { idle, loading, success, failure }

class LoginState extends Equatable {
  final LoginStatus status;
  final String? error;

  const LoginState({this.status = LoginStatus.idle, this.error});

  LoginState copyWith({LoginStatus? status, String? error}) =>
      LoginState(status: status ?? this.status, error: error);

  @override
  List<Object?> get props => [status, error];
}
