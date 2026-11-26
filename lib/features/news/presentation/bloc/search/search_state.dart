import 'package:equatable/equatable.dart';
import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/presentation/bloc/read_state.dart';

class SearchState extends Equatable {
  /// Vincula el texto de la consulta con el estado de sus resultados.
  const SearchState(this.query, this.news);

  final String query;
  final ReadState<List<Article>> news;

  /// La consulta y el estado de lectura que determinan la igualdad.
  @override
  List<Object?> get props => [query, news];
}
