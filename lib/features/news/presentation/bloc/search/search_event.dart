import 'dart:async';

sealed class SearchEvent {
  /// Permite crear eventos de búsqueda constantes.
  const SearchEvent();
}

class SearchQueryChanged extends SearchEvent {
  /// Registra el texto editado para iniciar la búsqueda tras una pausa.
  const SearchQueryChanged(this.query);

  final String query;
}

class SearchSubmitted extends SearchEvent {
  /// Pide buscar de inmediato con el texto indicado.
  const SearchSubmitted(this.query);

  final String query;
}

class SearchRefreshed extends SearchEvent {
  /// Pide repetir la consulta actual y admite avisar cuando termine.
  const SearchRefreshed([this.completion]);

  final Completer<void>? completion;
}
