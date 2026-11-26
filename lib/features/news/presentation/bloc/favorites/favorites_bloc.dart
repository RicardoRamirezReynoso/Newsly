import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:newsly/core/usecases/base_use_case.dart';
import 'package:newsly/features/news/domain/usecases/get_favorites.dart';
import 'package:newsly/features/news/domain/usecases/toggle_favorite.dart';
import 'package:newsly/features/news/presentation/bloc/favorites/favorites_event.dart';
import 'package:newsly/features/news/presentation/bloc/favorites/favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  /// Parte de la carga inicial y registra los eventos de lectura y cambio de favoritos.
  FavoritesBloc(this._getFavorites, this._toggleFavorite)
    : super(const FavoritesState()) {
    on<FavoritesRequested>(_onRequested);
    on<FavoriteToggled>(_onToggled);
  }

  final GetFavorites _getFavorites;
  final ToggleFavorite _toggleFavorite;
  var _loading = false;

  /// Solicita una lectura de Hive y permite esperar a que termine.
  Future<void> refresh() {
    if (isClosed) return Future.value();
    final completion = Completer<void>();
    add(FavoritesRequested(completion));
    return completion.future;
  }

  /// Carga los favoritos evitando leer mientras hay otra carga o cambios pendientes.
  Future<void> _onRequested(
    FavoritesRequested event,
    Emitter<FavoritesState> emit,
  ) async {
    if (_loading || state.busyIds.isNotEmpty) {
      event.completion?.complete();
      return;
    }
    _loading = true;
    try {
      final previous = state.articles;
      emit(FavoritesState(articles: previous));
      final result = await _getFavorites(const NoParams());
      if (emit.isDone) return;
      emit(
        result.fold(
          (failure) => FavoritesState(
            articles: previous,
            loading: false,
            loadFailure: failure,
          ),
          (articles) => FavoritesState(
            articles: List.unmodifiable(articles),
            loading: false,
          ),
        ),
      );
    } finally {
      _loading = false;
      event.completion?.complete();
    }
  }

  /// Actualiza todas las pantallas después de confirmar la escritura local.
  Future<void> _onToggled(
    FavoriteToggled event,
    Emitter<FavoritesState> emit,
  ) async {
    final article = event.article;
    final id = article.id;
    if (state.loading || state.busyIds.contains(id)) return;
    final removing = state.contains(id);
    emit(
      FavoritesState(
        articles: state.articles,
        busyIds: Set.unmodifiable({...state.busyIds, id}),
        loading: false,
        loadFailure: state.loadFailure,
      ),
    );
    final result = await _toggleFavorite(
      ToggleFavoriteParams(article, isSaved: removing),
    );
    if (emit.isDone) return;
    final busyIds = Set<String>.unmodifiable({...state.busyIds}..remove(id));
    emit(
      result.fold(
        (failure) => FavoritesState(
          articles: state.articles,
          busyIds: busyIds,
          loading: false,
          loadFailure: state.loadFailure,
          actionFailure: failure,
        ),
        (saved) => FavoritesState(
          articles: List.unmodifiable([
            ?saved,
            ...state.articles.where((article) => article.id != id),
          ]),
          busyIds: busyIds,
          loading: false,
          loadFailure: state.loadFailure,
        ),
      ),
    );
  }
}
