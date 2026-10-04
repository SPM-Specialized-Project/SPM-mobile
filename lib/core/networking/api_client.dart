import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../security/token_storage.dart';
import '../security/session_events.dart';
import '../security/draft_storage.dart';

final apiClientProvider = Provider<Dio>((ref) {
  ref.watch(apiSessionEpochProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: const {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await tokenStorage.readAccessToken();
          if (token != null && token.trim().isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        } catch (error, stackTrace) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: error,
              stackTrace: stackTrace,
            ),
          );
        }
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final data = error.response?.data;
        final code = data is Map ? data['code'] : null;
        if ((status == 401 && error.requestOptions.path != '/api/auth/login') ||
            code == 'ACCOUNT_LOCKED') {
          final current = await tokenStorage.readAccessToken();
          if (current != null &&
              error.requestOptions.headers['Authorization'] ==
                  'Bearer $current') {
            await tokenStorage.clearAccessToken();
            await DraftStorage.clear();
            ref.read(sessionExpiryProvider.notifier).advance();
            ref.read(apiSessionEpochProvider.notifier).advance();
          }
        } else if (status == 403 &&
            error.requestOptions.path.startsWith('/api/v1/')) {
          await DraftStorage.clear();
        }
        handler.next(error);
      },
    ),
  );

  ref.onDispose(() => dio.close());
  return dio;
});
