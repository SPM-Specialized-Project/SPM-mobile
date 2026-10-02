import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;

  static const _horizontalPadding = 20.0;
  static const _maximumContentWidth = 460.0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (ref.read(authControllerProvider).isLoading) return;

    await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  String _messageFor(Object error) {
    if (error is DioException) {
      switch (error.response?.statusCode) {
        case 401:
          return 'Email hoặc mật khẩu không đúng.';
        case 403:
          return 'Tài khoản đang bị khóa hoặc không được phép truy cập.';
      }
    }

    return 'Không thể đăng nhập. Hãy kiểm tra kết nối rồi thử lại.';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final errorMessage = authState.hasError
        ? _messageFor(authState.error!)
        : null;
    final session = authState.value;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF0FF), Color(0xFFF5F7FC), Color(0xFFF5F7FC)],
            stops: [0, 0.38, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth =
                  (constraints.maxWidth - 2 * _horizontalPadding)
                      .clamp(0.0, _maximumContentWidth)
                      .toDouble();
              final minimumHeight = (constraints.maxHeight - 48)
                  .clamp(0.0, double.infinity)
                  .toDouble();

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: _horizontalPadding,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minimumHeight),
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _BrandHeader(),
                          const SizedBox(height: 28),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: colors.outlineVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1D3478,
                                  ).withValues(alpha: 0.08),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Chào mừng trở lại',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: const Color(0xFF1E2A4A),
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Đăng nhập bằng tài khoản HCMUT của bạn.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.username,
                                    ],
                                    autocorrect: false,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      hintText: 'name@example.com',
                                      prefixIcon: Icon(
                                        Icons.alternate_email_rounded,
                                      ),
                                    ),
                                    validator: (value) {
                                      final email = value?.trim() ?? '';
                                      if (email.isEmpty) {
                                        return 'Vui lòng nhập email.';
                                      }
                                      if (!email.contains('@')) {
                                        return 'Email chưa đúng định dạng.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _hidePassword,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    decoration: InputDecoration(
                                      labelText: 'Mật khẩu',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                      ),
                                      suffixIcon: IconButton(
                                        tooltip: _hidePassword
                                            ? 'Hiện mật khẩu'
                                            : 'Ẩn mật khẩu',
                                        onPressed: () {
                                          setState(() {
                                            _hidePassword = !_hidePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _hidePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Vui lòng nhập mật khẩu.';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (errorMessage != null) ...[
                                    const SizedBox(height: 16),
                                    _MessagePanel(
                                      message: errorMessage,
                                      color: colors.error,
                                      backgroundColor: colors.errorContainer,
                                      icon: Icons.error_outline_rounded,
                                    ),
                                  ],
                                  if (session != null) ...[
                                    const SizedBox(height: 16),
                                    _MessagePanel(
                                      message:
                                          'Xin chào ${session.user.name} · ${session.role.name}',
                                      color: colors.onPrimaryContainer,
                                      backgroundColor: colors.primaryContainer,
                                      icon: Icons.verified_outlined,
                                    ),
                                  ],
                                  const SizedBox(height: 22),
                                  SizedBox(
                                    height: 54,
                                    child: FilledButton(
                                      onPressed: authState.isLoading
                                          ? null
                                          : _submit,
                                      child: authState.isLoading
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: colors.onPrimary,
                                                      ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Text('Đang đăng nhập...'),
                                              ],
                                            )
                                          : const Text('Đăng nhập'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'TUTOR SUPPORT SYSTEM · HCMUT',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: colors.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Image.asset('assets/branding/bachkhoa.png'),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HCMUT SSO',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              'TUTOR SUPPORT SYSTEM',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                letterSpacing: 0.9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.message,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  final String message;
  final Color color;
  final Color backgroundColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
