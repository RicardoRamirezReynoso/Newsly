import 'dart:async';

import 'package:newsly/features/news/domain/entities/article.dart';

sealed class FavoritesEvent {
  /// Permite crear eventos de favoritos constantes.
  const FavoritesEvent();
}

class FavoritesRequested extends FavoritesEvent {
  /// Pide cargar los guardados y admite avisar cuando termine.
  const FavoritesRequested([this.completion]);

  final Completer<void>? completion;
}

class FavoriteToggled extends FavoritesEvent {
  /// Identifica el artículo que se añadirá o retirará de los guardados.
  const FavoriteToggled(this.article);

  final Article article;
}
