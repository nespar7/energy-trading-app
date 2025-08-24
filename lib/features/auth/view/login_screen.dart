import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/logic/login_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailC = TextEditingController();
  final passC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state.status == LoginStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error ?? 'Auth error')),
            );
          }
        },
        builder: (context, state) {
          final busy = state.status == LoginStatus.loading;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: emailC,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: passC,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () => context.read<LoginCubit>().signInWithEmail(
                          emailC.text.trim(),
                          passC.text,
                        ),
                  child: busy
                      ? const CircularProgressIndicator()
                      : const Text('Sign in'),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => context.read<LoginCubit>().registerWithEmail(
                          emailC.text.trim(),
                          passC.text,
                        ),
                  child: const Text('Create account'),
                ),
                const Divider(height: 32),
                OutlinedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Continue with Google'),
                  onPressed: busy
                      ? null
                      : () => context.read<LoginCubit>().signInWithGoogle(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
