import 'package:dartz/dartz.dart';
import 'package:newsly/core/error/failure.dart';

/// Contrato de los casos de uso asíncronos que pueden fallar.
abstract interface class BaseUseCase<T, Params> {
  /// Ejecuta el caso de uso y devuelve su resultado o un fallo de dominio.
  Future<Either<Failure, T>> call(Params params);
}

class NoParams {
  /// Representa una llamada que no necesita datos de entrada.
  const NoParams();
}
