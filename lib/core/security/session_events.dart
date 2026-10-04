import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionEventCounter extends Notifier<int> {
  @override
  int build() => 0;
  void advance() => state++;
}

final sessionExpiryProvider = NotifierProvider<SessionEventCounter, int>(
  SessionEventCounter.new,
);
final apiSessionEpochProvider = NotifierProvider<SessionEventCounter, int>(
  SessionEventCounter.new,
);
