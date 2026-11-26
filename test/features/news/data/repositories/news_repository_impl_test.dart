import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:newsly/core/error/failure.dart';
import 'package:newsly/core/network/dio_client.dart';
import 'package:newsly/core/network/dio_failure_mapper.dart';
import 'package:newsly/features/news/data/datasources/news_local_data_source.dart';
import 'package:newsly/features/news/data/datasources/news_remote_data_source.dart';
import 'package:newsly/features/news/data/repositories/news_repository_impl.dart';
import 'package:newsly/features/news/domain/entities/article.dart';

const _id = 'technology/2026/nov/23/una-noticia';
const _record = {
  'id': _id,
  'webTitle': 'Titular',
  'sectionId': 'technology',
  'sectionName': 'Technology',
  'webPublicationDate': '2026-11-23T12:00:00Z',
  'webUrl': 'https://www.theguardian.com/$_id',
  'fields': {
    'headline': 'Un artículo de prueba',
    'trailText': '<p>Un resumen &amp; sus detalles.</p>',
    'byline': 'Una autora',
    'wordcount': '500',
  },
};

/// Registra las pruebas del repositorio con solicitudes controladas y una caja de Hive
/// temporal.
void main() {
  late Directory directory;
  late Box<String> box;
  late Dio dio;
  late NewsRemoteDataSource api;
  late NewsRepositoryImpl repository;
  late List<RequestOptions> requests;
  Response<Object?> Function(RequestOptions)? response;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('newsly_hive_test_');
    Hive.init(directory.path);
    box = await Hive.openBox<String>(NewsLocalDataSource.boxName);
    requests = [];
    response = null;
    dio = createGuardianDio('test-key', requestSpacing: Duration.zero);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final reply = response;
          if (reply == null) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
            );
            return;
          }
          handler.resolve(reply(options));
        },
      ),
    );
    api = NewsRemoteDataSource(dio);
    repository = NewsRepositoryImpl(api, NewsLocalDataSource(box));
  });

  tearDown(() async {
    dio.close(force: true);
    await Hive.deleteBoxFromDisk(NewsLocalDataSource.boxName);
    await directory.delete();
  });

  test(
    'convierte los datos del listado y envía el filtro de sección',
    () async {
      response = (options) => _ok(options, {
        'results': [_record],
      });
      final result = await repository.headlines(NewsSection.technology);
      final article = result.getOrElse(() => fail('Faltan resultados')).single;
      expect(article.id, _id);
      expect(article.title, 'Un artículo de prueba');
      expect(article.summary, 'Un resumen & sus detalles.');
      expect(article.publishedAt, DateTime.utc(2026, 11, 23, 12));
      expect(article.readingMinutes, 3);
      expect(requests.single.path, '/search');
      expect(requests.single.queryParameters['section'], 'technology');
      expect(requests.single.queryParameters['order-by'], 'newest');
      expect(requests.single.queryParameters['api-key'], 'test-key');
    },
  );

  test('busca por relevancia y acepta que no haya resultados', () async {
    response = (options) => _ok(options, {'results': []});
    final result = await repository.search('ciencia & tecnología');
    expect(result.getOrElse(() => fail('La búsqueda falló')), isEmpty);
    expect(requests.single.queryParameters['q'], 'ciencia & tecnología');
    expect(requests.single.queryParameters['order-by'], 'relevance');
  });

  test('mapea una respuesta incompleta y un fallo de conexión', () async {
    response = (options) => _ok(options, {});
    final invalid = await repository.search('tecnología');
    expect(
      invalid.fold((failure) => failure.kind, (_) => null),
      FailureKind.invalidData,
    );
    response = null;
    final offline = await repository.headlines(NewsSection.all);
    expect(
      offline.fold((failure) => failure.kind, (_) => null),
      FailureKind.connection,
    );
  });

  test(
    'comparte una descarga, reabre el cuerpo sin red y quita el favorito',
    () async {
      final preview = Article(
        id: _id,
        title: 'Titular',
        sectionId: 'technology',
        sectionName: 'Technology',
        publication: 'The Guardian',
        publishedAt: null,
        webUrl: Uri.parse('https://www.theguardian.com/$_id'),
      );
      response = (options) => _ok(options, {
        'content': {
          ..._record,
          'fields': {
            ...(_record['fields'] as Map<String, String>),
            'body': '<p>Contenido completo para la lectura offline.</p>',
          },
        },
      });
      final results = await Future.wait([
        repository.article(_id),
        repository.saveFavorite(preview),
      ]);
      expect(results.every((result) => result.isRight()), isTrue);
      expect(requests.single.path, '/$_id');

      await box.close();
      box = await Hive.openBox<String>(NewsLocalDataSource.boxName);
      repository = NewsRepositoryImpl(api, NewsLocalDataSource(box));
      requests.clear();
      response = null;

      final restored = await repository.article(_id);
      final favorite = restored.getOrElse(
        () => fail('No se pudo leer sin red'),
      );
      expect(favorite.bodyHtml, contains('Contenido completo'));
      expect((await repository.favorites()).getOrElse(() => []), [favorite]);
      expect((await repository.removeFavorite(_id)).isRight(), isTrue);
      expect(
        (await repository.favorites()).getOrElse(() => [favorite]),
        isEmpty,
      );
      expect(requests, isEmpty);
    },
  );

  test('rechaza las solicitudes cuando falta la clave de Guardian', () async {
    final client = createGuardianDio('');
    addTearDown(() => client.close(force: true));
    var sent = false;
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sent = true;
          handler.resolve(_ok(options, {'results': []}));
        },
      ),
    );
    final withoutKey = NewsRepositoryImpl(
      NewsRemoteDataSource(client),
      NewsLocalDataSource(box),
    );

    final result = await withoutKey.headlines(NewsSection.all);

    expect(
      result.fold((failure) => failure.kind, (_) => null),
      FailureKind.configuration,
    );
    expect(sent, isFalse);
  });

  test('distingue tiempo de espera, autorización, cuota y servidor', () {
    final options = RequestOptions(path: '/search');
    final timeout = DioException(
      requestOptions: options,
      type: DioExceptionType.receiveTimeout,
    );
    expect(guardianFailure(timeout).kind, FailureKind.timeout);
    const errors = {
      401: FailureKind.unauthorized,
      403: FailureKind.unauthorized,
      404: FailureKind.notFound,
      429: FailureKind.rateLimit,
      503: FailureKind.server,
    };
    for (final entry in errors.entries) {
      final error = DioException.badResponse(
        statusCode: entry.key,
        requestOptions: options,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: entry.key,
        ),
      );
      expect(
        guardianFailure(error),
        Failure(entry.value, statusCode: entry.key),
      );
    }
  });
}

/// Construye una respuesta exitosa con la estructura de The Guardian para las pruebas.
Response<Object?> _ok(RequestOptions options, Map<String, Object?> data) =>
    Response<Object?>(
      requestOptions: options,
      statusCode: 200,
      data: {
        'response': {'status': 'ok', ...data},
      },
    );
