import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:newsly/core/error/failure.dart';
import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/domain/repositories/news_repository.dart';
import 'package:newsly/features/news/domain/usecases/get_favorites.dart';
import 'package:newsly/features/news/domain/usecases/get_news_detail.dart';
import 'package:newsly/features/news/domain/usecases/get_top_news.dart';
import 'package:newsly/features/news/domain/usecases/search_news.dart';
import 'package:newsly/features/news/domain/usecases/toggle_favorite.dart';
import 'package:newsly/features/news/presentation/bloc/favorites/favorites_bloc.dart';
import 'package:newsly/features/news/presentation/bloc/news_detail/news_detail_bloc.dart';
import 'package:newsly/features/news/presentation/bloc/news_list/news_list_bloc.dart';
import 'package:newsly/features/news/presentation/bloc/read_state.dart';
import 'package:newsly/features/news/presentation/bloc/search/search_bloc.dart';
import 'package:newsly/features/news/presentation/bloc/search/search_event.dart';
import 'package:newsly/features/news/presentation/newsly_app.dart';

final _article = Article(
  id: 'technology/2026/nov/23/nuevo-chip',
  title: 'Una nueva generación de chips',
  sectionId: 'technology',
  sectionName: 'Technology',
  publication: 'The Guardian',
  publishedAt: DateTime.utc(2026, 11, 23, 12),
  webUrl: Uri.parse('https://www.theguardian.com/technology/nuevo-chip'),
  author: 'Elena Morales',
  summary: 'Los nuevos chips procesan datos en el dispositivo.',
  bodyText: 'Texto completo disponible sin conexión.',
);

/// Registra las pruebas de navegación móvil, búsqueda, favoritos y actualización.
void main() {
  testWidgets('abre el detalle, guarda, reabre sin red y quita en móvil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _NewsRepository();
    await tester.pumpWidget(NewslyApp(services: _services(repository)));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Resumen diario'), findsOneWidget);
    await tester.tap(find.text(_article.title));
    await tester.pumpAndSettle();
    expect(
      find.text('Texto completo disponible sin conexión.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Volver'), findsOneWidget);
    expect(find.text('Newsly'), findsNothing);

    await tester.tap(find.byTooltip('Guardar en favoritos'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Quitar de favoritos'), findsOneWidget);
    repository.offline = true;
    await tester.tap(find.text('Guardados'));
    await tester.pumpAndSettle();
    expect(find.text('1 guardado'), findsOneWidget);
    await tester.tap(find.text(_article.title));
    await tester.pumpAndSettle();
    expect(
      find.text('Texto completo disponible sin conexión.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitar'));
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay guardados'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('usa riel, filtra y conserva el texto de búsqueda en tableta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _NewsRepository();
    await tester.pumpWidget(NewslyApp(services: _services(repository)));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    await tester.tap(find.text('Tecnología'));
    await tester.pumpAndSettle();
    expect(repository.lastSection, NewsSection.technology);
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'chips');
    await tester.pump(const Duration(milliseconds: 510));
    await tester.pumpAndSettle();
    expect(repository.lastQuery, 'chips');
    expect(find.text('RESULTADOS'), findsOneWidget);
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.text('chips'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('la búsqueda descarta resultados anteriores', () async {
    final previous = Completer<NewsResult<List<Article>>>();
    final latest = Completer<NewsResult<List<Article>>>();
    final repository = _NewsRepository()
      ..searchHandler = (query) =>
          query == 'primera' ? previous.future : latest.future;
    final bloc = SearchBloc(SearchNews(repository));
    addTearDown(bloc.close);
    final first = bloc.stream.firstWhere((state) => state.query == 'primera');
    bloc.add(const SearchSubmitted('primera'));
    await first;
    final second = bloc.stream.firstWhere(
      (state) =>
          state.query == 'segunda' && state.news.status == ReadStatus.empty,
    );
    bloc.add(const SearchSubmitted('segunda'));
    latest.complete(right([]));
    await second;
    previous.complete(right([_article]));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.query, 'segunda');
    expect(bloc.state.news.status, ReadStatus.empty);
  });

  test('conserva los titulares existentes si falla la actualización', () async {
    final repository = _NewsRepository();
    final bloc = NewsListBloc(GetTopNews(repository));
    addTearDown(bloc.close);
    await bloc.refresh();
    expect(bloc.state.news.status, ReadStatus.success);
    repository.offline = true;
    await bloc.refresh();
    expect(bloc.state.news.status, ReadStatus.error);
    expect(bloc.state.news.value, [_article]);
    expect(bloc.state.news.failure?.kind, FailureKind.connection);
  });

  testWidgets('deslizar hacia abajo actualiza el listado', (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _NewsRepository();
    await tester.pumpWidget(NewslyApp(services: _services(repository)));
    await tester.pumpAndSettle();
    expect(repository.headlineRequests, 1);

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, 330),
    );
    await tester.pumpAndSettle();
    expect(repository.headlineRequests, 2);
    expect(find.text(_article.title), findsOneWidget);
  });
}

/// Registra los BLoCs aislados para que usen el repositorio de prueba.
GetIt _services(NewsRepository repository) => GetIt.asNewInstance()
  ..registerFactory(() => NewsListBloc(GetTopNews(repository)))
  ..registerFactory(() => SearchBloc(SearchNews(repository)))
  ..registerFactory(() => NewsDetailBloc(GetNewsDetail(repository)))
  ..registerFactory(
    () => FavoritesBloc(GetFavorites(repository), ToggleFavorite(repository)),
  );

class _NewsRepository implements NewsRepository {
  final saved = <String, Article>{};
  NewsSection? lastSection;
  String? lastQuery;
  var offline = false;
  var headlineRequests = 0;
  Future<NewsResult<List<Article>>> Function(String)? searchHandler;

  /// Devuelve el favorito en memoria o simula una consulta según el estado de conexión.
  @override
  Future<NewsResult<Article>> article(String id) async {
    final favorite = saved[id];
    if (favorite != null) return right(favorite);
    return offline
        ? left(const Failure(FailureKind.connection))
        : right(_article);
  }

  /// Devuelve los artículos guardados en memoria durante la prueba.
  @override
  Future<NewsResult<List<Article>>> favorites() async =>
      right(saved.values.toList());

  /// Registra la sección consultada y simula el resultado según la conexión.
  @override
  Future<NewsResult<List<Article>>> headlines(NewsSection section) async {
    headlineRequests++;
    lastSection = section;
    return offline
        ? left(const Failure(FailureKind.connection))
        : right([_article]);
  }

  /// Elimina el artículo guardado en memoria por su identificador.
  @override
  Future<NewsResult<Unit>> removeFavorite(String id) async {
    saved.remove(id);
    return right(unit);
  }

  /// Guarda el artículo en memoria y devuelve la copia guardada.
  @override
  Future<NewsResult<Article>> saveFavorite(Article article) async {
    saved[article.id] = article;
    return right(article);
  }

  /// Registra la consulta y usa una respuesta controlada cuando la prueba la configura.
  @override
  Future<NewsResult<List<Article>>> search(String query) async {
    lastQuery = query;
    final handler = searchHandler;
    return handler == null ? right([_article]) : handler(query);
  }
}
