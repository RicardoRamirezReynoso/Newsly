import 'package:dartz/dartz.dart';

import 'package:newsly/core/error/failure.dart';
import 'package:newsly/features/news/domain/entities/article.dart';

typedef NewsResult<T> = Either<Failure, T>;

abstract interface class NewsRepository {
  /// Devuelve las noticias recientes para el filtro seleccionado.
  Future<NewsResult<List<Article>>> headlines(NewsSection section);

  /// Devuelve las noticias que coinciden con la consulta.
  Future<NewsResult<List<Article>>> search(String query);

  /// Recupera el detalle de una noticia por su identificador.
  Future<NewsResult<Article>> article(String id);

  /// Enumera los artículos disponibles para lectura sin conexión.
  Future<NewsResult<List<Article>>> favorites();

  /// Persiste el artículo y devuelve la copia guardada.
  Future<NewsResult<Article>> saveFavorite(Article article);

  /// Retira un artículo de los favoritos por su identificador.
  Future<NewsResult<Unit>> removeFavorite(String id);
}
