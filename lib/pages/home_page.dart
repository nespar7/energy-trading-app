import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_app/pages/wallet_page.dart';
import 'package:energy_app/wallet/wallet_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/auth_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final wallet = WalletService(FirebaseFirestore.instance);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Wallet',
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const WalletPage()));
            },
          ),
          IconButton(
            tooltip: 'signout',
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mini wallet card (live balance)
          StreamBuilder<double>(
            stream: wallet.balanceStream(uid),
            builder: (context, snap) {
              final bal = (snap.data ?? 0).toStringAsFixed(2);
              return Card(
                child: ListTile(
                  title: const Text('Wallet'),
                  subtitle: Text(
                    '$bal coins',
                    style: const TextStyle(fontSize: 18),
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WalletPage()),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Your existing content placeholder
          const Center(child: Text('Logged in!')),
        ],
      ),
    );
  }
}
