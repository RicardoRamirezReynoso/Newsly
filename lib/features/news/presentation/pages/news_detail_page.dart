import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/presentation/bloc/news_detail/news_detail_bloc.dart';
import 'package:newsly/features/news/presentation/bloc/news_detail/news_detail_event.dart';
import 'package:newsly/features/news/presentation/bloc/news_detail/news_detail_state.dart';
import 'package:newsly/features/news/presentation/theme/news_theme.dart';
import 'package:newsly/features/news/presentation/widgets/article_card.dart';
import 'package:newsly/features/news/presentation/widgets/editorial.dart';
import 'package:newsly/features/news/presentation/widgets/favorite_button.dart';
import 'package:newsly/features/news/presentation/widgets/news_status.dart';

class NewsDetailPage extends StatelessWidget {
  /// Recibe el identificador del artículo, la ruta de origen y una vista previa
  /// opcional.
  const NewsDetailPage({
    super.key,
    required this.id,
    required this.parentRoute,
    this.preview,
  });

  final String id;
  final String parentRoute;
  final Article? preview;

  /// Presenta la vista previa al cargar y añade el cuerpo cuando está disponible.
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<NewsDetailBloc>();
    return BlocBuilder<NewsDetailBloc, NewsDetailState>(
      builder: (context, state) {
        final article = state.value ?? preview;
        return Column(
          children: [
            _ArticleToolbar(
              article: article,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.goNamed(parentRoute);
                }
              },
            ),
            Expanded(
              child: NewsScroll(
                storageId: 'article-$id',
                maxWidth: 784,
                top: 22,
                slivers: [
                  if (article != null)
                    SliverToBoxAdapter(child: _ArticleHeader(article)),
                  if (state.value case final full?)
                    _ArticleBody(full)
                  else
                    SliverToBoxAdapter(
                      child: NewsStatus(
                        status: state.status,
                        failure: state.failure,
                        onRetry: () => bloc.add(NewsDetailRequested(id)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ArticleToolbar extends StatelessWidget {
  /// Recibe el artículo visible y la acción para volver.
  const _ArticleToolbar({required this.article, required this.onBack});

  final Article? article;
  final VoidCallback onBack;

  /// Muestra el botón de regreso, la sección y el marcador si hay un artículo.
  @override
  Widget build(BuildContext context) {
    final article = this.article;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: NewsPalette.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              tooltip: 'Volver',
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: NewsPalette.subtle,
                foregroundColor: NewsPalette.ink,
                minimumSize: const Size.square(40),
              ),
            ),
            Expanded(
              child: Center(
                child: EditorialLabel(
                  article == null ? 'The Guardian' : sectionLabel(article),
                  accent: true,
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: article == null ? null : FavoriteButton(article),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleHeader extends StatelessWidget {
  /// Recibe los datos editoriales que encabezan la lectura.
  const _ArticleHeader(this.article);

  final Article article;

  /// Presenta el título, la autoría, la fecha, la duración estimada y la imagen.
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= newsWideBreakpoint;
    final date = article.publishedAt?.toLocal();
    final minutes = article.readingMinutes;
    final details = [
      if (date != null) DateFormat('d MMM y · HH:mm', 'es').format(date),
      if (minutes != null) '$minutes min de lectura',
    ].join('  ·  ');
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              article.title,
              style: NewsType.serif(wide ? 49 : 31, spacing: -1.0),
            ),
          ),
          if (article.summary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              article.summary,
              style: NewsType.sans(
                wide ? 19 : 15,
                color: NewsPalette.secondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: NewsPalette.subtle,
                  child: Icon(
                    article.author.isEmpty
                        ? Icons.newspaper_rounded
                        : Icons.person_outline_rounded,
                    color: NewsPalette.ink,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Wrap(
                    spacing: 13,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        articleByline(article),
                        style: NewsType.sans(12, weight: 800),
                      ),
                      if (details.isNotEmpty)
                        Text(
                          details,
                          style: NewsType.sans(
                            11,
                            color: NewsPalette.secondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (article.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: AspectRatio(
                aspectRatio: 1.82,
                child: ArticleImage(article, cover: true),
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _ArticleBody extends StatelessWidget {
  /// Recibe el artículo que se mostrará en la zona de lectura.
  const _ArticleBody(this.article);

  final Article article;

  /// Renderiza el cuerpo en HTML o texto y añade el enlace a la fuente.
  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      if (article.bodyHtml.isNotEmpty)
        HtmlWidget(
          article.bodyHtml,
          baseUrl: article.webUrl,
          renderMode: RenderMode.sliverList,
          onTapUrl: (url) => _open(context, Uri.tryParse(url)),
          customStylesBuilder: (element) => switch (element.localName) {
            'a' => {'color': '#a62c22'},
            'h2' || 'h3' => {'font-family': 'Source Serif 4'},
            _ => null,
          },
          textStyle: NewsType.sans(16, height: 1.65),
        )
      else
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SelectableText(
              article.hasBody
                  ? article.bodyText
                  : 'El texto completo está disponible en el sitio original.',
              style: NewsType.sans(16, height: 1.65),
            ),
          ),
        ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              TextButton.icon(
                onPressed: () => _open(context, article.webUrl),
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: Text(
                  'Leer en The Guardian',
                  style: NewsType.sans(13, weight: 800),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  /// Abre enlaces HTTP o HTTPS y avisa si la apertura falla.
  Future<bool> _open(BuildContext context, Uri? uri) async {
    if (uri == null || !['https', 'http'].contains(uri.scheme)) return false;
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      // El mensaje también cubre plataformas sin un navegador disponible.
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
    return true;
  }
}
