import 'package:dio/dio.dart';

import 'package:newsly/core/error/exceptions.dart';
import 'package:newsly/core/error/failure.dart';
import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/data/models/article_record.dart';

/// Cliente de contenido público de The Guardian.
class NewsRemoteDataSource {
  /// Recibe el cliente HTTP que se usará para consultar The Guardian.
  const NewsRemoteDataSource(this._dio);

  static const _previewFields =
      'headline,trailText,thumbnail,byline,publication,wordcount';

  final Dio _dio;

  /// Consulta noticias por sección o por relevancia de la búsqueda.
  Future<List<Article>> list({String? sectionId, String query = ''}) async {
    final response = await _get('/search', {
      'page-size': query.isEmpty ? 12 : 20,
      'type': 'article',
      'show-fields': _previewFields,
      'order-by': query.isEmpty ? 'newest' : 'relevance',
      'section': ?sectionId,
      if (query.isNotEmpty) 'q': query,
    });
    final results = response['results'];
    if (results is! List<Object?>) {
      throw const FormatException('Faltan los resultados');
    }
    return [
      for (final result in results) ArticleRecord.fromGuardian(_asMap(result)),
    ];
  }

  /// Valida el identificador y solicita el artículo con su texto completo.
  Future<Article> detail(String id) async {
    final segments = id.split('/');
    if (segments.any((part) => part.isEmpty || part == '.' || part == '..')) {
      throw const RemoteDataException(FailureKind.notFound);
    }
    final path = segments.map(Uri.encodeComponent).join('/');
    final response = await _get('/$path', {
      'show-fields': '$_previewFields,body,bodyText',
    });
    return ArticleRecord.fromGuardian(_asMap(response['content']));
  }

  /// Ejecuta la solicitud y extrae el contenido de una respuesta válida.
  Future<Map<String, Object?>> _get(
    String path,
    Map<String, Object> parameters,
  ) async {
    final result = await _dio.get<Object?>(path, queryParameters: parameters);
    final response = _asMap(_asMap(result.data)['response']);
    if (response['status'] != 'ok') {
      throw const FormatException('La respuesta de Guardian no es válida');
    }
    return response;
  }

  /// Valida que el valor recibido sea un objeto JSON.
  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map<String, Object?>) return value;
    throw const FormatException('Se esperaba un objeto JSON');
  }
}
