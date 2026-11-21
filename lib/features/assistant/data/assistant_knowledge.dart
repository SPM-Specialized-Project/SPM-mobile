import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _knowledgeAsset = 'assets/assistant/knowledge_vi.md';
const _assistantSourceUrl =
    'https://prism.openai.com/?u=a2be7451-b86c-491f-9e0b-f3b6eee1edc2&pg=1&m=main.tex';
const _roles = {'student', 'tutor'};
const _states = {'design', 'proposed', 'unresolved'};
const _stopWords = {
  'toi',
  'minh',
  'em',
  'ban',
  'hay',
  'cach',
  'lam',
  'nhu',
  'the',
  'nao',
  'co',
  'vui',
  'long',
  'huong',
  'dan',
  'de',
  'cho',
  've',
  'cua',
  'mot',
  'cai',
  'nhung',
  'cac',
  'a',
  'voi',
  'gi',
  'xin',
  'da',
  'duoc',
  'khong',
  'thi',
  'muon',
  'vao',
  'ra',
  'o',
  'trong',
  'bi',
  'nua',
  'hoac',
  'sao',
  'bang',
};
const _searchEquivalents = {
  'truc tuyen': 'online',
  'thoi khoa bieu': 'lich hoc',
  'bai viet': 'bai dang',
  'doi tuan': 'chuyen tuan',
  'gioi han si so': 'si so',
  'ba buoi': '3 buoi',
  'soan': 'viet',
};
const _liveMarkers = {
  'ngay mai',
  'hom nay',
  'hom qua',
  'tuan nay',
  'tuan toi',
  'tuan sau',
  'toi nay',
  'bay gio',
  'hien tai',
};
const _howToMarkers = {
  'cach',
  'huong dan',
  'o dau',
  'nhu the nao',
  'lam sao',
  'the nao',
};

const _diacriticGroups = <String, String>{
  'a': 'áàảãạăắằẳẵặâấầẩẫậ',
  'e': 'éèẻẽẹêếềểễệ',
  'i': 'íìỉĩị',
  'o': 'óòỏõọôốồổỗộơớờởỡợ',
  'u': 'úùủũụưứừửữự',
  'y': 'ýỳỷỹỵ',
};

final _diacriticLookup = <String, String>{
  for (final entry in _diacriticGroups.entries)
    for (final character in entry.value.runes)
      String.fromCharCode(character): entry.key,
};

enum AssistantDestination {
  courses('courses', 'Mở Khóa học', Icons.menu_book_rounded),
  schedule('schedule', 'Mở Lịch', Icons.event_note_rounded),
  library('library', 'Mở Thư viện', Icons.auto_stories_outlined),
  more('more', 'Mở Tiện ích', Icons.grid_view_rounded);

  const AssistantDestination(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;

  static AssistantDestination? parse(String? value) {
    for (final destination in values) {
      if (destination.key == value) return destination;
    }
    return null;
  }
}

class AssistantGuide {
  const AssistantGuide({
    required this.id,
    required this.title,
    required this.roles,
    required this.state,
    required this.source,
    required this.queries,
    required this.body,
    this.destination,
  });

  final String id;
  final String title;
  final Set<String> roles;
  final String state;
  final String source;
  final List<String> queries;
  final String body;
  final AssistantDestination? destination;
}

class AssistantReply {
  const AssistantReply({
    required this.status,
    required this.answer,
    required this.sources,
    this.title,
    this.note,
    this.featureStatus,
    this.mode,
    this.destination,
  });

  final String status;
  final String answer;
  final List<AssistantCitation> sources;
  final String? title;
  final String? note;
  final String? featureStatus;
  final String? mode;
  final AssistantDestination? destination;
}

class AssistantCitation {
  const AssistantCitation({required this.id, required this.section});

