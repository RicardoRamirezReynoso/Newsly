import 'package:dio/dio.dart';
import 'package:newsly/core/network/guardian_request_interceptor.dart';

/// Configura la URL base, los tiempos de espera y el interceptor de The Guardian.
Dio createGuardianDio(
  String apiKey, {
  Duration requestSpacing = const Duration(milliseconds: 1050),
}) {
  return Dio(
    BaseOptions(
      baseUrl: 'https://content.guardianapis.com',
      connectTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 12),
      headers: {'Accept': 'application/json'},
    ),
  )..interceptors.add(GuardianRequestInterceptor(apiKey, requestSpacing));
}
