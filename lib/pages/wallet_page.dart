import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../wallet/wallet_service.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late final WalletService _svc;
  late final String _uid;

  @override
  void initState() {
    super.initState();
    _svc = WalletService(FirebaseFirestore.instance);
    _uid = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<void> _showDepositSheet() async {
    final c = TextEditingController();
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Demo Coins',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: 'e.g. 100',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final amt = double.tryParse(c.text.trim()) ?? 0;
                try {
                  await _svc.deposit(_uid, amt);
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Top Up'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showWithdrawSheet() async {
    final c = TextEditingController();
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Withdraw Demo Coins',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: 'e.g. 50',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () async {
                final amt = double.tryParse(c.text.trim()) ?? 0;
                try {
                  await _svc.withdraw(_uid, amt);
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Withdraw'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Balance card
          StreamBuilder<double>(
            stream: _svc.balanceStream(_uid),
            builder: (_, snap) {
              final bal = (snap.data ?? 0).toStringAsFixed(2);
              return Card(
                child: ListTile(
                  title: const Text('Demo Coins'),
                  subtitle: Text(bal, style: const TextStyle(fontSize: 20)),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _showDepositSheet,
                        child: const Text('Top Up'),
                      ),
                      FilledButton.tonal(
                        onPressed: _showWithdrawSheet,
                        child: const Text('Withdraw'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Transactions list
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _svc.txnsStream(_uid, limit: 100),
            builder: (_, snap) {
              final items = snap.data ?? const [];
              if (items.isEmpty) {
                return const Text('No transactions yet');
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final t = items[i];
                  final type = (t['type'] ?? '').toString();
                  final amt = ((t['amount'] as num?)?.toDouble() ?? 0)
                      .toStringAsFixed(2);
                  final ts = t['createdAt'];
                  String when = '';
                  if (ts is Timestamp) {
                    when = ts.toDate().toLocal().toString();
                  }
                  return ListTile(
                    leading: Icon(
                      type == 'deposit'
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                    ),
                    title: Text(
                      type == 'deposit'
                          ? 'Deposit'
                          : (type == 'withdraw')
                          ? 'Withdraw'
                          : type,
                    ),
                    subtitle: when.isEmpty ? null : Text(when),
                    trailing: Text(
                      (type == 'deposit' ? '+$amt' : '-$amt'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: type == 'deposit' ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
