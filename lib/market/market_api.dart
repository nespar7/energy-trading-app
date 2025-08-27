import 'package:dio/dio.dart';
import 'package:energy_app/config/env.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarketApi {
  MarketApi._internal()
    : _dio = Dio(
        BaseOptions(
          baseUrl: kEnergyApiBase,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 12),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) async {
          final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
          if (idToken != null) o.headers['Authorization'] = 'Bearer $idToken';
          h.next(o);
        },
      ),
    );
  }

  static final MarketApi I = MarketApi._internal();
  final Dio _dio;

  Future<void> placeOrder({
    required String side, // 'buy' | 'sell'
    required double qty,
    required double price,
  }) async {
    await _dio.post(
      '/market/placeOrder',
      data: {'side': side, 'qty': qty, 'price': price},
    );
  }

  Future<void> cancelOrder(String orderId) async {
    await _dio.post('/market/cancelOrder', data: {'orderId': orderId});
  }
}
