import 'package:newsly/core/usecases/base_use_case.dart';
import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/domain/repositories/news_repository.dart';

class GetNewsDetail implements BaseUseCase<Article, String> {
  /// Recibe el repositorio encargado de obtener el contenido de los artículos.
  const GetNewsDetail(this._repository);
  final NewsRepository _repository;

  /// Recupera el contenido completo del artículo por su identificador.
  @override
  Future<NewsResult<Article>> call(String id) => _repository.article(id);
}
