import 'package:cloud_firestore/cloud_firestore.dart';

class EnergyRepository {
  EnergyRepository(this._db);
  final FirebaseFirestore _db;

  // Last 3 hours = 12 buckets (15m each), ascending
  Stream<List<Map<String, dynamic>>> last3h(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('energyBars')
        .orderBy('ts', descending: true)
        .limit(12)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList().reversed.toList());
  }

  Stream<List<Map<String, dynamic>>> lastNH(String uid, {int hours = 12}) {
    final limit = hours * 4; // 4 buckets/hour
    return _db
        .collection('users')
        .doc(uid)
        .collection('energyBars')
        .orderBy('ts', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList().reversed.toList());
  }

  Stream<Map<String, dynamic>?> battery(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('battery')
        .doc('main')
        .snapshots()
        .map((d) => d.data());
  }
}
