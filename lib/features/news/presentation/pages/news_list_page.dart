import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/presentation/navigation/news_destination.dart';
import 'package:newsly/features/news/presentation/bloc/news_list/news_list_bloc.dart';
import 'package:newsly/features/news/presentation/bloc/news_list/news_list_event.dart';
import 'package:newsly/features/news/presentation/bloc/news_list/news_list_state.dart';
import 'package:newsly/features/news/presentation/theme/news_theme.dart';
import 'package:newsly/features/news/presentation/widgets/article_card.dart';
import 'package:newsly/features/news/presentation/widgets/editorial.dart';
import 'package:newsly/features/news/presentation/widgets/news_status.dart';

class NewsListPage extends StatelessWidget {
  /// Crea la página de Inicio que muestra filtros y noticias recientes.
  const NewsListPage({super.key});

  /// Presenta los filtros y organiza la portada y el listado según el ancho.
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<NewsListBloc>();
    return BlocBuilder<NewsListBloc, NewsListState>(
      builder: (context, state) {
        final news = state.news;
        final articles = news.value;
        final twoColumns = MediaQuery.sizeOf(context).width >= 960;
        return NewsScroll(
          storageId: 'headlines',
          onRefresh: bloc.refresh,
          slivers: [
            const SliverToBoxAdapter(
              child: PageHeading(
                'Resumen diario',
                subtitle:
                    'Las noticias más relevantes de actualidad, tecnología y negocios.',
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 18),
                child: _SectionFilters(
                  section: state.section,
                  onSelect: (section) => bloc.add(NewsSectionSelected(section)),
                ),
              ),
            ),
            if (articles == null)
              SliverToBoxAdapter(
                child: NewsStatus(
                  status: news.status,
                  failure: news.failure,
                  onRetry: bloc.refresh,
                  emptyMessage: 'Elige otra sección o actualiza la edición.',
                ),
              )
            else ...[
              if (news.failure case final failure?)
                SliverToBoxAdapter(
                  child: RefreshNotice(failure, onRetry: bloc.refresh),
                ),
              if (twoColumns && articles.length > 1)
                SliverToBoxAdapter(child: _WideEdition(articles))
              else ...[
                SliverToBoxAdapter(child: _FeaturedStory(articles.first)),
                if (articles.length > 1) ...[
                  SliverToBoxAdapter(
                    child: _LatestHeading(articles.length - 1),
                  ),
                  SliverList.separated(
                    itemCount: articles.length - 1,
                    itemBuilder: (context, index) =>
                        _HomeCard(articles[index + 1]),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                  ),
                ],
              ],
            ],
          ],
        );
      },
    );
  }
}

class _SectionFilters extends StatelessWidget {
  /// Recibe el filtro activo y la acción para cambiar de sección.
  const _SectionFilters({required this.section, required this.onSelect});

  final NewsSection section;
  final ValueChanged<NewsSection> onSelect;

  /// Muestra las secciones en una fila desplazable con el filtro activo resaltado.
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in NewsSection.values)
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: ChoiceChip(
                label: Text(option.label),
                labelStyle: NewsType.sans(
                  12,
                  weight: 750,
                  color: option == section ? Colors.white : NewsPalette.ink,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                labelPadding: const EdgeInsets.symmetric(horizontal: 3),
                selected: option == section,
                showCheckmark: false,
                side: BorderSide(
                  color: option == section ? NewsPalette.ink : NewsPalette.line,
                ),
                shape: const StadiumBorder(),
                selectedColor: NewsPalette.ink,
                backgroundColor: NewsPalette.subtle.withValues(alpha: 0.45),
                onSelected: (_) => onSelect(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _WideEdition extends StatelessWidget {
  /// Recibe los artículos que formarán la edición de dos columnas.
  const _WideEdition(this.articles);

  final List<Article> articles;

  /// Coloca la noticia destacada junto a las publicaciones recientes.
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 6, child: _FeaturedStory(articles.first)),
      const SizedBox(width: 26),
      Expanded(
        flex: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LatestHeading(articles.length - 1, top: 0),
            for (final article in articles.skip(1))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _HomeCard(article, compact: true),
              ),
          ],
        ),
      ),
    ],
  );
}

class _FeaturedStory extends StatelessWidget {
  /// Recibe el artículo destacado de la edición.
  const _FeaturedStory(this.article);

  final Article article;

  /// Añade la etiqueta de portada y abre el detalle al tocar la tarjeta.
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionHeading(
        'Noticia destacada',
        trailing: 'En portada',
        featured: true,
      ),
      const SizedBox(height: 10),
      FeaturedCard(
        article,
        onOpen: () => NewsDestination.home.openArticle(context, article),
      ),
    ],
  );
}

class _LatestHeading extends StatelessWidget {
  /// Recibe la cantidad de noticias recientes y el margen superior.
  const _LatestHeading(this.count, {this.top = 23});

  final int count;
  final double top;

  /// Muestra el encabezado del listado con el número de noticias.
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top, bottom: 10),
    child: SectionHeading(
      'Últimas noticias',
      trailing: count == 1 ? '1 nota' : '$count notas',
    ),
  );
}

class _HomeCard extends StatelessWidget {
  /// Configura la tarjeta de Inicio con la variante compacta cuando corresponde.
  const _HomeCard(this.article, {this.compact = false});

  final Article article;
  final bool compact;

  /// Muestra el artículo y enlaza con el detalle en la pestaña de Inicio.
  @override
  Widget build(BuildContext context) => ArticleCard(
    article,
    compact: compact,
    onOpen: () => NewsDestination.home.openArticle(context, article),
  );
}
