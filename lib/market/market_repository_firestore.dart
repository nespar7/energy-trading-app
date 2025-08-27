import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class MarketFsRepo {
  MarketFsRepo(this._db);
  final FirebaseFirestore _db;

  Stream<List<Map<String, dynamic>>> orderbook() {
    return _db
        .collection('orders')
        .where('status', isEqualTo: 'open')
        .orderBy('price') // you can shape client-side into buy/sell stacks
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> myOrders(String uid) {
    return _db
        .collection('orders')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> myTrades(String uid) {
    // for simplicity, union query emulation: two streams merged client-side
    final asBuyer = _db
        .collection('trades')
        .where('buyerUid', isEqualTo: uid)
        .orderBy('ts', descending: true)
        .limit(100)
        .snapshots();

    final asSeller = _db
        .collection('trades')
        .where('sellerUid', isEqualTo: uid)
        .orderBy('ts', descending: true)
        .limit(100)
        .snapshots();

    return asBuyer.combineLatest(asSeller, (a, b) {
      final A = a.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      final B = b.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      A.addAll(B);
      A.sort((x, y) => (y['ts'] as Timestamp).compareTo(x['ts'] as Timestamp));
      return A;
    });
  }
}

// tiny extension to combine two streams without extra packages
extension _CombineLatest<T> on Stream<T> {
  Stream<R> combineLatest<S, R>(
    Stream<S> other,
    R Function(T, S) combiner,
  ) async* {
    T? a;
    S? b;
    bool hasA = false, hasB = false;
    await for (final _ in StreamGroup.merge([
      map((v) {
        a = v;
        hasA = true;
        return 0;
      }),
      other.map((v) {
        b = v;
        hasB = true;
        return 0;
      }),
    ])) {
      if (hasA && hasB) yield combiner(a as T, b as S);
    }
  }
}

// helper
class StreamGroup {
  static Stream<T> merge<T>(Iterable<Stream<T>> streams) async* {
    final subs = <StreamSubscription<T>>[];
    final controller = StreamController<T>();
    var active = streams.length;
    for (final s in streams) {
      subs.add(
        s.listen(
          controller.add,
          onError: controller.addError,
          onDone: () {
            active--;
            if (active == 0) controller.close();
          },
        ),
      );
    }
    yield* controller.stream;
    for (final sub in subs) {
      await sub.cancel();
    }
  }
}
