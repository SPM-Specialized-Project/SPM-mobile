import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/core/security/token_storage.dart';
import 'package:spm_mobile/features/auth/application/auth_controller.dart';
import 'package:spm_mobile/features/auth/application/auth_providers.dart';
import 'package:spm_mobile/features/auth/data/auth_repository.dart';
import 'package:spm_mobile/features/auth/data/auth_session.dart';

import '../../../support/fake_token_storage.dart';

const _session = AuthSession(
  accessToken: 'token-demo',
  role: UserRole.student,
  user: AuthUser(
    id: 'student@gmail.com',
    email: 'student@gmail.com',
    firstName: 'Student',
    lastName: 'User',
    picture: null,
  ),
);

const _lecturerSession = AuthSession(
  accessToken: 'lecturer-token',
  role: UserRole.lecturer,
  user: AuthUser(
    id: 'lecturer@gmail.com',
    email: 'lecturer@gmail.com',
    firstName: 'Lecturer',
    lastName: 'User',
    picture: null,
  ),
);

typedef _LoginHandler =
    Future<AuthSession> Function({
      required String email,
      required String password,
    });

typedef _RestoreHandler = Future<AuthSession> Function(String token);

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository(super._dio, this._loginHandler, {this.restoreHandler});

  final _LoginHandler _loginHandler;
  final _RestoreHandler? restoreHandler;

  @override
  Future<AuthSession> login({required String email, required String password}) {
    return _loginHandler(email: email, password: password);
  }

  @override
  Future<AuthSession> restoreSession(String token) {
    return restoreHandler!(token);
  }
}

Future<ProviderContainer> _createContainer(
  _LoginHandler loginHandler, {
  String? initialToken,
  _RestoreHandler? restoreHandler,
}) async {
  final dio = Dio();
  final tokenStorage = FakeTokenStorage(token: initialToken);
  final repository = _FakeAuthRepository(
    dio,
    loginHandler,
    restoreHandler: restoreHandler,
  );
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      tokenStorageProvider.overrideWithValue(tokenStorage),
    ],
  );

  addTearDown(() {
    container.dispose();
    dio.close(force: true);
  });

  try {
    await container.read(authControllerProvider.future);
  } catch (_) {
    // Some tests deliberately model a failed startup session check.
  }
  return container;
}

