import 'package:dio/dio.dart';
import 'package:newsly/core/error/exceptions.dart';
import 'package:newsly/core/error/failure.dart';

class GuardianRequestInterceptor extends Interceptor {
  /// Configura la clave y el intervalo mínimo entre solicitudes.
  GuardianRequestInterceptor(this._apiKey, this._requestSpacing);

  final String _apiKey;
  final Duration _requestSpacing;
  final _clock = Stopwatch()..start();
  var _nextRequest = Duration.zero;

  /// Autentica las solicitudes y reserva un turno para respetar la cuota.
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_apiKey.isEmpty) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: const RemoteDataException(FailureKind.configuration),
        ),
      );
      return;
    }

    final now = _clock.elapsed;
    final delay = _nextRequest - now;
    _nextRequest =
        (delay > Duration.zero ? _nextRequest : now) + _requestSpacing;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    options.queryParameters['api-key'] = _apiKey;
    handler.next(options);
  }
}
