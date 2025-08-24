import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/auth_repository.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _repo;
  LoginCubit(this._repo) : super(const LoginState());

  Future<void> signInWithEmail(String email, String password) async {
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      await _repo.signInWithEmail(email, password);
      emit(state.copyWith(status: LoginStatus.success));
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.failure, error: e.toString()));
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      await _repo.registerWithEmail(email, password);
      emit(state.copyWith(status: LoginStatus.success));
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.failure, error: e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      await _repo.signInWithGoogle();
      emit(state.copyWith(status: LoginStatus.success));
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.failure, error: e.toString()));
    }
  }

  void reset() => emit(const LoginState());
}
