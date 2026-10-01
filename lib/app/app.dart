import 'package:flutter/material.dart';

import '../features/component_catalog/presentation/mobile_home_screen.dart';
import 'theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tutor Support System',
      theme: AppTheme.light,
      home: const MobileHomeScreen(),
    );
  }
}