void main() {
  group('AuthController', () {
    test('starts signed out when secure storage has no token', () async {
      final container = await _createContainer(
        ({required email, required password}) async => _session,
      );

      final state = container.read(authControllerProvider);

      expect(state, isA<AsyncData<AuthSession?>>());
      expect((state as AsyncData<AuthSession?>).value, isNull);
    });

    test('sets the session after a successful login', () async {
      final container = await _createContainer(
        ({required email, required password}) async => _session,
      );
      final controller = container.read(authControllerProvider.notifier);

      await controller.login(
        email: 'student@gmail.com',
        password: 'student123',
      );

      final state = container.read(authControllerProvider);
      expect(state, isA<AsyncData<AuthSession?>>());
      expect((state as AsyncData<AuthSession?>).value, _session);
      expect(
        (container.read(tokenStorageProvider) as FakeTokenStorage).token,
        _session.accessToken,
      );
    });

    test('exposes loading while the login request is pending', () async {
      final completer = Completer<AuthSession>();
      final container = await _createContainer(
        ({required email, required password}) => completer.future,
      );
      final controller = container.read(authControllerProvider.notifier);

      final loginFuture = controller.login(
        email: 'student@gmail.com',
        password: 'student123',
      );

      expect(container.read(authControllerProvider), isA<AsyncLoading>());

      completer.complete(_session);
      await loginFuture;
    });

    test('exposes an error when login fails', () async {
      final container = await _createContainer(({
        required email,
        required password,
      }) async {
        throw StateError('Invalid credentials');
      });
      final controller = container.read(authControllerProvider.notifier);

      await controller.login(
        email: 'student@gmail.com',
        password: 'wrong-password',
      );

      final state = container.read(authControllerProvider);
      expect(state, isA<AsyncError<AuthSession?>>());
      expect(state.error, isA<StateError>());
    });

    test('logout clears the session', () async {
      final container = await _createContainer(
        ({required email, required password}) async => _session,
      );
      final controller = container.read(authControllerProvider.notifier);

      await controller.login(
        email: 'student@gmail.com',
        password: 'student123',
      );
      await controller.logout();

      final state = container.read(authControllerProvider);
      expect(state, isA<AsyncData<AuthSession?>>());
      expect((state as AsyncData<AuthSession?>).value, isNull);
      expect(
        (container.read(tokenStorageProvider) as FakeTokenStorage).token,
        isNull,
      );
    });

    test('ignores a login response that arrives after logout', () async {
      final completer = Completer<AuthSession>();
      final container = await _createContainer(
        ({required email, required password}) => completer.future,
      );
      final controller = container.read(authControllerProvider.notifier);

      final loginFuture = controller.login(
        email: 'student@gmail.com',
        password: 'student123',
      );
      await controller.logout();
      completer.complete(_session);
      await loginFuture;

      final state = container.read(authControllerProvider);
      expect(state, isA<AsyncData<AuthSession?>>());
      expect((state as AsyncData<AuthSession?>).value, isNull);
    });

    test(
      'keeps the newest login when requests complete out of order',
      () async {
        final firstLogin = Completer<AuthSession>();
        final secondLogin = Completer<AuthSession>();
        var requestCount = 0;
        final container = await _createContainer(({
          required email,
          required password,
        }) {
          requestCount++;
          return requestCount == 1 ? firstLogin.future : secondLogin.future;
        });
        final controller = container.read(authControllerProvider.notifier);

        final firstRequest = controller.login(
          email: 'student@gmail.com',
          password: 'student123',
        );
        final secondRequest = controller.login(
          email: 'lecturer@gmail.com',
          password: 'lecturer123',
        );

        secondLogin.complete(_lecturerSession);
        await secondRequest;
        firstLogin.complete(_session);
        await firstRequest;

        final state = container.read(authControllerProvider);
        expect(state, isA<AsyncData<AuthSession?>>());
        expect((state as AsyncData<AuthSession?>).value, _lecturerSession);
        expect(
          (container.read(tokenStorageProvider) as FakeTokenStorage).token,
          _lecturerSession.accessToken,
        );
      },
    );

    test('restores a saved token through the backend session check', () async {
      final container = await _createContainer(
        ({required email, required password}) async => _session,
        initialToken: 'saved-token',
        restoreHandler: (token) async {
          expect(token, 'saved-token');
          return AuthSession(
            accessToken: token,
            user: _session.user,
            role: _session.role,
          );
        },
      );

      final state = container.read(authControllerProvider);
      expect(state.value?.accessToken, 'saved-token');
      expect(state.value?.user, _session.user);
      expect(state.value?.role, _session.role);
    });

    test('deletes an expired saved token when backend returns 401', () async {
      final container = await _createContainer(
        ({required email, required password}) async => _session,
        initialToken: 'expired-token',
        restoreHandler: (token) async {
          final request = RequestOptions(path: '/api/auth/me');
          throw DioException(
            requestOptions: request,
            response: Response<dynamic>(
              requestOptions: request,
              statusCode: 401,
            ),
          );
        },
      );

      expect(container.read(authControllerProvider).value, isNull);
      expect(
        (container.read(tokenStorageProvider) as FakeTokenStorage).token,
        isNull,
      );
    });

    test(
      'keeps a saved token if session validation fails due to a network error',
      () async {
        final container = await _createContainer(
          ({required email, required password}) async => _session,
          initialToken: 'saved-token',
          restoreHandler: (token) async => throw DioException(
            requestOptions: RequestOptions(path: '/api/auth/me'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        final state = container.read(authControllerProvider);
        expect(state.error, isA<SessionRestoreException>());
        expect(
          (container.read(tokenStorageProvider) as FakeTokenStorage).token,
          'saved-token',
        );
      },
    );
  });
}
