import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/tssa_repository.dart';
import 'tssa_form.dart';
import 'tssa_ui.dart';

Map<String, String> tssaGroups(TssaData me) => {
  for (final group in ((me['policy'] as Map?)?['serviceGroups'] as List? ?? []))
    group['id'] as String: group['label'] as String,
};
Future<void> tssaOpenForm(
  BuildContext context,
  TssaFormScreen form,
  VoidCallback reload,
) async {
  final result = await Navigator.push<bool>(
    context,
    PageRouteBuilder<bool>(
      pageBuilder: (_, animation, secondaryAnimation) => form,
      transitionDuration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 200),
      reverseTransitionDuration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 200),
      transitionsBuilder: (_, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
  if (result == true) reload();
}

void tssaOpenPage(BuildContext context, String title, Widget child) =>
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        transitionDuration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 200),
        reverseTransitionDuration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 200),
        transitionsBuilder: (_, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        pageBuilder: (_, animation, secondaryAnimation) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: child,
        ),
      ),
    );
List<TssaField> learnerFields() => const [
  TssaField('displayName', 'Tên hiển thị'),
  TssaField(
    'grade',
    'Khối lớp',
    requiredWhenKey: 'draft',
    requiredWhenValue: false,
  ),
  TssaField(
    'subjects',
    'Môn học',
    kind: 'list',
    requiredWhenKey: 'draft',
    requiredWhenValue: false,
    hint: 'Ngăn cách các môn bằng dấu phẩy.',
  ),
  TssaField(
    'goals',
    'Mục tiêu học',
    kind: 'long',
    requiredWhenKey: 'draft',
    requiredWhenValue: false,
  ),
  TssaField(
    'formats',
    'Hình thức',
    kind: 'multi',
    options: tssaFormats,
    requiredWhenKey: 'draft',
    requiredWhenValue: false,
  ),
  TssaField(
    'availability',
    'Lịch có thể học',
    kind: 'windows',
    requiredWhenKey: 'draft',
    requiredWhenValue: false,
  ),
  TssaField(
    'area',
    'Địa bàn',
    hint: 'Chỉ cần quận/tỉnh hoặc vùng phục vụ; không nhập địa chỉ nhà.',
  ),
  TssaField('language', 'Ngôn ngữ'),
  TssaField('communication', 'Cách giao tiếp tự chọn', kind: 'long'),
  TssaField(
    'supports',
    'Điều chỉnh mong muốn',
    kind: 'list',
    hint: 'Tự chọn; không cần chẩn đoán.',
  ),
  TssaField(
    'budget',
    'Ngân sách tự chọn',
    hint:
        'Khoảng ngân sách hoặc cơ chế tài trợ để coordinator trao đổi; không dùng xếp hạng tự động.',
  ),
  TssaField('draft', 'Giữ hồ sơ ở trạng thái nháp', kind: 'bool', value: true),
];

