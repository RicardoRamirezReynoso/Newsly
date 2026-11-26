import 'package:flutter/material.dart';

import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/presentation/theme/news_theme.dart';

const newsWideBreakpoint = 760.0;

/// Traduce las secciones conocidas y conserva el nombre original de las demás.
String sectionLabel(Article article) => switch (article.sectionId) {
  'world' || 'us-news' || 'uk-news' || 'australia-news' => 'Actualidad',
  'technology' => 'Tecnología',
  'business' => 'Negocios',
  'environment' => 'Medio ambiente',
  'science' => 'Ciencia',
  'sport' || 'football' => 'Deportes',
  'culture' || 'books' || 'film' || 'music' => 'Cultura',
  _ => article.sectionName.isEmpty ? 'Noticias' : article.sectionName,
};

/// Usa la autoría del artículo o el nombre de la publicación cuando no hay firma.
String articleByline(Article article) =>
    article.author.isEmpty ? article.publication : article.author;

class EditorialLabel extends StatelessWidget {
  /// Recibe el texto y si debe usar el color de acento.
  const EditorialLabel(this.text, {super.key, this.accent = false});

  final String text;
  final bool accent;

  /// Aplica el estilo editorial en mayúsculas con el color correspondiente.
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: NewsType.sans(
      10,
      weight: 800,
      spacing: 1.15,
      color: accent ? NewsPalette.accent : NewsPalette.ink,
    ),
  );
}

class SectionHeading extends StatelessWidget {
  /// Recibe el título y un dato complementario opcional.
  const SectionHeading(
    this.title, {
    super.key,
    this.trailing,
    this.featured = false,
  });

  final String title;
  final String? trailing;
  final bool featured;

  /// Alinea la etiqueta de sección con el dato complementario.
  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Row(
      children: [
        Expanded(child: EditorialLabel(title)),
        if (trailing != null)
          Text(
            trailing,
            style: NewsType.sans(
              11,
              weight: 700,
              spacing: 0.3,
              color: featured ? NewsPalette.accent : NewsPalette.secondary,
            ),
          ),
      ],
    );
  }
}

class PageHeading extends StatelessWidget {
  /// Recibe el título de página y una descripción opcional.
  const PageHeading(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  /// Muestra el título como encabezado accesible y adapta su tamaño al ancho.
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= newsWideBreakpoint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: NewsType.serif(wide ? 49 : 34, spacing: -1.4),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 7),
          Text(
            subtitle!,
            style: NewsType.sans(wide ? 15 : 13, color: NewsPalette.secondary),
          ),
        ],
      ],
    );
  }
}

/// Contiene una pantalla editorial desplazable y centra su contenido en ventanas amplias.
class NewsScroll extends StatelessWidget {
  /// Configura el contenido desplazable y el gesto de actualización opcional.
  const NewsScroll({
    super.key,
    required this.storageId,
    required this.slivers,
    this.onRefresh,
    this.maxWidth = 1200,
    this.top = 24,
  });

  final String storageId;
  final List<Widget> slivers;
  final Future<void> Function()? onRefresh;
  final double maxWidth;
  final double top;

  /// Centra el contenido, conserva el desplazamiento y habilita el gesto cuando
  /// procede.
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = MediaQuery.sizeOf(context).width >= newsWideBreakpoint;
      final padding = wide ? 36.0 : 16.0;
      final inset = ((constraints.maxWidth - maxWidth) / 2).clamp(
        padding,
        double.infinity,
      );
      final view = CustomScrollView(
        key: PageStorageKey(storageId),
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              inset,
              wide ? top + 12 : top,
              inset,
              32,
            ),
            sliver: SliverMainAxisGroup(slivers: slivers),
          ),
        ],
      );
      return onRefresh == null
          ? view
          : RefreshIndicator(onRefresh: onRefresh!, child: view);
    },
  );
}
