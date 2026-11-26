import 'dart:async';

import 'package:newsly/features/news/domain/entities/article.dart';

sealed class NewsListEvent {
  /// Permite crear eventos del listado constantes.
  const NewsListEvent();
}

class NewsListRefreshed extends NewsListEvent {
  /// Pide recargar la sección activa y admite avisar cuando termine.
  const NewsListRefreshed([this.completion]);

  final Completer<void>? completion;
}

class NewsSectionSelected extends NewsListEvent {
  /// Transporta la categoría seleccionada para cargar sus titulares.
  const NewsSectionSelected(this.section);

  final NewsSection section;
}
