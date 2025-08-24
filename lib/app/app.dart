import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/logic/auth_bloc.dart';
import '../features/auth/logic/login_cubit.dart';
import '../features/auth/view/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AuthRepository();

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          redirect: (ctx, state) {
            final user = FirebaseAuth.instance.currentUser;
            return user == null ? '/login' : '/home';
          },
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => BlocProvider(
            create: (_) => LoginCubit(repo),
            child: const LoginScreen(),
          ),
        ),
        GoRoute(path: '/home', builder: (_, __) => const _HomeScreen()),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(repo)..add(const AuthSubscriptionRequested()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Energy Demo',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
        routerConfig: router,
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthSignOutRequested()),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(child: Text('Welcome, ${user.email ?? user.uid}')),
    );
  }
}
