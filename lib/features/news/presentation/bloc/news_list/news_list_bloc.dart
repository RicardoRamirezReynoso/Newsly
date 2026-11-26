import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/domain/usecases/get_top_news.dart';
import 'package:newsly/features/news/presentation/bloc/news_list/news_list_event.dart';
import 'package:newsly/features/news/presentation/bloc/news_list/news_list_state.dart';
import 'package:newsly/features/news/presentation/bloc/read_state.dart';

class NewsListBloc extends Bloc<NewsListEvent, NewsListState> {
  /// Inicia el listado en la sección Todo y registra los eventos de consulta.
  NewsListBloc(this._getTopNews)
    : super(const NewsListState(NewsSection.all, ReadState.loading())) {
    on<NewsListRefreshed>(_onRefreshed);
    on<NewsSectionSelected>(_onSectionSelected);
  }

  final GetTopNews _getTopNews;
  var _request = 0;

  /// Mantiene activo el indicador del gesto hasta concluir la actualización.
  Future<void> refresh() {
    if (isClosed) return Future.value();
    final completion = Completer<void>();
    add(NewsListRefreshed(completion));
    return completion.future;
  }

  /// Vuelve a consultar la sección conservando los titulares visibles durante la carga.
  Future<void> _onRefreshed(
    NewsListRefreshed event,
    Emitter<NewsListState> emit,
  ) async {
    try {
      await _load(state.section, state.news.value, emit);
    } finally {
      event.completion?.complete();
    }
  }

  /// Carga la nueva sección cuando cambia el filtro.
  Future<void> _onSectionSelected(
    NewsSectionSelected event,
    Emitter<NewsListState> emit,
  ) async {
    if (event.section != state.section) {
      await _load(event.section, null, emit);
    }
  }

  /// Publica el resultado del listado si la solicitud sigue siendo la más reciente.
  Future<void> _load(
    NewsSection section,
    List<Article>? previous,
    Emitter<NewsListState> emit,
  ) async {
    final request = ++_request;
    emit(NewsListState(section, ReadState.loading(previous)));
    final result = await _getTopNews(section);
    if (emit.isDone || request != _request) return;
    emit(
      NewsListState(
        section,
        result.fold(
          (failure) => ReadState.error(failure, previous),
          readListState,
        ),
      ),
    );
  }
}
