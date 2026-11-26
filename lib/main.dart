import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:newsly/core/di/service_locator.dart';
import 'package:newsly/core/error/failure.dart';
import 'package:newsly/features/news/presentation/newsly_app.dart';
import 'package:newsly/features/news/presentation/bloc/read_state.dart';
import 'package:newsly/features/news/presentation/theme/news_theme.dart';
import 'package:newsly/features/news/presentation/widgets/news_status.dart';

/// Prepara Flutter y monta la pantalla de arranque de Newsly.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _NewslyBootstrap());
}

class _NewslyBootstrap extends StatefulWidget {
  /// Crea el widget que prepara las dependencias de la aplicación.
  const _NewslyBootstrap();

  /// Crea el estado que controla el arranque y sus reintentos.
  @override
  State<_NewslyBootstrap> createState() => _NewslyBootstrapState();
}

class _NewslyBootstrapState extends State<_NewslyBootstrap> {
  Future<GetIt> _initializing = initializeDependencies();

  /// Muestra la aplicación cuando está lista o presenta la carga y el reintento.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GetIt>(
      future: _initializing,
      builder: (context, snapshot) {
        if (snapshot.data case final services?) {
          return NewslyApp(services: services);
        }
        final failed = snapshot.hasError;
        return MaterialApp(
          title: 'Newsly',
          theme: newsTheme(),
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: SafeArea(
              child: Center(
                child: NewsStatus(
                  status: failed ? ReadStatus.error : ReadStatus.loading,
                  failure: failed ? const Failure(FailureKind.storage) : null,
                  onRetry: () => setState(() {
                    _initializing = initializeDependencies();
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
