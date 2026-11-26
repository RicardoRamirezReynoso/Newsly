import 'package:equatable/equatable.dart';

/// Noticia de The Guardian, con el cuerpo disponible después de abrir el detalle.
class Article extends Equatable {
  /// Reúne los datos de la noticia y, cuando está disponible, su texto completo.
  const Article({
    required this.id,
    required this.title,
    required this.sectionId,
    required this.sectionName,
    required this.publication,
    required this.publishedAt,
    required this.webUrl,
    this.summary = '',
    this.author = '',
    this.imageUrl,
    this.wordCount,
    this.bodyHtml = '',
    this.bodyText = '',
  });

  final String id;
  final String title;
  final String sectionId;
  final String sectionName;
  final String publication;
  final DateTime? publishedAt;
  final Uri webUrl;
  final String summary;
  final String author;
  final String? imageUrl;
  final int? wordCount;
  final String bodyHtml;
  final String bodyText;

  /// Indica si el artículo tiene cuerpo en HTML o en texto plano.
  bool get hasBody => bodyHtml.isNotEmpty || bodyText.isNotEmpty;

  /// El tiempo estimado de lectura en minutos, calculado a 220 palabras por minuto.
  int? get readingMinutes {
    final words = wordCount;
    return words == null || words <= 0 ? null : (words / 220).ceil();
  }

  /// Los campos que Equatable usa para comparar las noticias.
  @override
  List<Object?> get props => [
    id,
    title,
    sectionId,
    sectionName,
    publication,
    publishedAt,
    webUrl,
    summary,
    author,
    imageUrl,
    wordCount,
    bodyHtml,
    bodyText,
  ];
}

enum NewsSection {
  all('Todo', null),
  world('Actualidad', 'world'),
  technology('Tecnología', 'technology'),
  business('Negocios', 'business'),
  culture('Cultura', 'culture'),
  environment('Medio ambiente', 'environment');

  /// Vincula el nombre visible del filtro con la sección de la API.
  const NewsSection(this.label, this.apiId);

  final String label;
  final String? apiId;
}
