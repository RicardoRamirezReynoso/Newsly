import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:newsly/features/news/presentation/bloc/favorites/favorites_bloc.dart';
import 'package:newsly/features/news/presentation/bloc/favorites/favorites_state.dart';
import 'package:newsly/features/news/presentation/theme/news_theme.dart';
import 'package:newsly/features/news/presentation/widgets/editorial.dart';
import 'package:newsly/features/news/presentation/navigation/news_destination.dart';

class NewsShell extends StatelessWidget {
  /// Recibe el navegador de pestañas y si la ruta activa muestra un artículo.
  const NewsShell({
    super.key,
    required this.navigation,
    required this.showingArticle,
  });

  final StatefulNavigationShell navigation;
  final bool showingArticle;

  /// Adapta la navegación al ancho y muestra los errores al modificar favoritos.
  @override
  Widget build(BuildContext context) {
    final count = context.select(
      (FavoritesBloc bloc) => bloc.state.articles.length,
    );
    final wide = MediaQuery.sizeOf(context).width >= newsWideBreakpoint;
    final index = navigation.currentIndex;

    return BlocListener<FavoritesBloc, FavoritesState>(
      listenWhen: (previous, current) =>
          current.actionFailure != null &&
          previous.actionFailure != current.actionFailure,
      listener: (context, state) {
        final failure = state.actionFailure!;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('${failure.title}. ${failure.message}')),
          );
      },
      child: Scaffold(
        body: SafeArea(
          bottom: wide,
          child: Column(
            children: [
              if (wide || !showingArticle) const _Masthead(),
              Expanded(
                child: Row(
                  children: [
                    if (wide) ...[
                      NavigationRail(
                        selectedIndex: index,
                        onDestinationSelected: _select,
                        minWidth: 88,
                        groupAlignment: -0.87,
                        labelType: NavigationRailLabelType.all,
                        backgroundColor: NewsPalette.background,
                        indicatorColor: NewsPalette.subtle,
                        selectedIconTheme: const IconThemeData(
                          color: NewsPalette.ink,
                        ),
                        unselectedIconTheme: const IconThemeData(
                          color: NewsPalette.secondary,
                        ),
                        selectedLabelTextStyle: NewsType.sans(11, weight: 850),
                        unselectedLabelTextStyle: NewsType.sans(
                          11,
                          weight: 650,
                          color: NewsPalette.secondary,
                        ),
                        destinations: [
                          for (final destination in NewsDestination.values)
                            NavigationRailDestination(
                              icon: _DestinationIcon(destination, count: count),
                              selectedIcon: _DestinationIcon(
                                destination,
                                count: count,
                                selected: true,
                              ),
                              label: Text(destination.label),
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1, thickness: 1),
                    ],
                    Expanded(child: navigation),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: wide
            ? null
            : DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: NewsPalette.line)),
                ),
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    labelTextStyle: WidgetStateProperty.resolveWith(
                      (states) => NewsType.sans(
                        11,
                        weight: states.contains(WidgetState.selected)
                            ? 850
                            : 650,
                      ),
                    ),
                  ),
                  child: NavigationBar(
                    height: 62,
                    backgroundColor: NewsPalette.background,
                    indicatorColor: NewsPalette.subtle,
                    selectedIndex: index,
                    onDestinationSelected: _select,
                    destinations: [
                      for (final destination in NewsDestination.values)
                        NavigationDestination(
                          icon: _DestinationIcon(destination, count: count),
                          selectedIcon: _DestinationIcon(
                            destination,
                            count: count,
                            selected: true,
                          ),
                          label: destination.label,
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// Cambia de pestaña o vuelve a su inicio si ya está seleccionada.
  void _select(int index) => navigation.goBranch(
    index,
    initialLocation: index == navigation.currentIndex,
  );
}

class _Masthead extends StatelessWidget {
  /// Crea el encabezado de marca compartido por las pestañas.
  const _Masthead();

  /// Muestra el nombre de Newsly junto a la fecha actual.
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= newsWideBreakpoint;
    final date = DateFormat(
      'd MMM',
      'es',
    ).format(DateTime.now()).replaceAll('.', '');
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: NewsPalette.line)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: wide ? 27 : 16,
          vertical: wide ? 13 : 9,
        ),
        child: Row(
          children: [
            Text(
              'Newsly',
              style: NewsType.serif(wide ? 31 : 25, weight: 750, height: 1.15),
            ),
            const SizedBox(width: 9),
            const EditorialLabel('Hoy', accent: true),
            const Spacer(),
            EditorialLabel(date),
          ],
        ),
      ),
    );
  }
}

class _DestinationIcon extends StatelessWidget {
  /// Vincula el icono con su pestaña, su selección y el número de guardados.
  const _DestinationIcon(
    this.destination, {
    required this.count,
    this.selected = false,
  });

  final NewsDestination destination;
  final int count;
  final bool selected;

  /// Muestra la variante activa del icono y el contador cuando hay favoritos.
  @override
  Widget build(BuildContext context) => Badge(
    backgroundColor: NewsPalette.accent,
    textColor: Colors.white,
    label: Text(count > 99 ? '99+' : '$count'),
    isLabelVisible: destination == NewsDestination.favorites && count > 0,
    child: Icon(
      selected ? destination.selectedIcon : destination.icon,
      color: selected ? NewsPalette.ink : NewsPalette.secondary,
      size: 22,
    ),
  );
}
