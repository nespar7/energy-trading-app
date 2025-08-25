import 'package:cloud_firestore/cloud_firestore.dart';

class WalletService {
  WalletService(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _walletRef(String uid) =>
      _db.collection('users').doc(uid).collection('wallet').doc('main');

  CollectionReference<Map<String, dynamic>> _txCol(String uid) =>
      _db.collection('users').doc(uid).collection('walletTxns');

  Stream<double> balanceStream(String uid) =>
      _walletRef(uid).snapshots().map((d) {
        final v = (d.data()?['balanceCoins'] as num?);
        return v?.toDouble() ?? 0.0;
      });

  Stream<List<Map<String, dynamic>>> txnsStream(String uid, {int limit = 50}) =>
      _txCol(uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.map((d) => d.data()).toList());

  Future<void> deposit(String uid, double amount) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be > 0');
    }
    final wallet = _walletRef(uid);
    final tx = _txCol(uid).doc();

    await _db.runTransaction((txn) async {
      final wSnap = await txn.get(wallet);
      final curr = (wSnap.data()?['balanceCoins'] as num?)?.toDouble() ?? 0.0;
      txn.set(tx, {
        'type': 'deposit',
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
      });
      txn.set(wallet, {'balanceCoins': curr + amount}, SetOptions(merge: true));
    });
  }
}
