import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/domain/usecases/search_news.dart';
import 'package:newsly/features/news/presentation/bloc/read_state.dart';
import 'package:newsly/features/news/presentation/bloc/search/search_event.dart';
import 'package:newsly/features/news/presentation/bloc/search/search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  /// Inicia la pantalla sin consulta y registra los eventos de escritura, envío y
  /// actualización.
  SearchBloc(
    this._searchNews, {
    this._debounce = const Duration(milliseconds: 500),
  }) : super(const SearchState('', ReadState.loading())) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchSubmitted>((event, emit) => _submit(event.query, emit));
    on<SearchRefreshed>(_onRefreshed);
  }

  final SearchNews _searchNews;
  final Duration _debounce;
  var _request = 0;

  /// Repite la búsqueda activa y permite esperar a que termine.
  Future<void> refresh() {
    if (isClosed) return Future.value();
    final completion = Completer<void>();
    add(SearchRefreshed(completion));
    return completion.future;
  }

  /// Ejecuta la consulta actual y avisa al indicador de actualización al concluir.
  Future<void> _onRefreshed(
    SearchRefreshed event,
    Emitter<SearchState> emit,
  ) async {
    try {
      await _submit(state.query, emit);
    } finally {
      event.completion?.complete();
    }
  }

  /// Espera a que termine la escritura y descarta las consultas anteriores.
  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query == state.query) return;
    final request = ++_request;
    emit(SearchState(query, const ReadState.loading()));
    await Future<void>.delayed(_debounce);
    if (emit.isDone || request != _request) return;
    await _load(query, request, null, emit);
  }

  /// Ejecuta la consulta de inmediato y conserva los resultados al repetir el mismo
  /// término.
  Future<void> _submit(String input, Emitter<SearchState> emit) {
    final query = input.trim();
    final previous = query == state.query ? state.news.value : null;
    final request = ++_request;
    emit(SearchState(query, ReadState.loading(previous)));
    return _load(query, request, previous, emit);
  }

  /// Publica los resultados o el fallo de la consulta que todavía está vigente.
  Future<void> _load(
    String query,
    int request,
    List<Article>? previous,
    Emitter<SearchState> emit,
  ) async {
    final result = await _searchNews(query);
    if (emit.isDone || request != _request) return;
    emit(
      SearchState(
        query,
        result.fold(
          (failure) => ReadState.error(failure, previous),
          readListState,
        ),
      ),
    );
  }
}
