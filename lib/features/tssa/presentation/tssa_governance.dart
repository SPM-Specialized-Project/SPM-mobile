import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/tssa_repository.dart';
import 'tssa_form.dart';
import 'tssa_profiles.dart';
import 'tssa_ui.dart';

class TssaSupport extends ConsumerWidget {
  const TssaSupport({required this.me, super.key});
  final TssaData me;
  Future<void> _report(
    BuildContext context,
    WidgetRef ref,
    VoidCallback reload,
  ) async {
    final bookings = tssaItems(
      await ref.read(tssaRepositoryProvider).read('bookings'),
    );
    if (!context.mounted) return;
    await tssaOpenForm(
      context,
      TssaFormScreen(
        title: 'Báo vấn đề',
        path: 'safety-cases',
        fields: [
          TssaField(
            'groupId',
            'Nhóm dịch vụ',
            kind: 'select',
            required: true,
            options: tssaGroups(me),
          ),
          const TssaField(
            'type',
            'Loại vấn đề',
            kind: 'select',
            required: true,
            options: {
              'QUALITY': 'Chất lượng buổi học',
              'SCHEDULE': 'Lịch',
              'PRIVACY': 'Riêng tư',
              'SAFETY': 'An toàn',
              'OTHER': 'Khác',
            },
          ),
          const TssaField(
            'description',
            'Điều cần xử lý',
            kind: 'long',
            required: true,
          ),
          TssaField(
            'bookingId',
            'Booking liên quan (tùy chọn)',
            kind: 'select',
            options: {
              '': 'Không gắn booking',
              for (final booking in bookings)
                booking['id'] as String: tssaDate(booking['start']),
            },
            value: '',
          ),
          const TssaField(
            'visibility',
            'Mức riêng tư',
            kind: 'select',
            required: true,
            options: {
              'HANDLER_ONLY': 'Người xử lý được phân công',
              'RESTRICTED': 'Người xử lý và privacy role',
            },
            value: 'HANDLER_ONLY',
          ),
          const TssaField(
            'urgency',
            'Mức độ',
            kind: 'select',
            required: true,
            options: {
              'NORMAL': 'Hỗ trợ vận hành thông thường',
              'URGENT': 'Cần tổ chức hỗ trợ khẩn',
            },
            value: 'NORMAL',
          ),
          const TssaField(
            'contact',
            'Cách liên hệ bạn cho phép',
            hint: 'Chỉ cung cấp phần cần để người xử lý liên hệ.',
          ),
        ],
        explanation:
            'Sau khi gửi bạn nhận mã case. App xác nhận đã tiếp nhận, không xác nhận đã giải quyết. Không ghi âm/video và không cần chẩn đoán.',
      ),
      reload,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => TssaView(
    path: 'safety-cases',
    builder: (data, reload) => TssaList(
      title: 'Hỗ trợ và an toàn',
      children: [
        const Text(
          'Dịch vụ giáo dục và điều phối tutor. Không dùng ứng dụng để chẩn đoán hoặc yêu cầu điều trị.',
        ),
        Text(
          (me['policy'] as Map?)?['nonRetaliation']?.toString() ??
              'Báo vấn đề không làm mất quyền đổi tutor hoặc đóng dịch vụ.',
        ),
        TssaCard(
          title: 'Trường hợp cần hỗ trợ khẩn',
          children: [
            Text(
              (me['policy'] as Map?)?['emergencyContact']?.toString() ??
                  'Tổ chức chưa xác minh kênh khẩn cho pilot. App không phải kênh phản hồi khẩn. Liên hệ đầu mối trực tiếp của tổ chức.',
            ),
            Text(
              'Đầu mối vận hành: ${(me['policy'] as Map?)?['safetyContact'] ?? 'Chưa cấu hình'}\nGiờ tiếp nhận: ${(me['policy'] as Map?)?['safetyHours'] ?? 'Chưa cấu hình'}',
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () => _report(context, ref, reload),
          icon: const Icon(Icons.support_agent),
          label: const Text('Báo vấn đề / lo ngại'),
        ),
        for (final item in tssaItems(data))
          TssaCard(
            title: 'Case ${item['id']}',
            subtitle: tssaStatus(item['status']),
            onTap: () => tssaOpenPage(
              context,
              'Case của bạn',
              TssaCasePage(me: me, caseId: item['id'] as String),
            ),
          ),
        OutlinedButton(
          onPressed: () => tssaOpenPage(
            context,
            'Yêu cầu quyền dữ liệu',
            TssaPrivacyQueue(me: me),
          ),
          child: const Text('Theo dõi export / delete'),
        ),
      ],
    ),
  );
}

class TssaCasePage extends StatelessWidget {
  const TssaCasePage({required this.me, required this.caseId, super.key});
  final TssaData me;
  final String caseId;
  @override
  Widget build(BuildContext context) => TssaView(
    path: 'safety-cases/$caseId',
    builder: (data, reload) => TssaList(
      title: 'Case $caseId',
      children: [
        TssaPanel(data),
        if ((me['permissions'] as List?)?.any(
                  (permission) => ['safety', 'privacy'].contains(permission),
                ) ==
                true &&
            data['reporterId'] != me['id'])
          FilledButton(
            onPressed: () => tssaOpenForm(
              context,
              TssaFormScreen(
                title: 'Ghi nhận xử lý case',
                path: 'safety-cases/$caseId',
                patch: true,
                extra: {'expectedRevision': data['revision']},
                fields: const [
                  TssaField(
                    'status',
                    'Bước xử lý',
                    kind: 'select',
                    required: true,
                    options: {
                      'RECEIVED': 'Đã tiếp nhận',
                      'IN_REVIEW': 'Đang xem',
                      'WAITING_INFO': 'Chờ bổ sung',
                      'RESOLVED': 'Đã xử lý',
                      'CLOSED': 'Đóng case',
                    },
                  ),
                  TssaField(
                    'handlerId',
                    'Tài khoản người xử lý mới (nếu chuyển)',
                  ),
                  TssaField(
                    'reason',
                    'Ghi nhận bước xử lý',
                    kind: 'long',
                    required: true,
                  ),
                ],
                transform: (values) {
                  if (values['handlerId'] == '') values.remove('handlerId');
                  return values;
                },
              ),
              reload,
            ),
            child: const Text('Cập nhật / chuyển người xử lý'),
          ),
      ],
    ),
  );
}

class TssaPrivacyQueue extends StatelessWidget {
  const TssaPrivacyQueue({required this.me, super.key});
  final TssaData me;
  @override
  Widget build(BuildContext context) => TssaView(
    path: 'privacy/requests',
    builder: (data, reload) => TssaList(
      title: 'Quyền dữ liệu',
      children: [
        if (tssaItems(data).isEmpty)
          const Text('Chưa có yêu cầu quyền dữ liệu thuộc phạm vi của bạn.'),
        for (final item in tssaItems(data))
          TssaCard(
            title: '${item['type']} · ${item['id']}',
            subtitle: tssaStatus(item['status']),
            onTap: () => tssaOpenPage(
              context,
              'Yêu cầu quyền dữ liệu',
              TssaView(
                path: 'privacy/requests/${item['id']}',
                builder: (detail, refresh) => TssaList(
                  title: tssaStatus(detail['status']),
                  children: [
                    TssaPanel(detail),
                    if (detail['exportData'] != null)
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text: const JsonEncoder.withIndent(
                                '  ',
                              ).convert(detail['exportData']),
                            ),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép bản sao dữ liệu.'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Sao chép bản sao dữ liệu của bạn'),
                      ),
                    if ((me['permissions'] as List?)?.contains('privacy') ==
                        true)
                      FilledButton(
                        onPressed: () => tssaOpenForm(
                          context,
                          TssaFormScreen(
                            title: 'Xử lý quyền dữ liệu',
                            path: 'privacy/requests/${item['id']}',
                            patch: true,
                            extra: {'expectedRevision': detail['revision']},
                            fields: const [
                              TssaField(
                                'status',
                                'Trạng thái xử lý',
                                kind: 'select',
                                required: true,
                                options: {
                                  'IN_REVIEW': 'Đang review',
                                  'NEEDS_INFO': 'Cần bổ sung',
                                  'DENIED': 'Từ chối có giải thích',
                                  'COMPLETED': 'Hoàn tất phạm vi được duyệt',
                                },
                              ),
                              TssaField(
                                'reason',
                                'Phạm vi / căn cứ xử lý',
                                kind: 'long',
                                required: true,
                              ),
                              TssaField(
                                'exceptions',
                                'Các ngoại lệ được giải thích',
                                kind: 'list',
                              ),
                            ],
                            explanation:
                                'Delete bị chặn khi chưa duyệt retention/backup hoặc còn booking hoạt động. Audit gốc được giữ theo chính sách.',
                          ),
                          refresh,
                        ),
                        child: const Text('Review và xử lý'),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class TssaNotifications extends StatelessWidget {
  const TssaNotifications({super.key});
  @override
  Widget build(BuildContext context) => TssaView(
    path: 'notifications',
    builder: (data, reload) => TssaList(
      title: 'Thông báo',
      children: [
        const Text(
          'Thông báo ngoài app chỉ có nội dung chung. Trạng thái chính được đọc từ máy chủ.',
        ),
        for (final item in tssaItems(data).reversed)
          TssaCard(
            title: item['preview'] as String,
            subtitle: '${item['category']} · ${tssaDate(item['createdAt'])}',
            children: [
              Text('Cập nhật: ${item['event']}'),
              if (item['read'] != true)
                TextButton(
                  onPressed: () => tssaOpenForm(
                    context,
                    TssaFormScreen(
                      title: 'Đánh dấu đã đọc',
                      path: 'notifications/${item['id']}',
                      patch: true,
                      extra: {'expectedRevision': item['revision']},
                      fields: const [],
                    ),
                    reload,
                  ),
                  child: const Text('Đánh dấu đã đọc'),
                ),
            ],
          ),
      ],
    ),
  );
}

class TssaPreferences extends ConsumerWidget {
  const TssaPreferences({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => TssaView(
    path: 'preferences',
    builder: (data, reload) => TssaList(
      title: 'Cách dùng phù hợp với bạn',
      children: [
        const Text(
          'App dùng câu ngắn, không bật âm thanh và không ghi âm/video. Có thể dùng text scaling và trình đọc màn hình của thiết bị.',
        ),
        FilledButton(
          onPressed: () => tssaOpenForm(
            context,
            TssaFormScreen(
              title: 'Tùy chọn sử dụng',
              path: 'preferences',
              patch: true,
              initial: data,
              extra: {'expectedRevision': data['revision']},
              fields: const [
                TssaField('reduceMotion', 'Giảm chuyển động', kind: 'bool'),
                TssaField(
                  'simpleLanguage',
                  'Ưu tiên câu ngắn',
                  kind: 'bool',
                  value: true,
                ),
                TssaField(
                  'muted',
                  'Tắt nhóm thông báo không bắt buộc',
                  kind: 'multi',
                  options: {
                    'requests': 'Yêu cầu ghép',
                    'bookings': 'Lịch / buổi học',
                    'consent': 'Consent',
                  },
                ),
              ],
              explanation:
                  'Thông báo safety quan trọng vẫn ở trong app. Push chỉ bật khi tổ chức có kênh và policy được xác minh.',
            ),
            () {
              reload();
              ref.invalidate(tssaPreferencesProvider);
            },
          ),
          child: const Text('Chỉnh tùy chọn'),
        ),
      ],
    ),
  );
}

const decisionLabels = {
  'D-01': 'Độ tuổi, địa bàn và hình thức pilot',
  'D-02': 'Mô hình phí và chính sách dịch vụ',
  'D-03': 'Tiêu chí xác minh / safeguarding tutor',
  'D-04': 'Xác minh quan hệ guardian–learner',
  'D-05': 'Dữ liệu bắt buộc, tùy chọn và retention',
  'D-06': 'Consent và sự tham gia của learner',
  'D-07': 'Quy trình safety và kênh khẩn',
  'D-08': 'Danh tính và vai trò mobile',
  'D-09': 'Tiêu chí matching và cách đo',
  'D-10': 'Hạ tầng, provider, backup và xử lý sự cố',
  'D-11': 'Ranh giới module CodePulse',
  'D-12': 'Owner sản phẩm, privacy, safety và model',
};
const gateLabels = {
  'representativeUsability': 'Usability với người dùng đại diện',
  'privacyReview': 'Review privacy',
  'safeguardingReview': 'Review safeguarding',
  'backupRestore': 'Bằng chứng backup / restore và retention',
  'securityReview': 'Review quyền và bảo mật',
  'shadowEvaluation': 'Shadow evaluation',
  'fairnessReview': 'Review fairness',
};

class TssaGovernance extends StatelessWidget {
  const TssaGovernance({required this.me, super.key});
  final TssaData me;
  void _policyForm(
    BuildContext context,
    TssaData data,
    VoidCallback reload,
  ) => tssaOpenForm(
    context,
    TssaFormScreen(
      title: 'Quy trình tổ chức',
      path: 'governance/policy',
      patch: true,
      initial: {
        ...data,
        'fairnessGapPercent': data['fairnessNoMatchGap'] == null
            ? null
            : ((data['fairnessNoMatchGap'] as num) * 100).round(),
        'groupsText': ((data['serviceGroups'] as List?) ?? [])
            .map((group) => '${group['id']} | ${group['label']}')
            .join('\n'),
      },
      extra: {'expectedRevision': data['revision'] ?? 0},
      fields: const [
        TssaField('version', 'Phiên bản policy', required: true),
        TssaField('owner', 'Product owner', required: true),
        TssaField(
          'groupsText',
          'Nhóm dịch vụ',
          kind: 'long',
          hint:
              'Mỗi dòng: mã nhóm | tên hiển thị. Ví dụ: pilot-local | Nhóm pilot.',
        ),
        TssaField(
          'verificationCriteria',
          'Tiêu chí xác minh tutor',
          kind: 'long',
        ),
        TssaField(
          'guardianVerification',
          'Quy trình xác minh guardian và escalation',
          kind: 'long',
        ),
        TssaField(
          'consentText',
          'Nội dung consent đã được review',
          kind: 'long',
        ),
        TssaField('changePolicy', 'Chính sách đổi / hủy lịch', kind: 'long'),
        TssaField('ruleOwner', 'Người phụ trách luật matching'),
        TssaField('ruleVersion', 'Phiên bản hard filter', required: true),
        TssaField('ruleApprovedBy', 'Người đã duyệt luật matching'),
        TssaField('ruleReviewRef', 'Tham chiếu review luật matching'),
        TssaField(
          'fairnessGapPercent',
          'Chênh lệch no-match cần tắt AI (%, tổ chức duyệt)',
          kind: 'number',
          hint:
              '0–100. Chỉ áp dụng khi đủ consent, cỡ mẫu và review; đây là tín hiệu vận hành cần xem lại.',
        ),
        TssaField('safetyContact', 'Đầu mối safety'),
        TssaField('safetyHours', 'Giờ tiếp nhận'),
        TssaField('safetySla', 'SLA tiếp nhận'),
        TssaField('privacyContact', 'Đầu mối privacy'),
        TssaField('emergencyContact', 'Kênh khẩn được tổ chức xác minh'),
        TssaField('emergencyVerifiedBy', 'Người xác minh kênh khẩn'),
        TssaField('emergencyEvidenceRef', 'Tham chiếu xác minh kênh khẩn'),
        TssaField(
          'retentionDays',
          'Retention dữ liệu vận hành (ngày)',
          kind: 'number',
        ),
        TssaField(
          'auditRetentionDays',
          'Retention / ngoại lệ audit (ngày)',
          kind: 'number',
        ),
        TssaField(
          'backupRetentionDays',
          'Retention backup (ngày)',
          kind: 'number',
        ),
      ],
      transform: (values) {
        final groups = (values.remove('groupsText') as String)
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) {
              final parts = line.split('|');
              return {
                'id': parts.first.trim(),
                'label': parts.length > 1
                    ? parts.sublist(1).join('|').trim()
                    : parts.first.trim(),
              };
            })
            .toList();
        final threshold = values.remove('fairnessGapPercent') as num?;
        return {
          ...values,
          'fairnessNoMatchGap': threshold == null
              ? data['fairnessNoMatchGap']
              : threshold / 100,
          'serviceGroups': groups,
          'status': 'PENDING_REVIEW',
        };
      },
      explanation:
          'Đây là cấu hình của tổ chức, không phải xác nhận pháp lý tự động. Chỉ điền quy trình và bằng chứng đã thực hiện.',
    ),
    reload,
  );
  @override
  Widget build(BuildContext context) => TssaView(
    path: 'governance/policy',
    builder: (data, reload) => TssaList(
      title: 'Quản trị TSSA',
      children: [
        TssaCard(
          title: 'Policy ${data['version']}',
          subtitle: tssaStatus(data['status']),
          children: [
            Text('Owner: ${data['owner']}'),
            Text(
              'AI: ${data['modelEnabled'] == true ? 'Được bật theo bằng chứng review' : 'Đang tắt; dùng baseline / thủ công'}',
            ),
          ],
        ),
        FilledButton(
          onPressed: () => _policyForm(context, data, reload),
          child: const Text('Điền quy trình và nhóm dịch vụ'),
        ),
        for (final entry in decisionLabels.entries)
          TssaCard(
            title: '${entry.key} · ${entry.value}',
            subtitle: tssaStatus(
              (data['decisions'] as Map)[entry.key]['status'],
            ),
            children: [
              Text(
                (data['decisions'] as Map)[entry.key]['decision']?.toString() ??
                    '',
              ),
              OutlinedButton(
                onPressed: () => tssaOpenForm(
                  context,
                  TssaFormScreen(
                    title: entry.value,
                    path: 'governance/policy',
                    patch: true,
                    initial: Map<String, dynamic>.from(
                      (data['decisions'] as Map)[entry.key] as Map,
                    ),
                    extra: {'expectedRevision': data['revision'] ?? 0},
                    fields: const [
                      TssaField(
                        'status',
                        'Kết quả',
                        kind: 'select',
                        required: true,
                        options: {
                          'OPEN': 'Còn mở',
                          'APPROVED': 'Đã được tổ chức chốt',
                        },
                      ),
                      TssaField(
                        'decision',
                        'Quyết định cụ thể',
                        kind: 'long',
                        required: true,
                      ),
                      TssaField('owner', 'Owner quyết định', required: true),
                      TssaField(
                        'evidenceRef',
                        'Tham chiếu bằng chứng / phê duyệt',
                        required: true,
                      ),
                    ],
                    transform: (values) => {
                      'decisions': {entry.key: values},
                    },
                  ),
                  reload,
                ),
                child: const Text('Ghi quyết định và bằng chứng'),
              ),
            ],
          ),
        OutlinedButton(
          onPressed: () => tssaOpenForm(
            context,
            TssaFormScreen(
              title: 'Bằng chứng trước pilot / bật AI',
              path: 'governance/policy',
              patch: true,
              initial: Map<String, dynamic>.from(data['releaseGates'] as Map),
              extra: {'expectedRevision': data['revision'] ?? 0},
              fields: [
                for (final entry in gateLabels.entries)
                  TssaField(entry.key, entry.value),
              ],
              transform: (values) => {'releaseGates': values},
            ),
            reload,
          ),
          child: const Text('Release gates và bằng chứng review'),
        ),
        OutlinedButton(
          onPressed: () => tssaOpenForm(
            context,
            TssaFormScreen(
              title: 'Phê duyệt policy vận hành',
              path: 'governance/policy',
              patch: true,
              extra: {
                'expectedRevision': data['revision'] ?? 0,
                'status': 'APPROVED',
              },
              fields: const [
                TssaField(
                  'evidenceRef',
                  'Tham chiếu phê duyệt vận hành',
                  required: true,
                ),
              ],
              explanation:
                  'Chỉ có thể duyệt khi các quyết định D-01…D-12 và quy trình cốt lõi đã được chốt.',
            ),
            reload,
          ),
          child: const Text('Ghi phê duyệt vận hành'),
        ),
        OutlinedButton(
          onPressed: () =>
              tssaOpenPage(context, 'Quyền và thời hạn', TssaBindings(me: me)),
          child: const Text('Review role và phạm vi truy cập'),
        ),
        OutlinedButton(
          onPressed: () =>
              tssaOpenPage(context, 'Model và rollback', const TssaModels()),
          child: const Text('Model card / rollback'),
        ),
        OutlinedButton(
          onPressed: () => tssaOpenForm(
            context,
            TssaFormScreen(
              title: 'Chế độ matching',
              path: 'governance/policy',
              patch: true,
              initial: data,
              extra: {'expectedRevision': data['revision'] ?? 0},
              fields: const [
                TssaField(
                  'matchingMode',
                  'Chế độ',
                  kind: 'select',
                  required: true,
                  options: {
                    'MANUAL': 'Thủ công',
                    'RULE_BASELINE': 'Luật / bảng điểm',
                    'SHADOW': 'AI shadow',
                    'MODEL_ASSISTED': 'Gợi ý AI có coordinator',
                  },
                ),
                TssaField(
                  'modelEnabled',
                  'Bật model sau khi đủ review / evidence',
                  kind: 'bool',
                ),
              ],
              explanation:
                  'Backend chặn bật model khi thiếu model card, review hoặc gate. Lỗi provider sẽ tắt model và quay về baseline.',
            ),
            reload,
          ),
          child: const Text('Chọn baseline / tắt hoặc bật AI theo gate'),
        ),
      ],
    ),
  );
}

class TssaBindings extends StatelessWidget {
  const TssaBindings({required this.me, super.key});
  final TssaData me;
  @override
  Widget build(BuildContext context) => TssaView(
    path: 'governance/bindings',
    builder: (data, reload) => TssaList(
      title: 'Review quyền có thời hạn',
      children: [
        const Text(
          'Admin không tự được xem hồ sơ learner. Privacy/safety cần quyền, nhóm và thời hạn cụ thể.',
        ),
        FilledButton(
          onPressed: () => tssaOpenForm(
            context,
            TssaFormScreen(
              title: 'Cấp / rà soát / khóa quyền',
              path: 'governance/bindings',
              fields: [
                TssaField(
                  'accountId',
                  'Tài khoản',
                  kind: 'select',
                  required: true,
                  options: {
                    for (final account in data['accounts'] as List)
                      account['email'] as String: account['email'] as String,
                  },
                ),
                const TssaField(
                  'role',
                  'Vai trò TSSA',
                  kind: 'select',
                  required: true,
                  options: {
                    'learner': 'Learner',
                    'guardian': 'Guardian',
                    'tutor': 'Tutor',
                    'coordinator': 'Coordinator',
                    'admin': 'Admin metadata',
                    'unassigned': 'Thu hồi vai trò',
                  },
                ),
                TssaField(
                  'groups',
                  'Nhóm được phân công',
                  kind: 'multi',
                  options: tssaGroups(me),
                ),
                const TssaField(
                  'permissions',
                  'Quyền đặc biệt',
                  kind: 'multi',
                  options: {
                    'privacy': 'Privacy theo nhóm',
                    'safety': 'Safety theo nhóm',
                    'governance': 'Quản trị metadata / policy',
                  },
                ),
                const TssaField(
                  'status',
                  'Trạng thái',
                  kind: 'select',
                  required: true,
                  options: {'ACTIVE': 'Hoạt động', 'LOCKED': 'Khóa tài khoản'},
                ),
                const TssaField(
                  'expiresAt',
                  'Ngày rà lại / hết hạn',
                  kind: 'date',
                  required: true,
                ),
                const TssaField(
                  'reason',
                  'Lý do và căn cứ review',
                  kind: 'long',
                  required: true,
                ),
              ],
              transform: (values) => {
                ...values,
                'expectedRevision':
                    tssaItems(data)
                        .where((item) => item['id'] == values['accountId'])
                        .firstOrNull?['revision'] ??
                    0,
              },
            ),
            reload,
          ),
          child: const Text('Review / cấp scope / khóa'),
        ),
        for (final binding in tssaItems(data))
          TssaCard(
            title: binding['id'] as String,
            subtitle: '${binding['role']} · ${tssaStatus(binding['status'])}',
            children: [TssaPanel(binding)],
          ),
      ],
    ),
  );
}

class TssaModels extends StatelessWidget {
  const TssaModels({super.key});
  @override
  Widget build(BuildContext context) => TssaView(
    path: 'governance/models',
    builder: (data, reload) => TssaList(
      title: 'Model card và đường rollback',
      children: [
        const Text(
          'Không có số đo chất lượng được tạo giả. Model-assisted chỉ bật sau baseline, shadow và review vận hành.',
        ),
        FilledButton(
          onPressed: () => tssaOpenForm(
            context,
            TssaFormScreen(
              title: 'Ghi model card',
              path: 'governance/models',
              extra: {
                'expectedRevision':
                    tssaItems(data).firstOrNull?['revision'] ?? 0,
              },
              fields: const [
                TssaField(
                  'modelVersion',
                  'Model và revision chính xác',
                  required: true,
                ),
                TssaField('owner', 'Model owner', required: true),
                TssaField('modelCard', 'Tham chiếu model card', required: true),
                TssaField(
                  'testEvidence',
                  'Tham chiếu test cases / kết quả',
                  required: true,
                ),
                TssaField(
                  'rollbackPath',
                  'Cách rollback về baseline',
                  required: true,
                ),
                TssaField('incidentContact', 'Đầu mối sự cố', required: true),
                TssaField(
                  'providerReviewRef',
                  'Review provider / vùng xử lý / retention',
                  required: true,
                ),
                TssaField('privacyReviewRef', 'Review privacy', required: true),
                TssaField(
                  'fairnessReviewRef',
                  'Review fairness',
                  required: true,
                ),
                TssaField(
                  'providerReviewed',
                  'Provider đã được tổ chức review',
                  kind: 'bool',
                ),
                TssaField(
                  'status',
                  'Trạng thái',
                  kind: 'select',
                  required: true,
                  options: {
                    'PENDING_REVIEW': 'Chờ review',
                    'APPROVED': 'Đã được duyệt',
                  },
                ),
                TssaField(
                  'expiresAt',
                  'Hết hiệu lực phê duyệt',
                  kind: 'date',
                  required: true,
                ),
              ],
            ),
            reload,
          ),
          child: const Text('Ghi model card / phê duyệt có căn cứ'),
        ),
        for (final model in tssaItems(data))
          TssaCard(
            title: model['modelVersion'] as String,
            subtitle: tssaStatus(model['status']),
            children: [TssaPanel(model)],
          ),
      ],
    ),
  );
}

class TssaAudit extends StatelessWidget {
  const TssaAudit({super.key});
  @override
  Widget build(BuildContext context) => TssaView(
    path: 'governance/audit',
    builder: (data, reload) => TssaList(
      title: 'Audit không sửa event gốc',
      children: [
        for (final event in tssaItems(data))
          TssaCard(
            title: '${event['sequence']} · ${event['action']}',
            subtitle: tssaDate(event['timestamp']),
            children: [
              TssaPanel(event),
              TextButton(
                onPressed: () => tssaOpenForm(
                  context,
                  TssaFormScreen(
                    title: 'Thêm correction',
                    path: 'governance/audit/correction',
                    extra: {'eventId': event['id']},
                    fields: const [
                      TssaField(
                        'reasonCode',
                        'Mã lý do correction',
                        required: true,
                      ),
                    ],
                    explanation:
                        'Chỉ thêm event mới tham chiếu event gốc; không sửa/xóa dấu vết cũ.',
                  ),
                  reload,
                ),
                child: const Text('Thêm correction có tham chiếu'),
              ),
            ],
          ),
      ],
    ),
  );
}

class TssaMetrics extends StatelessWidget {
  const TssaMetrics({super.key});
  static const labels = {
    'coverage': 'Yêu cầu đã chạy lọc điều kiện',
    'eligibility': 'Có ứng viên đủ điều kiện',
    'noMatch': 'No-match',
    'override': 'Coordinator thay đổi / hỏi bổ sung',
    'familyAccept': 'Gia đình chấp nhận',
    'completedFirstSession': 'Hoàn tất buổi đầu',
    'rematch': 'Yêu cầu ghép lại',
    'response': 'Có phản hồi',
    'missingness': 'Yêu cầu thiếu dữ liệu',
  };
  @override
  Widget build(BuildContext context) => TssaView(
    path: 'governance/metrics',
    builder: (data, reload) => TssaList(
      title: 'Chất lượng dịch vụ',
      children: [
        Text(
          'Khoảng thời gian: ${tssaDate(data['start'])} – ${tssaDate(data['end'])}',
        ),
        Text('${data['caseCount']} yêu cầu · ${data['runCount']} run'),
        Text(
          '${data['pendingRuns']} run đang chờ/chạy. Các số dưới là phương án thực chạy; AI bị khóa/lỗi được tính baseline.',
        ),
        for (final entry in (data['modes'] as Map).entries)
          Text('${tssaStatus(entry.key)}: ${entry.value} run'),
        for (final entry in labels.entries)
          TssaCard(
            title: entry.value,
            children: [
              Text(
                '${data[entry.key]['numerator']} / ${data[entry.key]['denominator']}',
              ),
              Text(
                data[entry.key]['value'] == null
                    ? 'Chưa có mẫu để tính tỷ lệ'
                    : '${((data[entry.key]['value'] as num) * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
        TssaCard(
          title: 'Thời gian tới kết quả lọc để coordinator review',
          children: [
            Text(
              'Số mẫu: ${data['timeToShortlist']['sampleSize']}\nTrung vị: ${data['timeToShortlist']['medianMinutes'] ?? 'Chưa đo'} phút\np90: ${data['timeToShortlist']['p90Minutes'] ?? 'Chưa đo'} phút',
            ),
          ],
        ),
        Text('Sự cố trong phạm vi: ${data['incidents']}'),
        TssaCard(
          title: 'Nhóm lý do trong các quyết định override',
          children: [
            for (final entry in (data['overrideReasons'] as Map).entries)
              Text('${tssaStatus(entry.key)}: ${entry.value}'),
          ],
        ),
        TssaCard(
          title: 'Nhóm lý do các yêu cầu ghép lại',
          children: [
            for (final entry in (data['rematchReasons'] as Map).entries)
              Text('${tssaStatus(entry.key)}: ${entry.value}'),
          ],
        ),
        Text(
          'Gia đình chưa phản hồi: ${data['familyPending']} · từ chối: ${data['familyDecline']}',
        ),
        TssaCard(
          title: 'Công và chi phí điều phối đã ghi nhận',
          children: [
            Text(
              '${data['effort']['sampleSize']} hoạt động · ${data['effort']['totalMinutes']} phút',
            ),
            Text(
              'Độ phủ: ${data['effort']['caseCoverage']['numerator']} / ${data['effort']['caseCoverage']['denominator']} ca',
            ),
            Text(
              'Chi phí được khai báo: ${data['effort']['reportedCostVnd']} VND · ${data['effort']['costSampleSize']} hoạt động có chi phí',
            ),
          ],
        ),
        Text(
          'Phản hồi sự cố đầu tiên: ${data['incidentFirstResponse']['meanMinutes'] ?? 'Chưa đo'} phút · ${data['incidentFirstResponse']['sampleSize']} mẫu',
        ),
        for (final subgroup in data['subgroups'] as List)
          TssaCard(
            title: tssaFormats[subgroup['format']]!,
            children: [
              Text(
                '${subgroup['sampleSize']} ca có consent · ${subgroup['eligibility']['numerator']} / ${subgroup['eligibility']['denominator']} run có ứng viên',
              ),
            ],
          ),
        if (data['modelDisabledReason'] != null)
          Text('AI đang tắt: ${data['modelDisabledReason']}'),
        Text(data['subgroupSuppression'] as String),
        const Text(
          'Các số này mô tả vận hành. Không chứng minh hiệu quả học tập hoặc model đã được xác nhận phù hợp.',
        ),
      ],
    ),
  );
}
