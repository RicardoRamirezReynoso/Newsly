import 'package:html/parser.dart' as html;

import 'package:newsly/features/news/domain/entities/article.dart';

/// Convierte las respuestas de Guardian y los registros Hive a entidades.
abstract final class ArticleRecord {
  /// Extrae los campos de The Guardian y limpia el HTML del resumen y la autoría.
  static Article fromGuardian(Map<String, Object?> json) {
    final fields = _map(json['fields']);
    return fromLocal({
      'id': json['id'],
      'title': _string(fields['headline']) ?? json['webTitle'],
      'sectionId': json['sectionId'],
      'sectionName': json['sectionName'],
      'publishedAt': json['webPublicationDate'],
      'webUrl': json['webUrl'],
      'summary': _plainText(fields['trailText']),
      'author': _plainText(fields['byline']),
      'publication': fields['publication'],
      'imageUrl': fields['thumbnail'],
      'wordCount': fields['wordcount'],
      'bodyHtml': fields['body'],
      'bodyText': fields['bodyText'],
    });
  }

  /// Valida los datos esenciales y convierte los campos opcionales a sus tipos.
  static Article fromLocal(Map<Object?, Object?> record) {
    final id = _string(record['id']);
    final title = _string(record['title']);
    final webUrl = Uri.tryParse(_string(record['webUrl']) ?? '');
    if (id == null || title == null || webUrl == null || !_isWebUrl(webUrl)) {
      throw const FormatException('Datos de artículo incompletos');
    }
    final imageUrl = Uri.tryParse(_string(record['imageUrl']) ?? '');
    return Article(
      id: id,
      title: title,
      sectionId: _string(record['sectionId']) ?? '',
      sectionName: _string(record['sectionName']) ?? '',
      publication: _string(record['publication']) ?? 'The Guardian',
      publishedAt: DateTime.tryParse(_string(record['publishedAt']) ?? ''),
      webUrl: webUrl,
      summary: _string(record['summary']) ?? '',
      author: _string(record['author']) ?? '',
      imageUrl: imageUrl != null && _isWebUrl(imageUrl)
          ? imageUrl.toString()
          : null,
      wordCount: int.tryParse(record['wordCount']?.toString() ?? ''),
      bodyHtml: _string(record['bodyHtml']) ?? '',
      bodyText: _string(record['bodyText']) ?? '',
    );
  }

  /// Convierte la entidad en un registro que se puede guardar como JSON.
  static Map<String, Object?> toLocal(Article article) => {
    'id': article.id,
    'title': article.title,
    'sectionId': article.sectionId,
    'sectionName': article.sectionName,
    'publication': article.publication,
    'publishedAt': article.publishedAt?.toIso8601String(),
    'webUrl': article.webUrl.toString(),
    'summary': article.summary,
    'author': article.author,
    'imageUrl': article.imageUrl,
    'wordCount': article.wordCount,
    'bodyHtml': article.bodyHtml,
    'bodyText': article.bodyText,
  };

  /// Lee un mapa o usa uno vacío cuando faltan los campos.
  static Map<Object?, Object?> _map(Object? value) =>
      value is Map<Object?, Object?> ? value : const {};

  /// Quita espacios sobrantes y trata los valores vacíos como ausentes.
  static String? _string(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  /// Extrae el texto del HTML y normaliza los espacios.
  static String _plainText(Object? value) {
    final markup = _string(value);
    if (markup == null) return '';
    return html
            .parseFragment(markup)
            .text
            ?.replaceAll(RegExp(r'\s+'), ' ')
            .trim() ??
        '';
  }

  /// Indica si la dirección usa HTTP o HTTPS e incluye un servidor.
  static bool _isWebUrl(Uri uri) =>
      (uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty;
}
