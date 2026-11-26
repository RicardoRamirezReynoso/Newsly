import 'package:dio/dio.dart';
import 'package:newsly/core/error/exceptions.dart';
import 'package:newsly/core/error/failure.dart';

/// Traduce los errores de transporte en fallos aptos para la interfaz.
Failure guardianFailure(DioException error) {
  final status = error.response?.statusCode;
  final kind = switch (error.type) {
    DioExceptionType.connectionError => FailureKind.connection,
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => FailureKind.timeout,
    DioExceptionType.badResponse => switch (status) {
      401 || 403 => FailureKind.unauthorized,
      404 || 410 => FailureKind.notFound,
      429 => FailureKind.rateLimit,
      final int code when code >= 500 => FailureKind.server,
      _ => FailureKind.unknown,
    },
    DioExceptionType.unknown => switch (error.error) {
      final RemoteDataException exception => exception.kind,
      FormatException() => FailureKind.invalidData,
      _ => FailureKind.unknown,
    },
    _ => FailureKind.unknown,
  };
  return Failure(kind, statusCode: status);
}
