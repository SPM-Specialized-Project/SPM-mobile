import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/navigation/presentation/authenticated_app_shell.dart';
import '../features/auth/data/auth_session.dart';
import '../features/tssa/presentation/tssa_screen.dart';
import '../features/tssa/data/tssa_repository.dart';

import 'theme/app_theme.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authControllerProvider).value != null;
    final reduceMotion =
        signedIn &&
        ref.watch(tssaPreferencesProvider).value?['reduceMotion'] == true;
    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.value != null && !next.isLoading && next.value == null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => const _AuthenticationGate(),
            ),
            (_) => false,
          ),
        );
      }
    });
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Tutor Support System',
      theme: AppTheme.light,
      themeAnimationDuration: reduceMotion
          ? Duration.zero
          : kThemeAnimationDuration,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations:
              reduceMotion || MediaQuery.of(context).disableAnimations,
        ),
        child: child!,
      ),
      home: const _AuthenticationGate(),
    );
  }
}

class _AuthenticationGate extends ConsumerWidget {
  const _AuthenticationGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (authState.isLoading) return const _AuthenticationLoadingScreen();

    final session = authState.value;
    if (session != null) {
      if ([
        UserRole.tssaLearner,
        UserRole.tssaGuardian,
        UserRole.tssaTutor,
      ].contains(session.role)) {
        return const TssaScreen();
      }
      return AuthenticatedAppShell(session: session);
    }

    if (authState.error is SessionRestoreException) {
      return _SessionRestoreErrorScreen(
        onRetry: () => ref.invalidate(authControllerProvider),
      );
    }

    return const LoginScreen();
  }
}

class _AuthenticationLoadingScreen extends StatelessWidget {
  const _AuthenticationLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _SessionRestoreErrorScreen extends StatelessWidget {
  const _SessionRestoreErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_outlined, size: 48, color: colors.error),
                  const SizedBox(height: 18),
                  Text(
                    'Chưa thể xác minh phiên đăng nhập',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ứng dụng vẫn giữ phiên đã lưu. Hãy kiểm tra kết nối máy '
                    'chủ rồi thử lại; nếu phiên hết hạn, máy chủ sẽ yêu cầu '
                    'đăng nhập lại.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
