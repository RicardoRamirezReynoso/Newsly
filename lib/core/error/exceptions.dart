import 'package:newsly/core/error/failure.dart';

/// Identifica errores de la fuente remota ajenos al código HTTP.
class RemoteDataException implements Exception {
  /// Conserva la categoría de un fallo de la fuente remota.
  const RemoteDataException(this.kind);

  final FailureKind kind;
}
