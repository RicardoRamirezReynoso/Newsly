import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:newsly/features/news/presentation/navigation/news_router.dart';
import 'package:newsly/features/news/presentation/bloc/favorites/favorites_bloc.dart';
import 'package:newsly/features/news/presentation/bloc/favorites/favorites_event.dart';
import 'package:newsly/features/news/presentation/theme/news_theme.dart';

class NewslyApp extends StatefulWidget {
  /// Recibe el localizador que proporciona las dependencias de la aplicación.
  const NewslyApp({super.key, required this.services});

  final GetIt services;

  /// Crea el estado que mantiene el router y el tema durante la sesión.
  @override
  State<NewslyApp> createState() => _NewslyAppState();
}

class _NewslyAppState extends State<NewslyApp> {
  late final GoRouter _router = createNewsRouter(widget.services);
  final _theme = newsTheme();

  /// Libera el router al desmontar la raíz de la aplicación.
  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  /// Configura el idioma y comparte el BLoC de favoritos entre las pestañas.
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        widget.services<FavoritesBloc>()..add(const FavoritesRequested()),
    child: MaterialApp.router(
      title: 'Newsly',
      debugShowCheckedModeBanner: false,
      theme: _theme,
      routerConfig: _router,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('es', 'MX')],
    ),
  );
}
