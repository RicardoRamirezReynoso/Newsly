import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsly/features/news/presentation/navigation/news_destination.dart';
import 'package:newsly/features/news/presentation/bloc/search/search_bloc.dart';
import 'package:newsly/features/news/presentation/bloc/search/search_event.dart';
import 'package:newsly/features/news/presentation/bloc/search/search_state.dart';
import 'package:newsly/features/news/presentation/theme/news_theme.dart';
import 'package:newsly/features/news/presentation/widgets/article_card.dart';
import 'package:newsly/features/news/presentation/widgets/editorial.dart';
import 'package:newsly/features/news/presentation/widgets/news_status.dart';

class SearchPage extends StatefulWidget {
  /// Crea la pantalla que permite explorar y buscar artículos.
  const SearchPage({super.key});

  /// Crea el estado que conserva el controlador del campo de búsqueda.
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _input = TextEditingController();

  /// Libera el controlador de texto al desmontar la pantalla.
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  /// Conecta el campo con el BLoC y presenta los resultados o el estado de la consulta.
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SearchBloc>();
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        final news = state.news;
        final articles = news.value;
        final count = articles?.length ?? 0;
        final exploring = state.query.isEmpty;
        return NewsScroll(
          storageId: 'search',
          onRefresh: bloc.refresh,
          maxWidth: 890,
          slivers: [
            const SliverToBoxAdapter(child: PageHeading('Buscar noticias')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 23),
                child: TextField(
                  controller: _input,
                  onChanged: (query) => bloc.add(SearchQueryChanged(query)),
                  onSubmitted: (query) => bloc.add(SearchSubmitted(query)),
                  textInputAction: TextInputAction.search,
                  style: NewsType.sans(14),
                  decoration: InputDecoration(
                    hintText: 'Titular, tema, categoría o autor…',
                    hintStyle: NewsType.sans(13, color: NewsPalette.secondary),
                    filled: true,
                    fillColor: NewsPalette.subtle.withValues(alpha: 0.55),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 21),
                    suffixIcon: exploring
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar búsqueda',
                            icon: const Icon(Icons.close_rounded, size: 19),
                            onPressed: () {
                              _input.clear();
                              bloc.add(const SearchSubmitted(''));
                            },
                          ),
                    border: _border(NewsPalette.line),
                    enabledBorder: _border(NewsPalette.line),
                    focusedBorder: _border(NewsPalette.ink),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionHeading(
                  exploring ? 'Explorar noticias' : 'Resultados',
                  trailing: articles == null
                      ? null
                      : (count == 1 ? '1 nota' : '$count notas'),
                ),
              ),
            ),
            if (articles == null)
              SliverToBoxAdapter(
                child: NewsStatus(
                  status: news.status,
                  failure: news.failure,
                  onRetry: bloc.refresh,
                  emptyIcon: Icons.search_off_rounded,
                  emptyTitle: exploring ? 'No hay noticias' : 'Sin resultados',
                  emptyMessage: exploring
                      ? 'Actualiza para consultar la edición.'
                      : 'Prueba con otro titular, tema o autor.',
                ),
              )
            else ...[
              if (news.failure case final failure?)
                SliverToBoxAdapter(
                  child: RefreshNotice(failure, onRetry: bloc.refresh),
                ),
              SliverList.separated(
                itemCount: count,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  return ArticleCard(
                    article,
                    onOpen: () =>
                        NewsDestination.search.openArticle(context, article),
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

  /// Crea el mismo contorno redondeado con el color que corresponda al foco.
  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(28),
    borderSide: BorderSide(color: color),
  );
}
