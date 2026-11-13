import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalCommunicationStore {
  LocalCommunicationStore._();

  static const _storage = FlutterSecureStorage();

  static Future<List<Map<String, dynamic>>> loadNotifications(String ownerId) =>
      _loadList(_key('notifications', ownerId), _notificationExamples());

  static Future<void> saveNotifications(
    String ownerId,
    List<Map<String, dynamic>> items,
  ) => _saveList(_key('notifications', ownerId), items);

  static Future<List<Map<String, dynamic>>> loadConversations(String ownerId) =>
      _loadList(_key('chat', ownerId), _conversationExamples());

  static Future<void> saveConversations(
    String ownerId,
    List<Map<String, dynamic>> items,
  ) => _saveList(_key('chat', ownerId), items);

  static String _key(String feature, String ownerId) {
    final identity = base64Url.encode(
      utf8.encode(ownerId.trim().toLowerCase()),
    );
    return 'spm_local_${feature}_v1_$identity';
  }

  static Future<List<Map<String, dynamic>>> _loadList(
    String key,
    List<Map<String, dynamic>> initialItems,
  ) async {
    try {
      final raw = await _storage.read(key: key);
      if (raw == null) return initialItems;
      final value = jsonDecode(raw);
      if (value is! List) return initialItems;
      return [
        for (final item in value)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    } catch (_) {
      return initialItems;
    }
  }

  static Future<void> _saveList(String key, List<Map<String, dynamic>> items) =>
      _storage.write(key: key, value: jsonEncode(items));

  static List<Map<String, dynamic>> _notificationExamples() {
    final now = DateTime.now();
    return [
      {
        'id': 'web-example-1',
        'title': 'Bài nộp mới',
        'message': 'Bạn có một bài nộp mới trong khóa học Kỹ thuật phần mềm.',
        'timestamp': now.subtract(const Duration(minutes: 5)).toIso8601String(),
        'isRead': false,
        'type': 'info',
        'isExample': true,
      },
      {
        'id': 'web-example-2',
        'title': 'Điểm mới',
        'message': 'Ví dụ: một bài nộp đã được chấm điểm.',
        'timestamp': now
            .subtract(const Duration(minutes: 30))
            .toIso8601String(),
        'isRead': false,
        'type': 'success',
        'isExample': true,
      },
      {
        'id': 'web-example-3',
        'title': 'Thông báo quan trọng',
        'message': 'Ví dụ thông báo thay đổi lịch học.',
        'timestamp': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'isRead': true,
        'type': 'warning',
        'isExample': true,
      },
      {
        'id': 'web-example-4',
        'title': 'Tài liệu mới',
        'message': 'Ví dụ thông báo tài liệu mới trong khóa học.',
        'timestamp': now.subtract(const Duration(hours: 5)).toIso8601String(),
        'isRead': true,
        'type': 'info',
        'isExample': true,
      },
    ];
  }

  static List<Map<String, dynamic>> _conversationExamples() => [
    {
      'id': 'example-pdt',
      'title': 'Phòng đào tạo',
      'description': 'Kênh trao đổi minh họa',
      'isGroup': false,
      'isExample': true,
      'members': <String>[],
      'messages': <Map<String, dynamic>>[],
    },
    {
      'id': 'example-os',
      'title': 'Operating System Course',
      'description': 'Kênh trao đổi môn học minh họa',
      'isGroup': false,
      'isExample': true,
      'members': <String>[],
      'messages': <Map<String, dynamic>>[],
    },
    {
      'id': 'example-ppl',
      'title': 'Principle Programming Language',
      'description': 'Kênh trao đổi môn học minh họa',
      'isGroup': false,
      'isExample': true,
      'members': <String>[],
      'messages': <Map<String, dynamic>>[],
    },
    {
      'id': 'example-db',
      'title': 'Database System Course',
      'description': 'Kênh trao đổi môn học minh họa',
      'isGroup': false,
      'isExample': true,
      'members': <String>[],
      'messages': <Map<String, dynamic>>[],
    },
    {
      'id': 'example-cn',
      'title': 'Computer Network Course',
      'description': 'Kênh trao đổi môn học minh họa',
      'isGroup': false,
      'isExample': true,
      'members': <String>[],
      'messages': <Map<String, dynamic>>[],
    },
    {
      'id': 'example-intern',
      'title': 'Internship',
      'description': 'Kênh trao đổi chương trình minh họa',
      'isGroup': false,
      'isExample': true,
      'members': <String>[],
      'messages': <Map<String, dynamic>>[],
    },
    {
      'id': 'example-calc',
      'title': 'Calculus 1',
      'description': 'Kênh trao đổi môn học minh họa',
      'isGroup': false,
      'isExample': true,
      'members': <String>[],
      'messages': <Map<String, dynamic>>[],
    },
    {
      'id': 'example-group',
      'title': 'Nhóm học tập Toán Tin',
      'description': 'Nhóm minh họa · 5 thành viên',
      'isGroup': true,
      'isExample': true,
      'members': <String>[
        'Nguyễn Văn A',
        'Trần Thị B',
        'Lê Văn C',
        'Phạm Thị D',
        'Hoàng Văn E',
      ],
      'messages': <Map<String, dynamic>>[
        {
          'id': 'example-message-1',
          'sender': 'Nguyễn Văn A',
          'text':
              'Chào mọi người, chúng ta có buổi học nhóm vào thứ 7 này không?',
          'timestamp': DateTime.utc(2025, 11, 1, 10).toIso8601String(),
          'isExample': true,
        },
        {
          'id': 'example-message-2',
          'sender': 'Trần Thị B',
          'text':
              'Mình nghĩ là có, nhưng chưa chắc chắn lắm. Ai biết thì xác nhận giúp nhé!',
          'timestamp': DateTime.utc(2025, 11, 1, 10, 5).toIso8601String(),
          'isExample': true,
        },
      ],
    },
  ];
}
