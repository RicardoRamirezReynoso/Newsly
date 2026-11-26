import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:newsly/core/network/dio_client.dart';
import 'package:newsly/features/news/data/datasources/news_local_data_source.dart';
import 'package:newsly/features/news/data/datasources/news_remote_data_source.dart';
import 'package:newsly/features/news/data/repositories/news_repository_impl.dart';
import 'package:newsly/features/news/domain/repositories/news_repository.dart';
import 'package:newsly/features/news/domain/usecases/get_favorites.dart';
import 'package:newsly/features/news/domain/usecases/get_news_detail.dart';
import 'package:newsly/features/news/domain/usecases/get_top_news.dart';
import 'package:newsly/features/news/domain/usecases/search_news.dart';
import 'package:newsly/features/news/domain/usecases/toggle_favorite.dart';
import 'package:newsly/features/news/presentation/bloc/favorites/favorites_bloc.dart';
import 'package:newsly/features/news/presentation/bloc/news_detail/news_detail_bloc.dart';
import 'package:newsly/features/news/presentation/bloc/news_list/news_list_bloc.dart';
import 'package:newsly/features/news/presentation/bloc/search/search_bloc.dart';

/// Abre Hive antes de registrar las dependencias que usan almacenamiento local.
Future<GetIt> initializeDependencies() async {
  final services = GetIt.instance;
  await dotenv.load(fileName: 'config/.env', isOptional: true);
  final key = dotenv.maybeGet('GUARDIAN_API_KEY')?.trim() ?? '';
  await Hive.initFlutter();
  final box = await Hive.openBox<String>(NewsLocalDataSource.boxName);

  services
    ..registerSingleton<Dio>(
      createGuardianDio(key),
      dispose: (dio) => dio.close(force: true),
    )
    ..registerSingleton<Box<String>>(box, dispose: (box) => box.close())
    ..registerLazySingleton(() => NewsRemoteDataSource(services()))
    ..registerLazySingleton(() => NewsLocalDataSource(services()))
    ..registerLazySingleton<NewsRepository>(
      () => NewsRepositoryImpl(services(), services()),
    )
    ..registerLazySingleton(() => GetTopNews(services()))
    ..registerLazySingleton(() => SearchNews(services()))
    ..registerLazySingleton(() => GetNewsDetail(services()))
    ..registerLazySingleton(() => GetFavorites(services()))
    ..registerLazySingleton(() => ToggleFavorite(services()))
    ..registerFactory(() => NewsListBloc(services()))
    ..registerFactory(() => SearchBloc(services()))
    ..registerFactory(() => NewsDetailBloc(services()))
    ..registerFactory(() => FavoritesBloc(services(), services()));
  return services;
}
