import 'package:newsly/core/usecases/base_use_case.dart';
import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/domain/repositories/news_repository.dart';

class GetTopNews implements BaseUseCase<List<Article>, NewsSection> {
  /// Recibe el repositorio que alimenta la edición de Inicio.
  const GetTopNews(this._repository);
  final NewsRepository _repository;

  /// Solicita las publicaciones recientes de la sección seleccionada.
  @override
  Future<NewsResult<List<Article>>> call(NewsSection section) =>
      _repository.headlines(section);
}
