sealed class NewsDetailEvent {
  /// Permite crear eventos de detalle constantes.
  const NewsDetailEvent();
}

class NewsDetailRequested extends NewsDetailEvent {
  /// Pide cargar el artículo correspondiente al identificador de la ruta.
  const NewsDetailRequested(this.id);

  final String id;
}
