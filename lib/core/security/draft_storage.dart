import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Drafts are encrypted by the platform secure store and expire after 24 hours.
/// Server profiles are never persisted as an offline cache.
class DraftStorage {
  static const _storage = FlutterSecureStorage();
  static String _key(String owner, String form) =>
      'tssa_draft_${base64Url.encode(utf8.encode('$owner:$form'))}';

  Future<Map<String, dynamic>?> read(String owner, String form) async {
    final key = _key(owner, form);
    final raw = await _storage.read(key: key);
    if (raw == null) return null;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (DateTime.parse(data['expiresAt'] as String).isBefore(DateTime.now())) {
      await _storage.delete(key: key);
      return null;
    }
    return data;
  }

  Future<void> write(String owner, String form, Map<String, dynamic> data) =>
      _storage.write(
        key: _key(owner, form),
        value: jsonEncode({
          ...data,
          'expiresAt': DateTime.now()
              .add(const Duration(hours: 24))
              .toUtc()
              .toIso8601String(),
        }),
      );

  Future<void> remove(String owner, String form) =>
      _storage.delete(key: _key(owner, form));

  static Future<void> clear() async {
    final keys = (await _storage.readAll()).keys
        .where((key) => key.startsWith('tssa_draft_'))
        .toList();
    for (final key in keys) {
      await _storage.delete(key: key);
    }
  }
}
