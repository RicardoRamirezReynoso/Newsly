import 'dart:convert';

import 'package:hive/hive.dart';

import 'package:newsly/features/news/domain/entities/article.dart';
import 'package:newsly/features/news/data/models/article_record.dart';

/// Guarda una copia legible de cada artículo, indexada por su id de Guardian.
class NewsLocalDataSource {
  /// Usa una caja de Hive para persistir los favoritos.
  const NewsLocalDataSource(this._box);

  static const boxName = 'newsly_favorites';
  final Box<String> _box;

  /// Recupera los favoritos en orden inverso al de guardado.
  List<Article> readAll() =>
      _box.values.map(_decode).toList().reversed.toList();

  /// Recupera un favorito por su identificador o devuelve `null` si no existe.
  Article? read(String id) {
    final value = _box.get(id);
    return value == null ? null : _decode(value);
  }

  /// Serializa el artículo y lo guarda bajo su identificador.
  Future<void> write(Article article) =>
      _box.put(article.id, jsonEncode(ArticleRecord.toLocal(article)));

  /// Elimina de Hive el favorito con el identificador indicado.
  Future<void> delete(String id) => _box.delete(id);

  /// Valida el registro JSON y reconstruye la noticia almacenada.
  Article _decode(String value) {
    final record = jsonDecode(value);
    if (record is! Map<String, Object?>) {
      throw const FormatException('Favorito inválido');
    }
    return ArticleRecord.fromLocal(record);
  }
}
