import 'package:newsly/core/usecases/base_use_case.dart';
import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/domain/repositories/news_repository.dart';

class SearchNews implements BaseUseCase<List<Article>, String> {
  /// Recibe el repositorio que ejecutará las consultas de búsqueda.
  const SearchNews(this._repository);
  final NewsRepository _repository;

  /// Elimina los espacios de los extremos antes de enviar la consulta.
  @override
  Future<NewsResult<List<Article>>> call(String query) =>
      _repository.search(query.trim());
}
