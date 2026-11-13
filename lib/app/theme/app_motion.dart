import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const navigationDuration = Duration(milliseconds: 180);

  static Duration duration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : navigationDuration;

  static Widget pageTransition(
    BuildContext context,
    Widget child,
    Animation<double> animation,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.015, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
