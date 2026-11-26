import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:newsly/features/news/domain/usecases/get_news_detail.dart';
import 'package:newsly/features/news/presentation/bloc/news_detail/news_detail_event.dart';
import 'package:newsly/features/news/presentation/bloc/news_detail/news_detail_state.dart';

class NewsDetailBloc extends Bloc<NewsDetailEvent, NewsDetailState> {
  /// Inicia la carga del detalle y registra el evento para solicitarlo o reintentar.
  NewsDetailBloc(this._getDetail) : super(const NewsDetailState.loading()) {
    on<NewsDetailRequested>(_onRequested);
  }

  final GetNewsDetail _getDetail;
  var _request = 0;

  /// Carga el artículo e ignora la respuesta si otra solicitud la reemplazó.
  Future<void> _onRequested(
    NewsDetailRequested event,
    Emitter<NewsDetailState> emit,
  ) async {
    final request = ++_request;
    emit(const NewsDetailState.loading());
    final result = await _getDetail(event.id);
    if (emit.isDone || request != _request) return;
    emit(result.fold(NewsDetailState.error, NewsDetailState.success));
  }
}
