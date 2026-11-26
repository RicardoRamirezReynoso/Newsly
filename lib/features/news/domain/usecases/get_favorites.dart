import 'package:newsly/core/usecases/base_use_case.dart';
import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/domain/repositories/news_repository.dart';

class GetFavorites implements BaseUseCase<List<Article>, NoParams> {
  /// Recibe el repositorio desde el que se leerán los favoritos.
  const GetFavorites(this._repository);
  final NewsRepository _repository;

  /// Recupera los artículos guardados para consultarlos sin conexión.
  @override
  Future<NewsResult<List<Article>>> call(NoParams params) =>
      _repository.favorites();
}
