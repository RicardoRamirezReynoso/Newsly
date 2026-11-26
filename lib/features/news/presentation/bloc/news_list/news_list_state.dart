import 'package:equatable/equatable.dart';
import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/presentation/bloc/read_state.dart';

class NewsListState extends Equatable {
  /// Une el filtro seleccionado con el estado de lectura de sus noticias.
  const NewsListState(this.section, this.news);

  final NewsSection section;
  final ReadState<List<Article>> news;

  /// La sección y el estado de lectura que determinan la igualdad.
  @override
  List<Object?> get props => [section, news];
}
