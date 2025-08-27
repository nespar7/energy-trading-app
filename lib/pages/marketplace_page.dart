import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../market/market_api.dart';
import '../market/market_repository_firestore.dart';
import '../widgets/app_drawer.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});
  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final String _uid;
  late final MarketFsRepo _repo;

  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _side = 'buy';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    _repo = MarketFsRepo(FirebaseFirestore.instance);
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _place() async {
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    if (qty <= 0 || price <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter valid qty & price')));
      return;
    }
    setState(() => _busy = true);
    try {
      await MarketApi.I.placeOrder(side: _side, qty: qty, price: price);
      _qtyCtrl.clear();
      _priceCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Order placed')));
        _tab.animateTo(0);
      }
    } catch (e) {
      final msg = e.toString();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Order failed: $msg')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(String orderId) async {
    setState(() => _busy = true);
    try {
      await MarketApi.I.cancelOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Order cancelled')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cancel failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Marketplace'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Orderbook'),
            Tab(text: 'My Orders'),
            Tab(text: 'My Trades'),
            Tab(text: 'New Order'),
          ],
        ),
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Stack(
          children: [
            TabBarView(
              controller: _tab,
              children: [
                _OrderbookTab(repo: _repo),
                _MyOrdersTab(repo: _repo, uid: _uid, onCancel: _cancel),
                _MyTradesTab(repo: _repo, uid: _uid),
                _NewOrderTab(
                  side: _side,
                  onSideChanged: (v) => setState(() => _side = v),
                  qtyCtrl: _qtyCtrl,
                  priceCtrl: _priceCtrl,
                  onSubmit: _place,
                ),
              ],
            ),
            if (_busy)
              const Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Color(0x55FFFFFF),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderbookTab extends StatelessWidget {
  const _OrderbookTab({required this.repo});
  final MarketFsRepo repo;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: repo.orderbook(),
      builder: (_, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error: ${snap.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snap.data!;
        if (orders.isEmpty) return const Center(child: Text('No open orders'));
        // split & sort client-side for nicer display
        final buys = orders.where((o) => o['side'] == 'buy').toList()
          ..sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
        final sells = orders.where((o) => o['side'] == 'sell').toList()
          ..sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Text(
              'Buys (best first)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ...buys.map(
              (o) => ListTile(
                leading: const Icon(Icons.north_east, color: Colors.green),
                title: Text(
                  'BUY  ${(o['qtyKwhOpen'] as num).toStringAsFixed(2)} kWh',
                ),
                subtitle: Text(
                  '₹ ${(o['price'] as num).toStringAsFixed(2)} / kWh',
                ),
                trailing: Text(o['status']),
              ),
            ),
            const Divider(),
            const Text(
              'Sells (best first)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ...sells.map(
              (o) => ListTile(
                leading: const Icon(Icons.south_west, color: Colors.red),
                title: Text(
                  'SELL ${(o['qtyKwhOpen'] as num).toStringAsFixed(2)} kWh',
                ),
                subtitle: Text(
                  '₹ ${(o['price'] as num).toStringAsFixed(2)} / kWh',
                ),
                trailing: Text(o['status']),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MyOrdersTab extends StatelessWidget {
  const _MyOrdersTab({
    required this.repo,
    required this.uid,
    required this.onCancel,
  });
  final MarketFsRepo repo;
  final String uid;
  final void Function(String orderId) onCancel;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: repo.myOrders(uid),
      builder: (_, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error: ${snap.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return const Center(child: Text('You have no orders'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final o = list[i];
            final open = o['status'] == 'open';
            return ListTile(
              title: Text(
                '${(o['side'] as String).toUpperCase()} '
                '${(o['qtyKwhOpen'] as num).toStringAsFixed(2)} kWh @ ₹${(o['price'] as num).toStringAsFixed(2)}',
              ),
              subtitle: Text('Status: ${o['status']}'),
              trailing: open
                  ? TextButton(
                      onPressed: () => onCancel(o['id'] as String),
                      child: const Text('Cancel'),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

class _MyTradesTab extends StatelessWidget {
  const _MyTradesTab({required this.repo, required this.uid});
  final MarketFsRepo repo;
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: repo.myTrades(uid),
      builder: (_, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error: ${snap.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final trades = snap.data!;
        if (trades.isEmpty) return const Center(child: Text('No trades yet'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: trades.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final t = trades[i];
            final isBuyer = t['buyerUid'] == uid;
            final qty = (t['qtyKwh'] as num).toStringAsFixed(2);
            final price = (t['price'] as num).toStringAsFixed(2);
            final total = ((t['qtyKwh'] as num) * (t['price'] as num))
                .toStringAsFixed(2);
            return ListTile(
              leading: Icon(
                isBuyer ? Icons.shopping_cart : Icons.payments,
                color: isBuyer ? Colors.green : Colors.blue,
              ),
              title: Text('${isBuyer ? 'Bought' : 'Sold'} $qty kWh @ ₹$price'),
              subtitle: Text('${(t['ts'] as Timestamp).toDate().toLocal()}'),
              trailing: Text(
                isBuyer ? '-$total' : '+$total',
                style: TextStyle(
                  color: isBuyer ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _NewOrderTab extends StatelessWidget {
  const _NewOrderTab({
    required this.side,
    required this.onSideChanged,
    required this.qtyCtrl,
    required this.priceCtrl,
    required this.onSubmit,
  });

  final String side;
  final ValueChanged<String> onSideChanged;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'buy', label: Text('Buy')),
            ButtonSegment(value: 'sell', label: Text('Sell')),
          ],
          selected: {side},
          onSelectionChanged: (s) => onSideChanged(s.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: qtyCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantity (kWh)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: priceCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Price (coins/kWh)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onSubmit, child: const Text('Place Order')),
        const SizedBox(height: 12),
        const Text(
          'Tip: Sell price must be ≤ best buy to fill immediately (and vice-versa).',
        ),
      ],
    );
  }
}