class TssaProfilesHub extends ConsumerWidget {
  const TssaProfilesHub({required this.me, super.key});
  final TssaData me;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = me['role'];
    if (role == 'tutor') return TssaTutors(me: me);
    if (role == 'unassigned') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn vai trò trong dịch vụ hỗ trợ học tập. Tutor cần được xác minh trước khi vào danh sách ứng viên.',
              ),
              FilledButton(
                onPressed: () => tssaOpenForm(
                  context,
                  const TssaFormScreen(
                    title: 'Bắt đầu với TSSA',
                    path: 'onboarding',
                    fields: [
                      TssaField(
                        'role',
                        'Vai trò của bạn',
                        kind: 'select',
                        required: true,
                        options: {
                          'learner': 'Người học',
                          'guardian': 'Phụ huynh / người giám hộ',
                          'tutor': 'Tutor',
                        },
                      ),
                    ],
                  ),
                  () => ref.invalidate(tssaIdentityProvider),
                ),
                child: const Text('Chọn vai trò'),
              ),
            ],
          ),
        ),
      );
    }
    return TssaView(
      path: 'learners',
      builder: (data, reload) => TssaList(
        title: 'Hồ sơ học',
        children: [
          const Text(
            'Bắt đầu từ mục tiêu học và lịch. Không cần cung cấp chẩn đoán lâm sàng.',
          ),
          const SizedBox(height: 16),
          if (['learner', 'guardian'].contains(role))
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Tạo hồ sơ học'),
              onPressed: () => tssaOpenForm(
                context,
                TssaFormScreen(
                  title: role == 'guardian'
                      ? 'Tạo yêu cầu liên kết learner'
                      : 'Hồ sơ học của bạn',
                  path: 'learners',
                  owner: me['id'] as String,
                  draftId: 'new-learner',
                  explanation: role == 'guardian'
                      ? 'Coordinator cần xác minh bằng chứng quan hệ đại diện. Bạn chỉ sửa hồ sơ sau khi liên kết được duyệt.'
                      : 'Môn, khối lớp, mục tiêu, hình thức và lịch cần đầy đủ trước khi gửi yêu cầu ghép.',
                  fields: [
                    TssaField(
                      'groupId',
                      'Nhóm dịch vụ',
                      kind: 'select',
                      required: true,
                      options: tssaGroups(me),
                    ),
                    if (role == 'guardian')
                      const TssaField(
                        'evidenceRef',
                        'Mã / tham chiếu bằng chứng quan hệ',
                        required: true,
                      )
                    else
                      ...learnerFields(),
                  ],
                  transform: (values) => {
                    'groupId': values.remove('groupId'),
                    if (role == 'guardian')
                      'evidenceRef': values['evidenceRef']
                    else ...{
                      'draft': values.remove('draft'),
                      'profile': values,
                    },
                  },
                ),
                reload,
              ),
            ),
          if (tssaItems(data).isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Chưa có hồ sơ được cấp quyền. Guardian có thể theo dõi yêu cầu liên kết bên dưới.',
              ),
            ),
          for (final learner in tssaItems(data))
            TssaCard(
              title:
                  learner['displayName']?.toString() ?? learner['id'] as String,
              subtitle: tssaStatus(learner['status']),
              onTap: () => tssaOpenPage(
                context,
                'Hồ sơ học',
                learner['canProfile'] != false
                    ? TssaLearnerPage(
                        me: me,
                        learnerId: learner['id'] as String,
                      )
                    : learner['canConsent'] == true
                    ? TssaConsentPage(
                        me: me,
                        learnerId: learner['id'] as String,
                      )
                    : const TssaList(
                        title: 'Quyền theo mục đích',
                        children: [
                          Text(
                            'Bạn có quyền lịch, feedback hoặc yêu cầu ghép. Mở tab Lịch hoặc Yêu cầu để dùng phần đã được cấp.',
                          ),
                        ],
                      ),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Guardian–learner',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TssaLinks(me: me),
        ],
      ),
    );
  }
}

class TssaLearnerPage extends StatelessWidget {
  const TssaLearnerPage({required this.me, required this.learnerId, super.key});
  final TssaData me;
  final String learnerId;
  @override
  Widget build(BuildContext context) => TssaView(
    path: 'learners/$learnerId/profile',
    builder: (data, reload) => TssaList(
      title: 'Mục tiêu và cách học',
      children: [
        TssaPanel(data),
        if (['learner', 'guardian'].contains(me['role'])) ...[
          FilledButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Sửa hồ sơ học'),
            onPressed: () => tssaOpenForm(
              context,
              TssaFormScreen(
                title: 'Sửa hồ sơ học',
                path: 'learners/$learnerId/profile',
                patch: true,
                owner: me['id'] as String,
                draftId: 'profile-$learnerId',
                fields: learnerFields(),
                initial: {
                  ...Map<String, dynamic>.from(data['profile'] as Map),
                  'draft': data['status'] == 'DRAFT',
                },
                extra: {'expectedRevision': data['revision']},
                explanation:
                    'Thay đổi được ghi vào lịch sử. Trường mới không tự thêm vào consent đã cấp.',
                transform: (values) => {
                  'draft': values.remove('draft'),
                  'profile': values,
                },
              ),
              reload,
            ),
          ),
          if (data['canConsent'] != false)
            OutlinedButton(
              onPressed: () => tssaOpenPage(
                context,
                'Consent và bản xem trước',
                TssaConsentPage(me: me, learnerId: learnerId),
              ),
              child: const Text('Consent và bản xem trước chia sẻ'),
            ),
          if (data['canConsent'] != false)
            OutlinedButton(
              onPressed: () => tssaOpenPage(
                context,
                'Quyền riêng tư',
                TssaPrivacyPage(me: me, learnerId: learnerId),
              ),
              child: const Text('Ai đã xem và quyền dữ liệu'),
            ),
        ],
      ],
    ),
  );
}

