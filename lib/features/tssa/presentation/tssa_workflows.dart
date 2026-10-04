import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/tssa_repository.dart';
import 'tssa_form.dart';
import 'tssa_profiles.dart';
import 'tssa_ui.dart';

class TssaRequests extends ConsumerWidget {
  const TssaRequests({required this.me, super.key});
  final TssaData me;
  Future<void> _create(
    BuildContext context,
    WidgetRef ref,
    VoidCallback reload,
  ) async {
    try {
      final learners = tssaItems(
        await ref.read(tssaRepositoryProvider).read('learners'),
      ).where((learner) => learner['canRequest'] != false).toList();
      if (!context.mounted) return;
      if (learners.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cần hồ sơ learner và liên kết còn quyền trước.'),
          ),
        );
        return;
      }
      final learnerId = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Chọn learner'),
          children: [
            for (final learner in learners)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, learner['id']),
                child: Text(
                  learner['displayName']?.toString() ?? learner['id'] as String,
                ),
              ),
          ],
        ),
      );
      if (learnerId == null) return;
      final selected = learners.firstWhere(
        (learner) => learner['id'] == learnerId,
      );
      final learner = selected['canProfile'] == false
          ? <String, dynamic>{'profile': <String, dynamic>{}}
          : await ref
                .read(tssaRepositoryProvider)
                .read('learners/$learnerId/profile');
      if (!context.mounted) return;
      await tssaOpenForm(
        context,
        TssaFormScreen(
          title: 'Yêu cầu tìm tutor',
          path: 'requests',
          owner: me['id'] as String,
          draftId: 'new-request-$learnerId',
          extra: {'learnerId': learnerId},
          initial: Map<String, dynamic>.from(learner['profile'] as Map),
          fields: learnerFields(),
          explanation:
              'Gửi yêu cầu cần môn, khối lớp, mục tiêu, hình thức, lịch và consent còn hiệu lực cho matching/coordinator. Tắt “giữ nháp” để gửi.',
          transform: (values) => {
            'draft': values.remove('draft'),
            'criteria': values
              ..remove('displayName')
              ..remove('communication'),
          },
        ),
        reload,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tssaError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => TssaView(
    path: 'requests',
    poll: true,
    builder: (data, reload) => TssaList(
      title: me['role'] == 'coordinator'
          ? 'Queue điều phối'
          : 'Yêu cầu tìm tutor',
      children: [
        if (['learner', 'guardian'].contains(me['role']))
          FilledButton.icon(
            onPressed: () => _create(context, ref, reload),
            icon: const Icon(Icons.add),
            label: const Text('Tạo yêu cầu'),
          ),
        if (tssaItems(data).isEmpty)
          const Text(
            'Chưa có yêu cầu trong phạm vi của bạn. Coordinator cần được admin cấp nhóm và thời hạn quyền.',
          ),
        for (final request in tssaItems(data))
          TssaCard(
            title:
                '${(request['criteria'] as Map?)?['subjects']?.join(', ') ?? 'Yêu cầu học'}',
            subtitle:
                '${tssaStatus(request['status'])}\nChờ ${request['ageHours']} giờ',
            onTap: () => tssaOpenPage(
              context,
              'Yêu cầu học',
              TssaRequestPage(me: me, requestId: request['id'] as String),
            ),
            children: [
              if (request['blockedReason'] != null)
                Text('Cần xử lý: ${request['blockedReason']}'),
              if (request['assignedTo'] != null)
                Text('Người phụ trách: ${request['assignedTo']}'),
            ],
          ),
      ],
    ),
  );
}

