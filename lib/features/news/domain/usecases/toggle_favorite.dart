import 'package:newsly/core/usecases/base_use_case.dart';
import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/domain/repositories/news_repository.dart';

class ToggleFavoriteParams {
  /// Identifica el artículo y si ya está guardado para decidir la operación.
  const ToggleFavoriteParams(this.article, {required this.isSaved});

  final Article article;
  final bool isSaved;
}

class ToggleFavorite implements BaseUseCase<Article?, ToggleFavoriteParams> {
  /// Recibe el repositorio que guarda o retira los favoritos.
  const ToggleFavorite(this._repository);
  final NewsRepository _repository;

  /// Devuelve el artículo persistido o `null` cuando se retira de favoritos.
  @override
  Future<NewsResult<Article?>> call(ToggleFavoriteParams params) async {
    if (params.isSaved) {
      return (await _repository.removeFavorite(
        params.article.id,
      )).map<Article?>((_) => null);
    }
    return (await _repository.saveFavorite(
      params.article,
    )).map<Article?>((article) => article);
  }
}
