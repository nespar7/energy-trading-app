import 'package:flutter/material.dart';

typedef TxnRecord = ({String label, IconData icon, Color color, String prefix});

class TransactionUtil {
  static const Map<String, TxnRecord> _config = {
    'deposit': (
      label: 'deposit',
      icon: Icons.arrow_downward,
      color: Colors.green,
      prefix: '+',
    ),
    'withdraw': (
      label: 'withdraw',
      icon: Icons.arrow_upward,
      color: Colors.red,
      prefix: '-',
    ),
    'sell': (
      label: 'sell',
      icon: Icons.arrow_downward,
      color: Colors.greenAccent,
      prefix: '+',
    ),
    'buy': (
      label: 'buy',
      icon: Icons.arrow_upward,
      color: Colors.redAccent,
      prefix: '',
    ),
  };

  static TxnRecord getStyle(String type) =>
      _config[type] ??
      (
        label: (type.isEmpty ? 'Unknown' : type),
        icon: Icons.help_outline,
        color: Colors.grey,
        prefix: '',
      );
}