class TssaRequestPage extends StatelessWidget {
  const TssaRequestPage({required this.me, required this.requestId, super.key});
  final TssaData me;
  final String requestId;
  @override
  Widget build(BuildContext context) => TssaView(
    path: 'requests/$requestId',
    poll: true,
    builder: (request, reload) => TssaList(
      title: tssaStatus(request['status']),
      children: [
        TssaPanel(request),
        if (['learner', 'guardian'].contains(me['role']) &&
            ['DRAFT', 'SUBMITTED', 'NEEDS_INFO'].contains(request['status']))
          OutlinedButton(
            onPressed: () => tssaOpenForm(
              context,
              TssaFormScreen(
                title: 'Sửa / gửi lại yêu cầu',
                path: 'requests/$requestId',
                patch: true,
                owner: me['id'] as String,
                draftId: 'request-$requestId',
                initial: Map<String, dynamic>.from(request['criteria'] as Map),
                extra: {'expectedRevision': request['revision']},
                fields: learnerFields()
                    .where(
                      (field) =>
                          !['displayName', 'communication'].contains(field.key),
                    )
                    .toList(),
                transform: (values) => {
                  'draft': values.remove('draft'),
                  'criteria': values,
                },
              ),
              reload,
            ),
            child: const Text('Sửa yêu cầu trước review'),
          ),
        if (me['role'] == 'coordinator') ...[
          OutlinedButton(
            onPressed: () => tssaOpenForm(
              context,
              TssaFormScreen(
                title: 'Ghi nhận công điều phối thực tế',
                path: 'requests/$requestId/effort',
                fields: const [
                  TssaField(
                    'activity',
                    'Hoạt động',
                    kind: 'select',
                    required: true,
                    options: {
                      'INTAKE': 'Tiếp nhận',
                      'VERIFICATION': 'Xác minh',
                      'REVIEW': 'Review shortlist',
                      'SCHEDULE': 'Điều phối lịch',
                      'FOLLOW_UP': 'Theo dõi sau buổi',
                    },
                  ),
                  TssaField(
                    'minutes',
                    'Số phút thực tế',
                    kind: 'number',
                    required: true,
                  ),
                  TssaField(
                    'costVnd',
                    'Chi phí thực tế (VND, tùy chọn)',
                    kind: 'number',
                  ),
                ],
                explanation:
                    'Chỉ ghi hoạt động đã làm. Chỉ số dùng dữ liệu thực tế và công bố độ phủ; không dùng giả định chi phí của báo cáo làm kết quả.',
              ),
              reload,
            ),
            child: const Text('Ghi công điều phối'),
          ),
          if ([
            'SUBMITTED',
            'NEEDS_INFO',
            'COORDINATOR_REVIEW',
          ].contains(request['status']))
            FilledButton(
              onPressed: () => tssaOpenForm(
                context,
                TssaFormScreen(
                  title: 'Tìm shortlist có giải thích',
                  path: 'requests/$requestId/matches',
                  extra: {'expectedRevision': request['revision']},
                  fields: const [
                    TssaField(
                      'mode',
                      'Phương án',
                      kind: 'select',
                      required: true,
                      options: {
                        'RULE_BASELINE': 'Luật / cấu hình đã được review',
                        'MANUAL': 'Lọc điều kiện để coordinator chọn thủ công',
                      },
                      value: 'RULE_BASELINE',
                    ),
                  ],
                  explanation:
                      'Tutor phải active, verified, đúng môn/khối, hình thức, lịch và giới hạn ca. Không có ứng viên thì giữ no-match.',
                ),
                reload,
              ),
              child: const Text('Lọc tutor và tạo shortlist'),
            ),
          if (request['latestMatchId'] != null)
            TssaMatchReview(me: me, request: request),
          TssaView(
            path: 'requests/$requestId/decisions',
            builder: (data, _) => Column(
              children: [
                for (final decision in tssaItems(data))
                  TssaCard(
                    title: tssaStatus(decision['action']),
                    subtitle: tssaDate(decision['createdAt']),
                    children: [TssaPanel(decision)],
                  ),
              ],
            ),
          ),
        ],
        if (['learner', 'guardian'].contains(me['role']) &&
            request['status'] == 'WAITING_FAMILY') ...[
          if (request['candidatesNeedReview'] == true)
            const Text(
              'Có tutor không còn đáp ứng lịch hoặc xác minh. Danh sách đã ẩn phần không còn hợp lệ; bạn có thể đề nghị coordinator review lại.',
            ),
          const Text(
            'Các tutor dưới đây đã được coordinator duyệt. Bạn có thể chọn, từ chối hoặc đề nghị danh sách khác.',
          ),
          for (final candidate
              in ((request['approvedCandidates'] as List?) ?? []))
            TssaCard(
              title:
                  (candidate['publicProfile'] as Map)['displayName']
                      ?.toString() ??
                  'Tutor',
              subtitle: 'Đã được coordinator duyệt',
              children: [
                TssaPanel(
                  Map<String, dynamic>.from(candidate['publicProfile'] as Map),
                ),
                TssaPanel(Map<String, dynamic>.from(candidate as Map)),
                FilledButton(
                  onPressed: () => tssaOpenForm(
                    context,
                    TssaFormScreen(
                      title: 'Chọn tutor này',
                      path: 'requests/$requestId/choice',
                      extra: {
                        'expectedRevision': request['revision'],
                        'action': 'ACCEPT',
                        'tutorId': candidate['tutorId'],
                      },
                      fields: const [
                        TssaField(
                          'reason',
                          'Điều bạn muốn coordinator biết',
                          kind: 'long',
                        ),
                      ],
                      explanation:
                          'Cần consent cho tutor trước khi chọn. Booking chỉ được xác nhận sau khi tutor chấp nhận khung giờ.',
                    ),
                    reload,
                  ),
                  child: const Text('Chọn tutor'),
                ),
              ],
            ),
          OutlinedButton(
            onPressed: () => tssaOpenForm(
              context,
              TssaFormScreen(
                title: 'Phản hồi shortlist',
                path: 'requests/$requestId/choice',
                extra: {'expectedRevision': request['revision']},
                fields: const [
                  TssaField(
                    'action',
                    'Mong muốn của bạn',
                    kind: 'select',
                    required: true,
                    options: {
                      'DECLINE': 'Tôi chưa chọn các tutor này',
                      'ASK_QUESTION': 'Tôi có câu hỏi',
                      'REQUEST_ANOTHER': 'Đề nghị shortlist khác',
                      'CLOSE': 'Đóng yêu cầu',
                    },
                  ),
                  TssaField(
                    'reason',
                    'Câu hỏi / điều nên thay đổi',
                    kind: 'long',
                  ),
                ],
                explanation:
                    'Từ chối shortlist vẫn giữ quyền tiếp tục dịch vụ.',
              ),
              reload,
            ),
            child: const Text('Từ chối / hỏi / đề nghị tutor khác'),
          ),
        ],
        if (['learner', 'guardian'].contains(me['role']) &&
            request['status'] == 'WAITING_TUTOR')
          FilledButton(
            onPressed: () => tssaOpenForm(
              context,
              TssaFormScreen(
                title: 'Chọn giờ buổi học',
                path: 'bookings',
                extra: {
                  'requestId': requestId,
                  'requestRevision': request['revision'],
                },
                fields: [
                  const TssaField(
                    'start',
                    'Bắt đầu',
                    kind: 'date',
                    required: true,
                  ),
                  const TssaField(
                    'end',
                    'Kết thúc',
                    kind: 'date',
                    required: true,
                  ),
                  const TssaField(
                    'timezone',
                    'Múi giờ hiển thị',
                    kind: 'select',
                    required: true,
                    options: {
                      'Asia/Ho_Chi_Minh': 'Việt Nam (UTC+07:00)',
                      'UTC': 'UTC',
                    },
                    value: 'Asia/Ho_Chi_Minh',
                  ),
                  TssaField(
                    'format',
                    'Hình thức',
                    kind: 'select',
                    required: true,
                    options: {
                      for (final format
                          in (request['criteria'] as Map)['formats'] as List)
                        format as String: tssaFormats[format]!,
                    },
                  ),
                  const TssaField(
                    'location',
                    'Địa điểm / cách tham gia',
                    hint:
                        'Chỉ chia sẻ phần cần cho buổi học; thông báo ngoài app không chứa địa điểm.',
                  ),
                  const TssaField(
                    'policyAccepted',
                    'Tôi đã đọc chính sách thay đổi / hủy lịch',
                    kind: 'bool',
                  ),
                ],
                explanation: (me['policy'] as Map)['changePolicy'] as String,
              ),
              reload,
            ),
            child: const Text('Đề xuất khung giờ cho tutor'),
          ),
        if (request['status'] != 'CLOSED')
          TextButton(
            onPressed: () => tssaOpenForm(
              context,
              TssaFormScreen(
                title: 'Đóng yêu cầu',
                path: 'requests/$requestId/close',
                extra: {'expectedRevision': request['revision']},
                fields: const [
                  TssaField('reason', 'Lý do / ghi chú', kind: 'long'),
                ],
              ),
              reload,
            ),
            child: const Text('Đóng yêu cầu và giữ lịch sử'),
          ),
      ],
    ),
  );
}

