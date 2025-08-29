import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_app/energy/energy_api.dart';
import 'package:energy_app/energy/energy_repository.dart';
import 'package:energy_app/pages/wallet_page.dart';
import 'package:energy_app/util/session.dart';
import 'package:energy_app/wallet/wallet_service.dart';
import 'package:energy_app/widgets/app_drawer.dart';
import 'package:energy_app/widgets/scrollable_energy_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final wallet = WalletService(FirebaseFirestore.instance);
    final energyRepo = EnergyRepository(FirebaseFirestore.instance);

    return Scaffold(
      drawer: AppDrawer(),
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
            onPressed: () => Session.logout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mini wallet card (live balance)
          StreamBuilder<String>(
            stream: wallet.balanceStream(uid),
            builder: (context, snap) {
              final bal = (snap.data ?? '0.00');
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () async {
                  try {
                    await EnergyApi.I.upsertRange(hours: 3);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Synced last 3h')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Sync 3h'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () async {
                  try {
                    await EnergyApi.I.upsertBucket();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ticked 1 bucket')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Tick'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Battery gauge (optional)
          StreamBuilder<Map<String, dynamic>?>(
            stream: energyRepo.battery(uid),
            builder: (context, snap) {
              final m = snap.data;
              if (m == null) return const SizedBox.shrink();
              final cap = (m['capacityKwh'] as num?)?.toDouble() ?? 0;
              final soc = (m['socKwh'] as num?)?.toDouble() ?? 0;
              final pct = cap > 0 ? (soc / cap).clamp(0.0, 1.0) : 0.0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Battery: ${soc.toStringAsFixed(2)} / ${cap.toStringAsFixed(1)} kWh',
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: pct),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          StreamBuilder<List<Map<String, dynamic>>>(
            stream: energyRepo.lastNH(uid, hours: 12), // load 12h to scroll
            builder: (context, snap) {
              final bars = snap.data ?? const [];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Energy (scroll • 15m buckets)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ScrollableEnergyChart(bars: bars), // <-- new widget
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
