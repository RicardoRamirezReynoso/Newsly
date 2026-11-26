import 'package:equatable/equatable.dart';
import 'package:newsly/core/error/failure.dart';
import 'package:newsly/features/news/domain/entities/article.dart';

class FavoritesState extends Equatable {
  /// Conserva los favoritos, las operaciones pendientes y cualquier fallo.
  const FavoritesState({
    this.articles = const [],
    this.busyIds = const {},
    this.loading = true,
    this.loadFailure,
    this.actionFailure,
  });

  final List<Article> articles;
  final Set<String> busyIds;
  final bool loading;
  final Failure? loadFailure;
  final Failure? actionFailure;

  /// Indica si la lista de favoritos contiene el identificador indicado.
  bool contains(String id) => articles.any((article) => article.id == id);

  /// Los datos que Equatable compara para detectar cambios en los favoritos.
  @override
  List<Object?> get props => [
    articles,
    busyIds,
    loading,
    loadFailure,
    actionFailure,
  ];
}