  final String id;
  final String section;
  String get url => _assistantSourceUrl;
}

class AssistantKnowledge {
  AssistantKnowledge(this.guides) {
    _index = [
      for (final guide in guides)
        (
          guide,
          [
            for (final query in [...guide.queries, guide.title]) _terms(query),
          ],
        ),
    ];
    final documentFrequency = <String, int>{};
    for (final (_, aliases) in _index) {
      final unique = aliases.expand((alias) => alias).toSet();
      for (final term in unique) {
        documentFrequency.update(term, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    _weights = {
      for (final entry in documentFrequency.entries)
        entry.key: 1 + math.log((1 + guides.length) / (1 + entry.value)),
    };
  }

  final List<AssistantGuide> guides;
  late final List<(AssistantGuide, List<Set<String>>)> _index;
  late final Map<String, double> _weights;

  static Future<List<AssistantGuide>> load() async {
    final markdown = (await rootBundle.loadString(
      _knowledgeAsset,
    )).replaceAll('\r\n', '\n');
    final headings = RegExp(
      r'^## ([A-Z]+-[0-9][A-Z0-9.-]*) — (.+)$',
      multiLine: true,
    ).allMatches(markdown).toList(growable: false);
    final guides = <AssistantGuide>[];
    final seen = <String>{};

    for (var index = 0; index < headings.length; index++) {
      final heading = headings[index];
      final nextStart = index + 1 < headings.length
          ? headings[index + 1].start
          : markdown.length;
      final block = markdown.substring(heading.end, nextStart).trim();
      final separator = block.indexOf('\n\n');
      if (separator < 0) {
        throw const FormatException('Đoạn hướng dẫn thiếu phần nội dung.');
      }
      final metadata = <String, String>{};
      for (final line in block.substring(0, separator).split('\n')) {
        final delimiter = line.indexOf(': ');
        if (delimiter > 0) {
          metadata[line.substring(0, delimiter).trim()] = line
              .substring(delimiter + 2)
              .trim();
        }
      }

      final id = heading.group(1)!;
      final roles = (metadata['Vai trò'] ?? '')
          .split(',')
          .map((role) => role.trim())
          .where((role) => role.isNotEmpty)
          .toSet();
      final state = metadata['Trạng thái'] ?? '';
      final source = metadata['Nguồn'] ?? '';
      final queries = (metadata['Câu hỏi mẫu'] ?? '')
          .split('|')
          .map((query) => query.trim())
          .where((query) => query.isNotEmpty)
          .toList(growable: false);
      final body = block.substring(separator + 2).trim();
      final destinationKey = metadata['Màn hình app'];
      final destination = AssistantDestination.parse(destinationKey);

      if (!seen.add(id) ||
          roles.isEmpty ||
          !roles.every(_roles.contains) ||
          !_states.contains(state) ||
          source.isEmpty ||
          queries.isEmpty ||
          body.isEmpty ||
          (destinationKey != null && destination == null)) {
        throw FormatException('Metadata hướng dẫn không hợp lệ: $id');
      }
      guides.add(
        AssistantGuide(
          id: id,
          title: heading.group(2)!.trim(),
          roles: roles,
          state: state,
          source: source,
          queries: queries,
          body: body,
          destination: destination,
        ),
      );
    }

    if (guides.isEmpty) {
      throw const FormatException(
        'Không tìm thấy hướng dẫn trong kho tri thức.',
      );
    }
    return guides;
  }

  AssistantReply answer(String question, String role) {
    if (!_roles.contains(role)) {
      throw ArgumentError.value(role, 'role', 'Vai trò không được hỗ trợ.');
    }
    if (question.length > 1000) {
      throw ArgumentError.value(
        question.length,
        'question',
        'Tối đa 1.000 ký tự.',
      );
    }

    final query = _normalize(question);
    if (query.isEmpty) {
      return _noMatch(
        'needs_clarification',
        'Bạn muốn được hướng dẫn thao tác nào?',
      );
    }
    if (_needsLiveData(query)) {
      return _noMatch(
        'unsupported',
        'Tôi chỉ có tài liệu hướng dẫn, chưa kết nối lịch, danh sách lớp hoặc dữ liệu cá nhân. Bạn có muốn biết cách mở mục xem lịch không?',
      );
    }

    final candidates = _retrieve(question, role);
    if (candidates.isEmpty) {
      return _noMatch(
        'unsupported',
        'Tôi chưa tìm được hướng dẫn phù hợp trong đặc tả cho vai trò này. Bạn có thể nêu rõ thao tác cần làm, ví dụ “Cách xem lịch học?”.',
      );
    }

    final (score, guide) = candidates.first;
    if (candidates.length > 1 && score - candidates[1].$1 <= 0.05) {
      return _noMatch(
        'needs_clarification',
        'Bạn muốn được hướng dẫn “${guide.title}” hay “${candidates[1].$2.title}”?',
      );
    }

    final note = switch (guide.state) {
      'design' =>
        'Theo thiết kế trong đặc tả; giao diện mobile thực tế có thể khác.',
      'proposed' => 'Đây là tính năng đề xuất, chưa xác nhận có trên app.',
      _ => 'Đặc tả chưa thống nhất quy tắc này.',
    };
    return AssistantReply(
      status: guide.state == 'unresolved' ? 'needs_review' : 'answered',
      title: guide.title,
      answer: guide.body,
      note: note,
      featureStatus: guide.state,
      sources: [AssistantCitation(id: guide.id, section: guide.source)],
      mode: 'retrieval',
      destination: guide.destination,
    );
  }

  List<(double, AssistantGuide)> _retrieve(String question, String role) {
    final query = _terms(question);
    final candidates = <(double, AssistantGuide)>[];
    for (final (guide, aliases) in _index) {
      if (!guide.roles.contains(role)) continue;
      var best = 0.0;
      for (final alias in aliases) {
        final shared = alias.intersection(query);
        if (shared.isEmpty) continue;
        if (query.length == alias.length && query.containsAll(alias)) {
          best = 1.0;
          break;
        }
        if (shared.length < 2) continue;
        final overlap = _weight(shared);
        final coverage = overlap / _weight(query);
        final score = 2 * overlap / (_weight(query) + _weight(alias));
        if (coverage >= 0.68 && score > best) best = score;
      }
      if (best >= 0.68) candidates.add((best, guide));
    }
    candidates.sort((left, right) {
      final scoreOrder = right.$1.compareTo(left.$1);
      return scoreOrder != 0 ? scoreOrder : left.$2.id.compareTo(right.$2.id);
    });
    return candidates;
  }

  double _weight(Set<String> words) =>
      words.fold<double>(0, (sum, word) => sum + (_weights[word] ?? 2.5));

  AssistantReply _noMatch(String status, String answer) =>
      AssistantReply(status: status, answer: answer, sources: const []);
}

Set<String> _terms(String text) {
  var normalized = _normalize(text);
  for (final entry in _searchEquivalents.entries) {
    normalized = normalized.replaceAll(
      RegExp('\\b${RegExp.escape(entry.key)}\\b'),
      entry.value,
    );
  }
  return normalized
      .split(' ')
      .where((term) => term.isNotEmpty && !_stopWords.contains(term))
      .toSet();
}

String _normalize(String text) {
  final output = StringBuffer();
  for (final rune in text.toLowerCase().replaceAll('đ', 'd').runes) {
    final character = String.fromCharCode(rune);
    output.write(_diacriticLookup[character] ?? character);
  }
  return output
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

bool _needsLiveData(String query) {
  final hasScheduleTerm = RegExp(r'\b(lich|buoi|lop|hoc)\b').hasMatch(query);
  final hasLiveMarker = _liveMarkers.any((marker) => query.contains(marker));
  final hasHowToMarker = _howToMarkers.any((marker) => query.contains(marker));
  return hasScheduleTerm && hasLiveMarker && !hasHowToMarker;
}
