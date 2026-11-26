import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsly/features/news/presentation/navigation/news_destination.dart';
import 'package:newsly/features/news/presentation/bloc/favorites/favorites_bloc.dart';
import 'package:newsly/features/news/presentation/bloc/favorites/favorites_state.dart';
import 'package:newsly/features/news/presentation/bloc/read_state.dart';
import 'package:newsly/features/news/presentation/theme/news_theme.dart';
import 'package:newsly/features/news/presentation/widgets/article_card.dart';
import 'package:newsly/features/news/presentation/widgets/editorial.dart';
import 'package:newsly/features/news/presentation/widgets/news_status.dart';

class FavoritesPage extends StatelessWidget {
  /// Crea la página que consulta los guardados desde el BLoC compartido.
  const FavoritesPage({super.key});

  /// Presenta el contador, los artículos guardados o el estado de carga, error o lista
  /// vacía.
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FavoritesBloc>();
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, state) {
        final articles = state.articles;
        final failure = state.loadFailure;
        return NewsScroll(
          storageId: 'favorites',
          onRefresh: bloc.refresh,
          maxWidth: 890,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: PageHeading(
                        'Favoritos',
                        subtitle:
                            'Artículos guardados localmente para leer cuando quieras.',
                      ),
                    ),
                    const SizedBox(width: 14),
                    if (!state.loading && failure == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 9),
                        child: Text(
                          articles.length == 1
                              ? '1 guardado'
                              : '${articles.length} guardados',
                          style: NewsType.sans(
                            11,
                            weight: 750,
                            color: NewsPalette.secondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (articles.isEmpty)
              SliverToBoxAdapter(
                child: NewsStatus(
                  status: state.loading
                      ? ReadStatus.loading
                      : failure == null
                      ? ReadStatus.empty
                      : ReadStatus.error,
                  failure: failure,
                  onRetry: bloc.refresh,
                  emptyIcon: Icons.bookmark_border_rounded,
                  emptyTitle: 'Aún no hay guardados',
                  emptyMessage:
                      'Toca el marcador de una noticia para leerla sin conexión.',
                ),
              )
            else ...[
              if (failure != null)
                SliverToBoxAdapter(
                  child: RefreshNotice(failure, onRetry: bloc.refresh),
                ),
              SliverList.separated(
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  return ArticleCard(
                    article,
                    saved: true,
                    onOpen: () =>
                        NewsDestination.favorites.openArticle(context, article),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(height: 10),
              ),
            ],
          ],
        );
      },
    );
  }
}