class TssaLinks extends StatelessWidget {
  const TssaLinks({required this.me, super.key});
  final TssaData me;
  @override
  Widget build(BuildContext context) => TssaView(
    path: 'guardian-links',
    builder: (data, reload) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (me['role'] == 'guardian')
          OutlinedButton(
            onPressed: () => tssaOpenForm(
              context,
              TssaFormScreen(
                title: 'Yêu cầu liên kết',
                path: 'guardian-links',
                fields: const [
                  TssaField(
                    'learnerId',
                    'Mã learner do tổ chức cung cấp',
                    required: true,
                  ),
                  TssaField(
                    'evidenceRef',
                    'Tham chiếu bằng chứng đại diện',
                    required: true,
                  ),
                ],
                explanation:
                    'Không liên kết tự động theo tên hoặc email giống nhau. Coordinator sẽ kiểm tra.',
              ),
              reload,
            ),
            child: const Text('Liên kết learner hiện có'),
          ),
        for (final link in tssaItems(data))
          TssaCard(
            title: 'Liên kết ${link['learnerId']}',
            subtitle: tssaStatus(link['status']),
            children: [
              TssaPanel(link),
              if (me['role'] == 'coordinator')
                OutlinedButton(
                  onPressed: () => tssaOpenForm(
                    context,
                    TssaFormScreen(
                      title: 'Xác minh quan hệ đại diện',
                      path: 'guardian-links/${link['id']}',
                      patch: true,
                      extra: {'expectedRevision': link['revision']},
                      fields: const [
                        TssaField(
                          'status',
                          'Kết quả',
                          kind: 'select',
                          required: true,
                          options: {
                            'VERIFIED': 'Đã kiểm tra và duyệt',
                            'REJECTED': 'Không được duyệt',
                          },
                        ),
                        TssaField(
                          'purposes',
                          'Quyền được cấp',
                          kind: 'multi',
                          options: {
                            'profile': 'Hồ sơ học',
                            'schedule': 'Lịch',
                            'feedback': 'Feedback',
                            'requests': 'Yêu cầu ghép',
                            'consent': 'Quản lý consent',
                          },
                        ),
                        TssaField(
                          'expiresAt',
                          'Hết hiệu lực',
                          kind: 'date',
                          requiredWhenKey: 'status',
                          requiredWhenValue: 'VERIFIED',
                        ),
                        TssaField(
                          'learnerParticipation',
                          'Ghi nhận ý kiến / cách tham gia của learner',
                          kind: 'long',
                          required: true,
                        ),
                        TssaField(
                          'learnerAccountId',
                          'Email tài khoản learner đã được tổ chức xác minh (tùy chọn)',
                          hint:
                              'Gắn tài khoản để learner tự xem consent và gửi phản hồi. Không suy ra quan hệ bằng email giống nhau.',
                        ),
                        TssaField(
                          'reason',
                          'Căn cứ review',
                          kind: 'long',
                          required: true,
                        ),
                      ],
                    ),
                    reload,
                  ),
                  child: const Text('Review và cấp quyền theo mục đích'),
                ),
              if (['learner', 'guardian'].contains(me['role']))
                OutlinedButton(
                  onPressed: () => tssaOpenForm(
                    context,
                    TssaFormScreen(
                      title: 'Thay đổi chia sẻ',
                      path: 'guardian-links/${link['id']}',
                      patch: true,
                      extra: {'expectedRevision': link['revision']},
                      fields: const [
                        TssaField(
                          'action',
                          'Mong muốn của bạn',
                          kind: 'select',
                          required: true,
                          options: {
                            'OBJECT': 'Tôi không muốn chia sẻ',
                            'DISPUTE': 'Có tranh chấp / cần đổi người đại diện',
                            'REVOKE': 'Thu hồi liên kết',
                          },
                        ),
                        TssaField(
                          'reason',
                          'Điều cần coordinator biết',
                          kind: 'long',
                        ),
                      ],
                    ),
                    reload,
                  ),
                  child: const Text('Không muốn chia sẻ / đề nghị xem lại'),
                ),
            ],
          ),
      ],
    ),
  );
}

