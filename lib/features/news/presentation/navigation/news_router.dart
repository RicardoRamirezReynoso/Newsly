import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/presentation/pages/news_detail_page.dart';
import 'package:newsly/features/news/presentation/pages/favorites_page.dart';
import 'package:newsly/features/news/presentation/pages/news_list_page.dart';
import 'package:newsly/features/news/presentation/pages/search_page.dart';
import 'package:newsly/features/news/presentation/bloc/news_detail/news_detail_bloc.dart';
import 'package:newsly/features/news/presentation/bloc/news_detail/news_detail_event.dart';
import 'package:newsly/features/news/presentation/bloc/news_list/news_list_bloc.dart';
import 'package:newsly/features/news/presentation/bloc/news_list/news_list_event.dart';
import 'package:newsly/features/news/presentation/bloc/read_state.dart';
import 'package:newsly/features/news/presentation/bloc/search/search_bloc.dart';
import 'package:newsly/features/news/presentation/bloc/search/search_event.dart';
import 'package:newsly/features/news/presentation/widgets/news_status.dart';
import 'package:newsly/features/news/presentation/navigation/news_destination.dart';
import 'package:newsly/features/news/presentation/navigation/news_shell.dart';

/// Mantiene la pila de navegación y el desplazamiento de cada sección.
GoRouter createNewsRouter(GetIt services) {
  GoRouter.optionURLReflectsImperativeAPIs = true;
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigation) => NewsShell(
          navigation: navigation,
          showingArticle: state.uri.pathSegments.contains('articulo'),
        ),
        branches: [
          for (final destination in NewsDestination.values)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: destination.path,
                  name: destination.name,
                  builder: (context, state) => switch (destination) {
                    NewsDestination.home => BlocProvider(
                      create: (_) =>
                          services<NewsListBloc>()
                            ..add(const NewsListRefreshed()),
                      child: const NewsListPage(),
                    ),
                    NewsDestination.search => BlocProvider(
                      create: (_) =>
                          services<SearchBloc>()..add(const SearchRefreshed()),
                      child: const SearchPage(),
                    ),
                    NewsDestination.favorites => const FavoritesPage(),
                  },
                  routes: [
                    GoRoute(
                      name: destination.articleRoute,
                      path: 'articulo/:articleId',
                      builder: (context, state) {
                        final id = state.pathParameters['articleId']!;
                        final extra = state.extra;
                        return BlocProvider(
                          key: ValueKey(id),
                          create: (_) =>
                              services<NewsDetailBloc>()
                                ..add(NewsDetailRequested(id)),
                          child: NewsDetailPage(
                            id: id,
                            parentRoute: destination.name,
                            preview: extra is Article ? extra : null,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NewsStatus(
              status: ReadStatus.empty,
              emptyTitle: 'Página no encontrada',
              emptyMessage:
                  'La dirección no corresponde a una página de Newsly.',
            ),
            FilledButton(
              onPressed: () => context.goNamed(NewsDestination.home.name),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
}
