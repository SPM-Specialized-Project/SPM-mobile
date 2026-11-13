import 'package:flutter/material.dart';

import '../../auth/data/auth_session.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';

enum CommunicationFeature { notifications, chat }

class CommunicationStatusScreen extends StatelessWidget {
  const CommunicationStatusScreen({
    required this.feature,
    required this.ownerId,
    required this.role,
    super.key,
  });

  final CommunicationFeature feature;
  final String ownerId;
  final UserRole role;

  @override
  Widget build(BuildContext context) => switch (feature) {
    CommunicationFeature.notifications => NotificationsScreen(ownerId: ownerId),
    CommunicationFeature.chat => ChatScreen(ownerId: ownerId, role: role),
  };
}