class TssaConsentPage extends StatelessWidget {
  const TssaConsentPage({required this.me, required this.learnerId, super.key});
  final TssaData me;
  final String learnerId;
  @override
  Widget build(BuildContext context) => TssaView(
    path: 'consents',
    builder: (data, reload) => TssaList(
      title: 'Consent theo mục đích',
      children: [
        Text(
          (me['policy'] as Map?)?['consentText']?.toString().isNotEmpty == true
              ? (me['policy'] as Map)['consentText'] as String
              : 'Tổ chức chưa công bố nội dung consent. Liên hệ coordinator để chốt trước pilot.',
        ),
        const Text(
          'Bạn chọn từng mục đích, trường dữ liệu và thời hạn. Thu hồi sẽ chặn chia sẻ mới và hủy run đang chờ.',
        ),
        FilledButton(
          onPressed: () => tssaOpenForm(
            context,
            TssaFormScreen(
              title: 'Chọn phần bạn đồng ý chia sẻ',
              path: 'consents',
              extra: {'learnerId': learnerId},
              fields: const [
                TssaField(
                  'purpose',
                  'Mục đích',
                  kind: 'select',
                  required: true,
                  options: tssaPurposes,
                ),
                TssaField(
                  'fields',
                  'Trường được chia sẻ',
                  kind: 'multi',
                  required: true,
                  options: tssaFields,
                ),
                TssaField(
                  'expiresAt',
                  'Thời hạn',
                  kind: 'date',
                  required: true,
                ),
                TssaField(
                  'explanationAccepted',
                  'Tôi đã đọc mục đích, người nhận và có thể thu hồi',
                  kind: 'bool',
                ),
              ],
            ),
            reload,
          ),
          child: const Text('Cấp consent'),
        ),
        for (final grant in tssaItems(
          data,
        ).where((grant) => grant['learnerId'] == learnerId))
          TssaCard(
            title: tssaPurposes[grant['purpose']] ?? grant['purpose'] as String,
            subtitle:
                DateTime.tryParse(
                          grant['expiresAt']?.toString() ?? '',
                        )?.isBefore(DateTime.now()) ==
                        true &&
                    grant['status'] == 'ACTIVE'
                ? 'Hết hạn'
                : tssaStatus(grant['status']),
            children: [
              TssaPanel(grant),
              if (grant['status'] == 'ACTIVE')
                OutlinedButton(
                  onPressed: () => tssaOpenForm(
                    context,
                    TssaFormScreen(
                      title: 'Thu hồi consent',
                      path: 'consents/${grant['id']}',
                      patch: true,
                      extra: {'expectedRevision': grant['revision']},
                      fields: const [],
                    ),
                    reload,
                  ),
                  child: const Text('Thu hồi consent'),
                ),
            ],
          ),
        const SizedBox(height: 16),
        TssaView(
          path: 'learners/$learnerId/sharing',
          builder: (preview, _) => Column(
            children: [
              const Text('Bản xem trước ở từng giai đoạn'),
              for (final row in tssaItems(preview))
                TssaCard(
                  title: tssaPurposes[row['purpose']] ?? '',
                  children: [TssaPanel(row)],
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class TssaTutors extends StatelessWidget {
  const TssaTutors({required this.me, super.key});
  final TssaData me;
  void _edit(
    BuildContext context,
    TssaData? tutor,
    VoidCallback reload,
  ) => tssaOpenForm(
    context,
    TssaFormScreen(
      title: 'Hồ sơ tutor',
      path: tutor == null
          ? 'tutors'
          : 'tutors/${Uri.encodeComponent(tutor['id'] as String)}',
      patch: tutor != null,
      owner: me['id'] as String,
      draftId: 'tutor-profile',
      initial: {
        ...?tutor?['profile'] as Map<String, dynamic>?,
        'groupId': tutor?['groupId'],
        'evidenceRef': tutor?['evidenceRef'],
        'active': tutor?['active'] ?? true,
      },
      extra: {'expectedRevision': tutor?['revision'] ?? 0},
      explanation:
          'Kinh nghiệm là thông tin bạn khai báo. Minh chứng chỉ dành cho coordinator xác minh. Chỉ tutor active và verified còn hạn được giới thiệu.',
      fields: [
        TssaField(
          'groupId',
          'Nhóm dịch vụ',
          kind: 'select',
          required: true,
          options: tssaGroups(me),
        ),
        const TssaField('displayName', 'Tên được giới thiệu', required: true),
        const TssaField('subjects', 'Môn dạy', kind: 'list', required: true),
        const TssaField('grades', 'Khối lớp', kind: 'list', required: true),
        const TssaField(
          'formats',
          'Hình thức',
          kind: 'multi',
          required: true,
          options: tssaFormats,
        ),
        const TssaField(
          'availability',
          'Lịch nhận ca',
          kind: 'windows',
          required: true,
        ),
        const TssaField('area', 'Địa bàn khi dạy trực tiếp'),
        const TssaField('language', 'Ngôn ngữ'),
        const TssaField('experience', 'Kinh nghiệm khai báo', kind: 'long'),
        const TssaField('teachingApproach', 'Cách dạy tự mô tả', kind: 'long'),
        const TssaField(
          'supports',
          'Điều chỉnh bạn có thể cung cấp',
          kind: 'list',
        ),
        const TssaField(
          'capacity',
          'Số ca tối đa đang hoạt động',
          kind: 'number',
          required: true,
          value: 1,
        ),
        const TssaField(
          'evidenceRef',
          'Mã / tham chiếu minh chứng',
          required: true,
        ),
        const TssaField('active', 'Đang nhận ca', kind: 'bool', value: true),
      ],
      transform: (values) => {
        'groupId': values.remove('groupId'),
        'evidenceRef': values.remove('evidenceRef'),
        'active': values.remove('active'),
        'profile': values,
      },
    ),
    reload,
  );
  @override
  Widget build(BuildContext context) => TssaView(
    path: 'tutors',
    builder: (data, reload) => TssaList(
      title: me['role'] == 'tutor' ? 'Hồ sơ và lịch nhận ca' : 'Xác minh tutor',
      children: [
        if (me['role'] == 'tutor' && tssaItems(data).isEmpty)
          FilledButton(
            onPressed: () => _edit(context, null, reload),
            child: const Text('Tạo hồ sơ tutor'),
          ),
        for (final tutor in tssaItems(data))
          TssaCard(
            title:
                (tutor['profile'] as Map)['displayName']?.toString() ?? 'Tutor',
            subtitle: tssaStatus((tutor['verification'] as Map)['status']),
            children: [
              TssaPanel(tutor),
              if (me['role'] == 'tutor')
                OutlinedButton(
                  onPressed: () => _edit(context, tutor, reload),
                  child: const Text('Sửa lịch / tạm dừng hồ sơ'),
                ),
              if (me['role'] == 'coordinator')
                OutlinedButton(
                  onPressed: () => tssaOpenForm(
                    context,
                    TssaFormScreen(
                      title: 'Review xác minh tutor',
                      path:
                          'tutors/${Uri.encodeComponent(tutor['id'] as String)}/verification',
                      patch: true,
                      extra: {'expectedRevision': tutor['revision']},
                      fields: const [
                        TssaField(
                          'status',
                          'Kết quả',
                          kind: 'select',
                          required: true,
                          options: {
                            'VERIFIED': 'Verified',
                            'REJECTED': 'Không được duyệt',
                            'EXPIRED': 'Hết hạn / cần review lại',
                          },
                        ),
                        TssaField(
                          'expiresAt',
                          'Hết hạn xác minh',
                          kind: 'date',
                          requiredWhenKey: 'status',
                          requiredWhenValue: 'VERIFIED',
                        ),
                        TssaField(
                          'evidenceRef',
                          'Tham chiếu kiểm tra theo tiêu chí tổ chức',
                          required: true,
                        ),
                        TssaField(
                          'reason',
                          'Căn cứ xác minh',
                          kind: 'long',
                          required: true,
                        ),
                      ],
                    ),
                    reload,
                  ),
                  child: const Text('Review minh chứng và tiêu chí'),
                ),
            ],
          ),
        if (me['role'] == 'coordinator') ...[
          const Text('Liên kết guardian cần review'),
          TssaLinks(me: me),
        ],
      ],
    ),
  );
}

class TssaPrivacyPage extends StatelessWidget {
  const TssaPrivacyPage({required this.me, required this.learnerId, super.key});
  final TssaData me;
  final String learnerId;
  @override
  Widget build(BuildContext context) => TssaView(
    path: 'privacy/$learnerId',
    builder: (data, reload) => TssaList(
      title: 'Dữ liệu và quyền của bạn',
      children: [
        TssaPanel(data),
        FilledButton(
          onPressed: () => tssaOpenForm(
            context,
            TssaFormScreen(
              title: 'Yêu cầu quyền dữ liệu',
              path: 'privacy/requests',
              extra: {'learnerId': learnerId},
              fields: const [
                TssaField(
                  'type',
                  'Yêu cầu',
                  kind: 'select',
                  required: true,
                  options: {
                    'EXPORT': 'Nhận bản sao dữ liệu',
                    'DELETE': 'Yêu cầu xóa dữ liệu',
                  },
                ),
                TssaField(
                  'reason',
                  'Phạm vi / điều muốn người xử lý biết',
                  kind: 'long',
                ),
              ],
              explanation:
                  'Người xử lý sẽ xác nhận phạm vi, thời hạn và ngoại lệ. Yêu cầu xóa không tự xóa audit bắt buộc giữ.',
            ),
            reload,
          ),
          child: const Text('Yêu cầu export / delete'),
        ),
        TssaView(
          path: 'privacy/requests',
          builder: (requests, _) => Column(
            children: [
              for (final item in tssaItems(
                requests,
              ).where((item) => item['learnerId'] == learnerId))
                TssaCard(
                  title: item['type'] as String,
                  subtitle: tssaStatus(item['status']),
                  children: [TssaPanel(item)],
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
