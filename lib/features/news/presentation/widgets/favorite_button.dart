import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/presentation/bloc/favorites/favorites_bloc.dart';
import 'package:newsly/features/news/presentation/bloc/favorites/favorites_event.dart';
import 'package:newsly/features/news/presentation/theme/news_theme.dart';

class FavoriteButton extends StatelessWidget {
  /// Asocia el botón con un artículo y permite acompañar el icono con texto.
  const FavoriteButton(this.article, {super.key, this.withLabel = false});

  final Article article;
  final bool withLabel;

  /// Refleja si el artículo está guardado o pendiente, y envía el evento al pulsarlo.
  @override
  Widget build(BuildContext context) {
    final (saved, blocked, pending) = context.select(
      (FavoritesBloc bloc) => (
        bloc.state.contains(article.id),
        bloc.state.loading,
        bloc.state.busyIds.contains(article.id),
      ),
    );
    final onPressed = blocked || pending
        ? null
        : () => context.read<FavoritesBloc>().add(FavoriteToggled(article));
    final label = saved ? 'Quitar de favoritos' : 'Guardar en favoritos';
    final color = saved ? NewsPalette.accent : NewsPalette.ink;
    final icon = pending
        ? SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        : Icon(
            saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            size: 19,
            color: color,
          );
    final background = saved ? NewsPalette.accentSoft : NewsPalette.subtle;
    return Semantics(
      container: true,
      selected: saved,
      child: withLabel
          ? Tooltip(
              message: label,
              child: TextButton.icon(
                onPressed: onPressed,
                icon: icon,
                label: Text(
                  saved ? 'Quitar' : 'Guardar',
                  style: NewsType.sans(11, weight: 780, color: color),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: background,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  minimumSize: const Size(0, 32),
                ),
              ),
            )
          : IconButton(
              tooltip: label,
              onPressed: onPressed,
              icon: icon,
              style: IconButton.styleFrom(
                backgroundColor: background,
                minimumSize: const Size.square(40),
              ),
            ),
    );
  }
}
