import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool loading = false;

  final auth = AuthService();

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _emailFlow() async {
    setState(() => loading = true);
    try {
      await auth.signInWithEmail(emailC.text.trim(), passC.text);
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? e.code);
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _googleFlow() async {
    setState(() => loading = true);
    final cred = await auth.signInWithGoogle();
    if (cred == null) _showSnack('Google sign-in cancelled');
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final busy = loading;
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
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
              onPressed: busy ? null : _emailFlow,
              child: busy
                  ? const CircularProgressIndicator()
                  : const Text('Continue'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy ? null : _googleFlow,
              icon: const Icon(Icons.login),
              label: const Text('Continue with Google'),
            ),
          ],
        ),
      ),
    );
  }
}