class TssaMatchReview extends ConsumerWidget {
  const TssaMatchReview({required this.me, required this.request, super.key});
  final TssaData me, request;
  Future<void> _decision(
    BuildContext context,
    WidgetRef ref,
    TssaData run,
    VoidCallback reload,
  ) async {
    final candidates = ((run['candidates'] as List?) ?? [])
        .map((candidate) => Map<String, dynamic>.from(candidate as Map))
        .toList();
    final additional = tssaItems(
      await ref.read(tssaRepositoryProvider).read('tutors'),
    );
    if (!context.mounted) return;
    await tssaOpenForm(
      context,
      TssaFormScreen(
        title: 'Quyết định của coordinator',
        path: 'matches/${run['id']}/decision',
        extra: {
          'expectedRevision': run['revision'],
          'requestRevision': request['revision'],
        },
        fields: [
          const TssaField(
            'action',
            'Quyết định',
            kind: 'select',
            required: true,
            options: {
              'APPROVE': 'Duyệt để gia đình chọn',
              'REORDER': 'Đổi thứ tự / bổ sung thủ công',
              'REJECT': 'Từ chối shortlist',
              'REQUEST_INFO': 'Đề nghị bổ sung',
              'NO_MATCH': 'Ghi nhận chưa có match',
              'CLOSE': 'Đóng yêu cầu',
            },
          ),
          TssaField(
            'tutorIds',
            'Chọn tutor theo thứ tự giới thiệu',
            kind: 'ordered',
            options: {
              for (final candidate in candidates)
                candidate['tutorId'] as String:
                    (candidate['publicProfile'] as Map)['displayName']
                        as String,
              for (final tutor in additional)
                tutor['id'] as String:
                    (tutor['profile'] as Map)['displayName'] as String,
            },
          ),
          const TssaField(
            'reasonCategory',
            'Nhóm lý do quyết định',
            kind: 'select',
            required: true,
            value: 'OTHER',
            options: {
              'SAFETY': 'An toàn',
              'SCHEDULE': 'Lịch học',
              'ACADEMIC': 'Môn / mục tiêu học',
              'SCORE': 'Thay thứ tự gợi ý',
              'DATA': 'Thiếu / sửa dữ liệu',
              'OTHER': 'Khác',
            },
          ),
          const TssaField(
            'reason',
            'Căn cứ quyết định / override',
            kind: 'long',
            required: true,
          ),
        ],
        explanation:
            'Thứ tự chọn là thứ tự giới thiệu. Backend kiểm tra lại điều kiện và consent; không duyệt tutor chưa verified.',
      ),
      reload,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => TssaView(
    path: 'matches/${request['latestMatchId']}',
    poll: true,
    builder: (run, reload) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Shortlist: ${tssaStatus(run['status'])}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        TssaPanel(run),
        const Text(
          'Gợi ý cần coordinator review. Điểm hỗ trợ sắp xếp; không phải xác suất học thành công.',
        ),
        for (final candidate in ((run['candidates'] as List?) ?? []))
          TssaCard(
            title:
                (candidate['publicProfile'] as Map)['displayName']
                    ?.toString() ??
                'Tutor',
            children: [
              TssaPanel(Map<String, dynamic>.from(candidate as Map)),
              TssaPanel(
                Map<String, dynamic>.from(candidate['publicProfile'] as Map),
              ),
            ],
          ),
        if ((run['exclusions'] as List?)?.isNotEmpty == true)
          ExpansionTile(
            title: const Text('Ứng viên bị loại / dữ liệu cần bổ sung'),
            children: [
              for (final exclusion in run['exclusions'] as List)
                TssaPanel(Map<String, dynamic>.from(exclusion as Map)),
            ],
          ),
        if ([
          'COMPLETED',
          'NO_MATCH',
          'NEEDS_REVIEW',
          'FAILED',
        ].contains(run['status']))
          FilledButton(
            onPressed: () => _decision(context, ref, run, reload),
            child: const Text('Review / duyệt / yêu cầu bổ sung'),
          ),
      ],
    ),
  );
}

