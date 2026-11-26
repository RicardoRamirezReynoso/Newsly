import 'package:equatable/equatable.dart';

enum FailureKind {
  configuration,
  connection,
  timeout,
  unauthorized,
  notFound,
  rateLimit,
  server,
  invalidData,
  storage,
  unknown,
}

/// Describe un error que la interfaz puede presentar sin exponer credenciales.
class Failure extends Equatable {
  /// Representa un fallo y su código HTTP cuando está disponible.
  const Failure(this.kind, {this.statusCode});

  final FailureKind kind;
  final int? statusCode;

  /// El título breve que identifica el fallo en pantalla.
  String get title => switch (kind) {
    FailureKind.configuration => 'Falta configurar la API',
    FailureKind.connection => 'Sin conexión',
    FailureKind.timeout => 'La conexión tardó demasiado',
    FailureKind.unauthorized => 'Acceso rechazado',
    FailureKind.notFound => 'Artículo no disponible',
    FailureKind.rateLimit => 'Límite de solicitudes alcanzado',
    FailureKind.server => 'El servicio no está disponible',
    FailureKind.invalidData => 'No pudimos leer la respuesta',
    FailureKind.storage => 'No pudimos acceder a tus guardados',
    FailureKind.unknown => 'Algo salió mal',
  };

  /// El mensaje que explica el fallo y cómo recuperarse cuando es posible.
  String get message => switch (kind) {
    FailureKind.configuration => 'Configura GUARDIAN_API_KEY en config/.env.',
    FailureKind.connection =>
      'Revisa tu conexión a internet e inténtalo de nuevo.',
    FailureKind.timeout =>
      'The Guardian no respondió a tiempo. Inténtalo de nuevo.',
    FailureKind.unauthorized =>
      'Revisa la clave de The Guardian en config/.env.',
    FailureKind.notFound => 'The Guardian ya no ofrece este artículo.',
    FailureKind.rateLimit => 'Espera un momento antes de volver a intentarlo.',
    FailureKind.server => 'The Guardian no pudo atender la solicitud.',
    FailureKind.invalidData =>
      'The Guardian devolvió datos en un formato inesperado.',
    FailureKind.storage =>
      'Inténtalo de nuevo para acceder al almacenamiento local.',
    FailureKind.unknown => 'Inténtalo de nuevo en unos instantes.',
  };

  /// La categoría y el código HTTP que identifican fallos equivalentes.
  @override
  List<Object?> get props => [kind, statusCode];
}
