import 'package:dio/dio.dart';
import 'package:energy_app/config/env.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EnergyApi {
  EnergyApi._internal()
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
        onRequest: (options, handler) async {
          final user = FirebaseAuth.instance.currentUser;
          final idToken = await user?.getIdToken();
          if (idToken != null) {
            options.headers['Authorization'] = 'Bearer $idToken';
          }
          handler.next(options);
        },
      ),
    );
  }

  static final EnergyApi I = EnergyApi._internal();
  final Dio _dio;

  Future<void> upsertRange({int hours = 3}) async {
    await _dio.post('/upsertRange', data: {'hours': hours});
  }

  Future<void> upsertBucket({DateTime? ts}) async {
    await _dio.post(
      '/upsertBucket',
      data: {if (ts != null) 'tsMillis': ts.millisecondsSinceEpoch},
    );
  }

  Future<bool> healthz() async {
    final r = await _dio.get('/healthz');
    return r.statusCode == 200;
  }
}
