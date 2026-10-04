import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/token_storage.dart';
import '../../../core/security/session_events.dart';
import '../../../core/security/draft_storage.dart';
import '../data/auth_session.dart';
import 'auth_providers.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(
      AuthController.new,
      retry: (_, _) => null,
    );

class AuthController extends AsyncNotifier<AuthSession?> {
  var _loginRequestId = 0;
  Future<void> _tokenOperationQueue = Future<void>.value();

  @override
  Future<AuthSession?> build() async {
    ref.watch(sessionExpiryProvider);
    final tokenStorage = ref.read(tokenStorageProvider);

    try {
      final token = await tokenStorage.readAccessToken();
      if (token == null || token.trim().isEmpty) return null;

      return await ref.read(authRepositoryProvider).restoreSession(token);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await tokenStorage.clearAccessToken();
        return null;
      }
      throw SessionRestoreException(error);
    } catch (error) {
      if (error is SessionRestoreException) rethrow;
      throw SessionRestoreException(error);
    }
  }

  Future<void> login({required String email, required String password}) async {
    final requestId = ++_loginRequestId;
    state = const AsyncLoading<AuthSession?>();

    final result = await AsyncValue.guard<AuthSession?>(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);

      await _enqueueTokenOperation(() async {
        if (requestId == _loginRequestId) {
          await ref
              .read(tokenStorageProvider)
              .saveAccessToken(session.accessToken);
        }
      });
      if (requestId == _loginRequestId) {
        ref.read(apiSessionEpochProvider.notifier).advance();
      }

      if (requestId != _loginRequestId) return null;
      return session;
    });

    // Ignore an older request if a newer login or logout happened meanwhile.
    if (requestId == _loginRequestId) {
      state = result;
    }
  }

  Future<void> logout() async {
    // Invalidate pending login requests so they cannot restore the session.
    final requestId = ++_loginRequestId;
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      /* Local sign out must still work offline. */
    }
    await _enqueueTokenOperation(() async {
      if (requestId == _loginRequestId) {
        await ref.read(tokenStorageProvider).clearAccessToken();
      }
    });

    if (requestId != _loginRequestId) return;
    await DraftStorage.clear();
    ref.read(apiSessionEpochProvider.notifier).advance();
    state = const AsyncData<AuthSession?>(null);
  }

  Future<void> _enqueueTokenOperation(Future<void> Function() operation) {
    final queuedOperation = _tokenOperationQueue.then((_) => operation());
    _tokenOperationQueue = queuedOperation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return queuedOperation;
  }
}

class SessionRestoreException implements Exception {
  const SessionRestoreException(this.cause);

  final Object cause;

  @override
  String toString() => 'Could not restore the saved session: $cause';
}
