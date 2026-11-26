import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:newsly/core/error/exceptions.dart';
import 'package:newsly/core/error/failure.dart';
import 'package:newsly/core/network/dio_failure_mapper.dart';
import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/domain/repositories/news_repository.dart';
import 'package:newsly/features/news/data/datasources/news_local_data_source.dart';
import 'package:newsly/features/news/data/datasources/news_remote_data_source.dart';

class NewsRepositoryImpl implements NewsRepository {
  /// Combina la fuente remota con el almacenamiento local de favoritos.
  NewsRepositoryImpl(this._api, this._store);

  final NewsRemoteDataSource _api;
  final NewsLocalDataSource _store;
  final _pendingDetails = <String, Future<NewsResult<Article>>>{};

  /// Solicita las publicaciones recientes de la sección seleccionada.
  @override
  Future<NewsResult<List<Article>>> headlines(NewsSection section) =>
      _remote(() => _api.list(sectionId: section.apiId));

  /// Solicita los artículos que coinciden con la consulta.
  @override
  Future<NewsResult<List<Article>>> search(String query) =>
      _remote(() => _api.list(query: query));

  /// Prioriza la copia local del artículo y consulta Guardian cuando hace falta.
  @override
  Future<NewsResult<Article>> article(String id) async {
    final saved = await _local(() => _store.read(id));
    return saved.fold(
      (_) => _remoteDetail(id),
      (article) async => article == null ? _remoteDetail(id) : right(article),
    );
  }

  /// Recupera los artículos guardados desde el almacenamiento local.
  @override
  Future<NewsResult<List<Article>>> favorites() => _local(_store.readAll);

  /// Reutiliza el favorito existente o descarga el texto antes de guardarlo.
  @override
  Future<NewsResult<Article>> saveFavorite(Article article) async {
    final existing = await _local(() => _store.read(article.id));
    return existing.fold((failure) async => left(failure), (saved) async {
      if (saved != null) return right(saved);
      final full = article.hasBody
          ? right<Failure, Article>(article)
          : await _remoteDetail(article.id);
      return full.fold(
        (failure) async => left(failure),
        (article) => _local(() async {
          await _store.write(article);
          return article;
        }),
      );
    });
  }

  /// Borra el favorito del almacenamiento local por su identificador.
  @override
  Future<NewsResult<Unit>> removeFavorite(String id) => _local(() async {
    await _store.delete(id);
    return unit;
  });

  /// Comparte la descarga si el mismo artículo se abre mientras se está guardando.
  Future<NewsResult<Article>> _remoteDetail(String id) =>
      _pendingDetails.putIfAbsent(id, () async {
        try {
          return await _remote(() => _api.detail(id));
        } finally {
          _pendingDetails.remove(id);
        }
      });

  /// Ejecuta la consulta y traduce los errores de conexión o formato a fallos de
  /// dominio.
  Future<NewsResult<T>> _remote<T>(Future<T> Function() run) async {
    try {
      return right(await run());
    } on RemoteDataException catch (error) {
      return left(Failure(error.kind));
    } on DioException catch (error) {
      return left(guardianFailure(error));
    } on FormatException {
      return left(const Failure(FailureKind.invalidData));
    }
  }

  /// Ejecuta la operación de Hive y convierte sus excepciones en fallos de
  /// almacenamiento.
  Future<NewsResult<T>> _local<T>(FutureOr<T> Function() run) async {
    try {
      return right(await run());
    } on Exception {
      return left(const Failure(FailureKind.storage));
    }
  }
}
