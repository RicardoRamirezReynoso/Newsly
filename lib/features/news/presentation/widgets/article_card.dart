import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:newsly/core/utils/relative_date.dart';
import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/presentation/theme/news_theme.dart';
import 'package:newsly/features/news/presentation/widgets/editorial.dart';
import 'package:newsly/features/news/presentation/widgets/favorite_button.dart';

class ArticleImage extends StatelessWidget {
  /// Recibe la noticia y el formato de portada o miniatura.
  const ArticleImage(this.article, {super.key, this.cover = false});

  final Article article;
  final bool cover;

  /// Muestra la imagen disponible y usa un marcador visual cuando falta o falla.
  @override
  Widget build(BuildContext context) {
    final url = article.imageUrl;
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(color: NewsPalette.subtle),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: NewsPalette.secondary,
          size: cover ? 32 : 21,
        ),
      ),
    );
    if (url == null) return fallback;
    if (kIsWeb) {
      // El CDN de Guardian permite incrustar sus imágenes sin cabeceras CORS.
      return Image.network(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, _) => const ColoredBox(color: NewsPalette.subtle),
      errorWidget: (_, _, _) => fallback,
    );
  }
}

class FeaturedCard extends StatelessWidget {
  /// Recibe el artículo de portada y la acción que abre su detalle.
  const FeaturedCard(this.article, {super.key, required this.onOpen});

  final Article article;
  final VoidCallback onOpen;

  /// Presenta la noticia destacada con imagen, resumen, autoría y marcador.
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= newsWideBreakpoint;
    return _ArticleFrame(
      onOpen: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: wide ? 1.84 : 1.78,
            child: ArticleImage(article, cover: true),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              wide ? 24 : 16,
              12,
              wide ? 24 : 16,
              14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: EditorialLabel(
                        sectionLabel(article),
                        accent: true,
                      ),
                    ),
                    FavoriteButton(article),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  article.title,
                  style: NewsType.serif(wide ? 34 : 25, height: 1.12),
                ),
                if (article.summary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    article.summary,
                    style: NewsType.sans(
                      wide ? 14 : 13,
                      color: NewsPalette.secondary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                _ArticleMeta(article, showDate: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ArticleCard extends StatelessWidget {
  /// Configura la tarjeta según si el artículo está guardado y el espacio disponible.
  const ArticleCard(
    this.article, {
    super.key,
    required this.onOpen,
    this.saved = false,
    this.compact = false,
  });

  final Article article;
  final VoidCallback onOpen;
  final bool saved;
  final bool compact;

  /// Presenta el titular, la imagen y los controles que correspondan al contexto.
  @override
  Widget build(BuildContext context) {
    return _ArticleFrame(
      onOpen: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EditorialLabel(sectionLabel(article), accent: true),
                      const SizedBox(height: 4),
                      Text(
                        article.title,
                        style: NewsType.serif(compact ? 18 : 21, height: 1.15),
                      ),
                      if (saved && article.summary.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          article.summary,
                          style: NewsType.sans(
                            12,
                            color: NewsPalette.secondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox.square(
                  dimension: compact ? 60 : 77,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ArticleImage(article),
                  ),
                ),
              ],
            ),
            if (saved) ...[const SizedBox(height: 8), const Divider(height: 1)],
            Row(
              children: [
                Expanded(child: _ArticleMeta(article, showDate: !saved)),
                const SizedBox(width: 6),
                FavoriteButton(article, withLabel: saved),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleFrame extends StatelessWidget {
  /// Une el contenido de una tarjeta con su acción de apertura.
  const _ArticleFrame({required this.onOpen, required this.child});

  final VoidCallback onOpen;
  final Widget child;

  /// Dibuja un contenedor interactivo que se anuncia como botón.
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      color: NewsPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: NewsPalette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onOpen, child: child),
    ),
  );
}

class _ArticleMeta extends StatelessWidget {
  /// Recibe la noticia y si debe mostrar la fecha de publicación.
  const _ArticleMeta(this.article, {required this.showDate});

  final Article article;
  final bool showDate;

  /// Muestra la autoría y los datos disponibles de fecha y tiempo de lectura.
  @override
  Widget build(BuildContext context) {
    final time = relativeDate(article.publishedAt);
    final minutes = article.readingMinutes;
    final secondary = [
      if (showDate && time.isNotEmpty) time,
      if (minutes != null) '$minutes min',
    ].join(' · ');
    return Wrap(
      spacing: 8,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(articleByline(article), style: NewsType.sans(11, weight: 750)),
        if (secondary.isNotEmpty)
          Text(
            secondary,
            style: NewsType.sans(11, color: NewsPalette.secondary),
          ),
      ],
    );
  }
}
