import 'package:flutter/material.dart';

class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({
    required this.memberId,
    required this.name,
    required this.email,
    required this.courseId,
    required this.courseTitle,
    this.courseCode,
    super.key,
  });

  final String memberId;
  final String name;
  final String email;
  final String courseId;
  final String courseTitle;
  final String? courseCode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final displayName = name.trim().isEmpty ? 'Thành viên khóa học' : name;
    final initial = displayName.substring(0, 1).toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin thành viên')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Center(
              child: Column(
                children: [
                  Hero(
                    tag: 'course-member-avatar-$courseId-$memberId',
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.onPrimaryContainer,
                      child: Text(
                        initial,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Thành viên trong lớp',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.alternate_email_rounded),
                    title: const Text('Email'),
                    subtitle: SelectableText(email),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: const Text('Khóa học'),
                    subtitle: Text(
                      courseCode == null || courseCode!.isEmpty
                          ? courseTitle
                          : '${courseCode!} · $courseTitle',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              margin: EdgeInsets.zero,
              color: colors.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Thông tin hiển thị được giới hạn ở dữ liệu thành viên mà API trả về cho khóa học này. Backend hiện chưa có API hồ sơ cá nhân để tải thêm thông tin.',
                  style: TextStyle(color: colors.onSecondaryContainer),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
