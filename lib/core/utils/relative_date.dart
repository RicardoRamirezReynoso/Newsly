import 'package:intl/intl.dart';

/// Muestra el tiempo transcurrido para publicaciones recientes y la fecha para las
/// anteriores.
String relativeDate(DateTime? value, {DateTime? now}) {
  if (value == null) return '';
  final difference = (now ?? DateTime.now()).difference(value);
  if (difference.inMinutes < 1) return 'Ahora';
  if (difference.inHours < 1) return 'Hace ${difference.inMinutes} min';
  if (difference.inDays < 1) return 'Hace ${difference.inHours} h';
  if (difference.inDays == 1) return 'Ayer';
  return DateFormat('d MMM', 'es').format(value.toLocal());
}
