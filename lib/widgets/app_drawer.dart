import 'package:energy_app/util/session.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../pages/home_page.dart';
import '../pages/wallet_page.dart';
import '../pages/marketplace_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _go(BuildContext context, Widget page) {
    Navigator.of(context).pop(); // close drawer
    // If you're already on the same page class, do nothing
    if (ModalRoute.of(context)?.settings.name == page.runtimeType.toString()) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => page,
        settings: RouteSettings(name: page.runtimeType.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.displayName ?? 'User'),
              accountEmail: Text(user?.email ?? user?.uid ?? ''),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.person),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => _go(context, const HomePage()),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Wallet'),
              onTap: () => _go(context, const WalletPage()),
            ),
            ListTile(
              leading: const Icon(Icons.storefront),
              title: const Text('Marketplace'),
              onTap: () => _go(context, const MarketplacePage()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Session.logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
