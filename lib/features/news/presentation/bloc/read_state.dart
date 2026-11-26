import 'package:equatable/equatable.dart';

import 'package:newsly/core/error/failure.dart';

enum ReadStatus { loading, success, empty, error }

/// Marca la respuesta como vacía o devuelve una lista de resultados inmutable.
ReadState<List<T>> readListState<T>(List<T> items) => items.isEmpty
    ? ReadState<List<T>>.empty()
    : ReadState.success(List.unmodifiable(items));

class ReadState<T> extends Equatable {
  /// Marca una carga en curso y conserva el valor anterior si lo hay.
  const ReadState.loading([T? previous])
    : this._(ReadStatus.loading, value: previous);

  /// Conserva el valor obtenido al completar la operación.
  const ReadState.success(T value) : this._(ReadStatus.success, value: value);

  /// Indica que la operación terminó sin resultados.
  const ReadState.empty() : this._(ReadStatus.empty);

  /// Expone el fallo y conserva el valor anterior si lo hay.
  const ReadState.error(Failure failure, [T? previous])
    : this._(ReadStatus.error, failure: failure, value: previous);

  /// Centraliza los datos comunes de los estados de lectura.
  const ReadState._(this.status, {this.value, this.failure});

  final ReadStatus status;
  final T? value;
  final Failure? failure;

  /// El estado, el valor y el fallo que Equatable usa para detectar cambios.
  @override
  List<Object?> get props => [status, value, failure];
}
