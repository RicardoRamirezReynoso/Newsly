import 'package:flutter/material.dart';

import 'package:newsly/core/error/failure.dart';
import 'package:newsly/features/news/presentation/theme/news_theme.dart';
import 'package:newsly/features/news/presentation/bloc/read_state.dart';

class NewsStatus extends StatelessWidget {
  /// Configura el estado de carga, error o lista vacía y la acción de reintento.
  const NewsStatus({
    super.key,
    required this.status,
    this.failure,
    this.onRetry,
    this.emptyIcon = Icons.article_outlined,
    this.emptyTitle = 'No hay noticias',
    this.emptyMessage = 'Vuelve a consultar más tarde.',
  });

  final ReadStatus status;
  final Failure? failure;
  final VoidCallback? onRetry;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;

  /// Muestra el mensaje y el indicador o icono adecuados para el estado actual.
  @override
  Widget build(BuildContext context) {
    final failure = this.failure;
    final loading = status == ReadStatus.loading;
    final icon = switch (failure?.kind) {
      FailureKind.connection => Icons.wifi_off_rounded,
      FailureKind.timeout => Icons.schedule_rounded,
      FailureKind.configuration ||
      FailureKind.unauthorized => Icons.key_outlined,
      null => emptyIcon,
      _ => Icons.error_outline_rounded,
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 370),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 16),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const SizedBox.square(
                    dimension: 29,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: failure == null
                          ? NewsPalette.subtle
                          : NewsPalette.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Icon(
                        icon,
                        size: 25,
                        color: failure == null
                            ? NewsPalette.ink
                            : NewsPalette.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    failure?.title ?? emptyTitle,
                    style: NewsType.serif(24),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  loading ? 'Cargando…' : failure?.message ?? emptyMessage,
                  style: NewsType.sans(13, color: NewsPalette.secondary),
                  textAlign: TextAlign.center,
                ),
                if (failure != null && onRetry != null) ...[
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Reintentar'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RefreshNotice extends StatelessWidget {
  /// Recibe el fallo de actualización y la acción para reintentar.
  const RefreshNotice(this.failure, {super.key, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  /// Muestra el fallo junto a una acción de reintento sobre el contenido existente.
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: NewsPalette.accentSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 4),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: NewsPalette.accent, size: 18),
            const SizedBox(width: 9),
            Expanded(
              child: Text(failure.title, style: NewsType.sans(12, weight: 700)),
            ),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    ),
  );
}