class TssaBookings extends StatelessWidget {
  const TssaBookings({
    required this.me,
    this.invitationsOnly = false,
    super.key,
  });
  final TssaData me;
  final bool invitationsOnly;
  @override
  Widget build(BuildContext context) => TssaView(
    path: 'bookings',
    builder: (data, reload) => TssaList(
      title: invitationsOnly ? 'Ca được mời' : 'Lịch và buổi học',
      children: [
        if (tssaItems(data).isEmpty)
          const Text('Chưa có booking được cấp quyền.'),
        for (final booking in tssaItems(data).where(
          (booking) => !invitationsOnly || booking['status'] == 'PENDING_TUTOR',
        ))
          TssaCard(
            title: booking['start'] == null
                ? 'Buổi học được cấp quyền'
                : tssaDate(booking['start']),
            subtitle: booking['start'] == null
                ? tssaStatus(booking['status'])
                : '${tssaStatus(booking['status'])} · ${tssaFormats[booking['format']] ?? ''}\nMúi giờ booking: ${booking['timezone']}',
            onTap: () => tssaOpenPage(
              context,
              'Buổi học',
              TssaBookingPage(me: me, bookingId: booking['id'] as String),
            ),
          ),
      ],
    ),
  );
}

class TssaBookingPage extends StatelessWidget {
  const TssaBookingPage({required this.me, required this.bookingId, super.key});
  final TssaData me;
  final String bookingId;
  @override
  Widget build(BuildContext context) => TssaView(
    path: 'bookings/$bookingId',
    builder: (booking, reload) => TssaList(
      title: 'Buổi học',
      children: [
        TssaPanel(booking),
        if (me['role'] == 'tutor' &&
            booking['canViewLearner'] == true &&
            booking['learnerId'] != null)
          OutlinedButton(
            onPressed: () => tssaOpenPage(
              context,
              'Hồ sơ được chia sẻ',
              TssaLearnerPage(
                me: me,
                learnerId: booking['learnerId'] as String,
              ),
            ),
            child: const Text('Mở phần hồ sơ còn consent'),
          ),
        if (booking['canSchedule'] != false &&
            ['PENDING_TUTOR', 'CONFIRMED'].contains(booking['status']) &&
            ['learner', 'guardian', 'tutor'].contains(me['role'])) ...[
          if (me['role'] == 'tutor' &&
              booking['status'] == 'PENDING_TUTOR' &&
              booking['familyAccepted'] == true)
            FilledButton(
              onPressed: () => tssaOpenForm(
                context,
                TssaFormScreen(
                  title: 'Xác nhận nhận buổi học',
                  path: 'bookings/$bookingId/respond',
                  extra: {
                    'action': 'ACCEPT',
                    'expectedRevision': booking['revision'],
                  },
                  fields: const [],
                  explanation:
                      'Xem múi giờ, hình thức, địa điểm và chính sách phía trên. Máy chủ kiểm tra lại lịch trùng và consent.',
                ),
                reload,
              ),
              child: const Text('Tôi đồng ý nhận khung giờ'),
            ),
          if (['learner', 'guardian'].contains(me['role']) &&
              booking['status'] == 'PENDING_TUTOR' &&
              booking['familyAccepted'] == false)
            FilledButton(
              onPressed: () => tssaOpenForm(
                context,
                TssaFormScreen(
                  title: 'Đồng ý giờ tutor đề xuất',
                  path: 'bookings/$bookingId/accept-change',
                  extra: {'expectedRevision': booking['revision']},
                  fields: const [],
                ),
                reload,
              ),
              child: const Text('Tôi đồng ý giờ mới'),
            ),
          OutlinedButton(
            onPressed: () => tssaOpenForm(
              context,
              TssaFormScreen(
                title: me['role'] == 'tutor'
                    ? 'Từ chối / rút khỏi ca'
                    : 'Hủy booking',
                path: 'bookings/$bookingId/respond',
                extra: {
                  'action': me['role'] == 'tutor' ? 'WITHDRAW' : 'CANCEL',
                  'expectedRevision': booking['revision'],
                },
                fields: const [
                  TssaField('reason', 'Lý do tùy chọn', kind: 'long'),
                ],
                explanation:
                    'Lịch sử được giữ lại. Coordinator sẽ điều phối lại; hệ thống không tự gán tutor mới.',
              ),
              reload,
            ),
            child: Text(
              me['role'] == 'tutor' ? 'Từ chối / rút khỏi ca' : 'Hủy booking',
            ),
          ),
          if (booking['status'] == 'CONFIRMED')
            OutlinedButton(
              onPressed: () => tssaOpenForm(
                context,
                TssaFormScreen(
                  title: 'Đề xuất đổi giờ',
                  path: 'bookings/$bookingId/reschedule',
                  extra: {'expectedRevision': booking['revision']},
                  fields: const [
                    TssaField(
                      'start',
                      'Bắt đầu mới',
                      kind: 'date',
                      required: true,
                    ),
                    TssaField(
                      'end',
                      'Kết thúc mới',
                      kind: 'date',
                      required: true,
                    ),
                  ],
                  explanation:
                      'Giờ mới cần nằm trong availability của hai bên. Gia đình và tutor phải xác nhận lại.',
                ),
                reload,
              ),
              child: const Text('Đề xuất đổi giờ'),
            ),
        ],
        if (me['role'] == 'tutor' &&
            ['CONFIRMED', 'COMPLETED', 'NOT_HELD'].contains(booking['status']))
          FilledButton(
            onPressed: () => tssaOpenForm(
              context,
              TssaFormScreen(
                title: 'Chuẩn bị / ghi nhận buổi học',
                path: 'bookings/$bookingId/notes',
                owner: me['id'] as String,
                draftId: 'note-$bookingId',
                extra: {'expectedRevision': booking['revision']},
                fields: const [
                  TssaField(
                    'agenda',
                    'Mục tiêu / hoạt động trước buổi',
                    kind: 'long',
                  ),
                  TssaField('summary', 'Ghi nhận học tập', kind: 'long'),
                  TssaField('adjustments', 'Điều chỉnh đã dùng', kind: 'long'),
                  TssaField('nextSteps', 'Bước tiếp theo', kind: 'long'),
                  TssaField(
                    'outcome',
                    'Kết quả buổi',
                    kind: 'select',
                    options: {
                      'AGENDA': 'Chỉ lưu chuẩn bị',
                      'COMPLETED': 'Buổi đã diễn ra',
                      'NOT_HELD': 'Buổi không diễn ra',
                    },
                    value: 'AGENDA',
                  ),
                  TssaField(
                    'reason',
                    'Lý do nếu buổi không diễn ra',
                    kind: 'long',
                  ),
                  TssaField(
                    'sharedWithFamily',
                    'Chia sẻ bản ghi này với gia đình',
                    kind: 'bool',
                  ),
                ],
                transform: (values) {
                  if (values['outcome'] == 'AGENDA') values.remove('outcome');
                  return values;
                },
                explanation:
                    'Ghi nội dung học, hoạt động và bước tiếp theo. Không cần chẩn đoán hoặc lời khuyên điều trị. App không ghi âm/video.',
              ),
              reload,
            ),
            child: const Text('Chuẩn bị / ghi nhận buổi học'),
          ),
        if (booking['canFeedback'] != false &&
            ['COMPLETED', 'NOT_HELD'].contains(booking['status']) &&
            ['learner', 'guardian', 'tutor'].contains(me['role']))
          FilledButton(
            onPressed: () => tssaOpenForm(
              context,
              TssaFormScreen(
                title: 'Phản hồi theo cách của bạn',
                path: 'bookings/$bookingId/feedback',
                fields: const [
                  TssaField(
                    'signal',
                    'Tôi cảm thấy',
                    kind: 'select',
                    options: {
                      'COMFORTABLE': '🙂 Thoải mái',
                      'UNSURE': '😐 Chưa biết',
                      'UNCOMFORTABLE': '🙁 Chưa thoải mái',
                      'SKIP': 'Tôi không muốn trả lời',
                    },
                  ),
                  TssaField('experience', 'Trải nghiệm của bạn', kind: 'long'),
                  TssaField('scheduleFit', 'Lịch có phù hợp không'),
                  TssaField('learningFit', 'Cách học có phù hợp không'),
                  TssaField('continueDoing', 'Điều nên tiếp tục', kind: 'long'),
                  TssaField('change', 'Điều nên thay đổi', kind: 'long'),
                  TssaField(
                    'shareWithFamily',
                    'Chia sẻ phản hồi này với gia đình',
                    kind: 'bool',
                  ),
                  TssaField(
                    'shareWithTutor',
                    'Chia sẻ phản hồi này với tutor',
                    kind: 'bool',
                  ),
                  TssaField(
                    'shareWithCoordinator',
                    'Chia sẻ phản hồi này với coordinator',
                    kind: 'bool',
                  ),
                ],
                explanation:
                    'Learner có thể chỉ chọn cảm nhận. Phản hồi được lưu riêng theo người gửi; guardian không trả lời thay mọi lựa chọn.',
              ),
              reload,
            ),
            child: const Text('Gửi phản hồi'),
          ),
        if (booking['canRequest'] != false &&
            ['learner', 'guardian'].contains(me['role']))
          OutlinedButton(
            onPressed: () => tssaOpenForm(
              context,
              TssaFormScreen(
                title: 'Đề nghị đổi tutor',
                path: 'bookings/$bookingId/rematch',
                fields: const [
                  TssaField(
                    'category',
                    'Nhóm lý do',
                    kind: 'select',
                    required: true,
                    options: {
                      'SUBJECT': 'Môn học',
                      'SCHEDULE': 'Lịch học',
                      'LEARNING_STYLE': 'Cách học',
                      'SAFETY': 'An toàn',
                      'OTHER': 'Khác',
                    },
                    value: 'OTHER',
                  ),
                  TssaField(
                    'reason',
                    'Điều cần coordinator xem lại',
                    kind: 'long',
                    required: true,
                  ),
                ],
                explanation:
                    'Tạo yêu cầu mới liên kết booking này và giữ nguyên lịch sử. Báo vấn đề không làm mất quyền đổi tutor.',
              ),
              reload,
            ),
            child: const Text('Yêu cầu ghép lại'),
          ),
        if (booking['canFeedback'] != false &&
            ['CONFIRMED', 'COMPLETED', 'NOT_HELD'].contains(booking['status']))
          TssaView(
            path: 'bookings/$bookingId/notes',
            builder: (notes, _) => Column(
              children: [
                for (final note in tssaItems(notes))
                  TssaCard(
                    title: 'Ghi nhận ${tssaDate(note['createdAt'])}',
                    children: [
                      TssaPanel(note),
                      if (me['role'] == 'tutor' && note['actor'] == me['id'])
                        TextButton(
                          onPressed: () => tssaOpenForm(
                            context,
                            TssaFormScreen(
                              title: 'Bổ sung phiên bản ghi nhận',
                              path: 'bookings/$bookingId/notes',
                              initial: note,
                              extra: {'supersedesId': note['id']},
                              fields: const [
                                TssaField(
                                  'agenda',
                                  'Chuẩn bị buổi',
                                  kind: 'long',
                                ),
                                TssaField(
                                  'summary',
                                  'Ghi nhận học tập',
                                  kind: 'long',
                                ),
                                TssaField(
                                  'adjustments',
                                  'Điều chỉnh đã dùng',
                                  kind: 'long',
                                ),
                                TssaField(
                                  'nextSteps',
                                  'Bước tiếp theo',
                                  kind: 'long',
                                ),
                                TssaField(
                                  'sharedWithFamily',
                                  'Chia sẻ bản này với gia đình',
                                  kind: 'bool',
                                ),
                              ],
                              explanation:
                                  'Lưu phiên bản bổ sung có tham chiếu. Bản gốc được giữ trong lịch sử.',
                            ),
                            reload,
                          ),
                          child: const Text('Bổ sung ghi nhận'),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        if (booking['canFeedback'] != false &&
            ['COMPLETED', 'NOT_HELD'].contains(booking['status']))
          TssaView(
            path: 'bookings/$bookingId/feedback',
            builder: (feedback, _) => Column(
              children: [
                for (final item in tssaItems(feedback))
                  TssaCard(
                    title: 'Phản hồi ${tssaDate(item['createdAt'])}',
                    children: [TssaPanel(item)],
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}
