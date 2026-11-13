import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalSessionRequestStore {
  LocalSessionRequestStore._();

  static const _storage = FlutterSecureStorage();

  static String _key(String ownerId) {
    final identity = base64Url.encode(
      utf8.encode(ownerId.trim().toLowerCase()),
    );
    return 'spm_student_session_request_drafts_v1_$identity';
  }

  static Future<List<Map<String, dynamic>>> load(String ownerId) async {
    try {
      final raw = await _storage.read(key: _key(ownerId));
      if (raw == null) return [];
      final value = jsonDecode(raw);
      if (value is! List) return [];
      return [
        for (final item in value)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(String ownerId, List<Map<String, dynamic>> drafts) =>
      _storage.write(key: _key(ownerId), value: jsonEncode(drafts));
}
