import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../util/transaction_util.dart';

class TransactionTile extends StatelessWidget {
  final Map<String, dynamic> t;
  const TransactionTile({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final type = (t['type'] ?? '').toString();
    final s = TransactionUtil.getStyle(type);

    final amt = ((t['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2);
    final ts = t['createdAt'];
    String when = '';
    if (ts is Timestamp) when = ts.toDate().toLocal().toString();

    return ListTile(
      leading: Icon(s.icon, color: s.color),
      title: Text(s.label),
      subtitle: when.isEmpty ? null : Text(when),
      trailing: Text(
        '${s.prefix}$amt',
        style: TextStyle(fontWeight: FontWeight.w600, color: s.color),
      ),
    );
  }
}
