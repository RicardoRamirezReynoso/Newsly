import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:newsly/features/news/domain/entities/article.dart';

enum NewsDestination {
  home('Inicio', '/', Icons.newspaper_outlined, Icons.newspaper_rounded),
  search('Buscar', '/buscar', Icons.search_rounded, Icons.search_rounded),
  favorites(
    'Guardados',
    '/guardados',
    Icons.bookmark_border_rounded,
    Icons.bookmark_rounded,
  );

  /// Define la ruta, la etiqueta y los iconos de una pestaña.
  const NewsDestination(this.label, this.path, this.icon, this.selectedIcon);

  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;

  /// El nombre de la ruta de detalle dentro de esta pestaña.
  String get articleRoute => '$name-article';

  /// Abre el detalle dentro de la pestaña actual con una vista previa del artículo.
  void openArticle(BuildContext context, Article article) {
    context.pushNamed(
      articleRoute,
      pathParameters: {'articleId': article.id},
      extra: article,
    );
  }
}
