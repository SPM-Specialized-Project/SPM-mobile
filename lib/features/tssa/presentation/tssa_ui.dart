import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/tssa_repository.dart';
import 'tssa_form.dart';

const tssaFormats = {'ONLINE': 'Trực tuyến', 'IN_PERSON': 'Trực tiếp'};
const tssaPurposes = {
  'coordinator': 'Coordinator điều phối',
  'tutor': 'Tutor chuẩn bị buổi học',
  'matching': 'Lọc và xếp hạng tutor',
  'notifications': 'Thông báo',
  'analytics': 'Nghiên cứu / phân tích',
};
const tssaFields = {
  'displayName': 'Tên hiển thị',
  'grade': 'Khối lớp',
  'subjects': 'Môn học',
  'goals': 'Mục tiêu học',
  'formats': 'Hình thức',
  'availability': 'Lịch rảnh',
  'area': 'Địa bàn',
  'language': 'Ngôn ngữ',
  'communication': 'Cách giao tiếp',
  'supports': 'Điều chỉnh tự chọn',
  'budget': 'Ngân sách tự chọn',
};
const tssaStatuses = {
  'DRAFT': 'Nháp',
  'SUBMITTED': 'Đã gửi',
  'NEEDS_INFO': 'Chờ bổ sung',
  'MATCHING': 'Đang tìm tutor',
  'COORDINATOR_REVIEW': 'Coordinator đang xem',
  'WAITING_FAMILY': 'Chờ gia đình chọn',
  'WAITING_TUTOR': 'Chờ tutor xác nhận',
  'BOOKED': 'Đã đặt lịch',
  'CLOSED': 'Đã đóng',
  'PENDING': 'Chờ xác minh',
  'VERIFIED': 'Đã xác minh',
  'REJECTED': 'Không được duyệt',
  'EXPIRED': 'Hết hạn',
  'ACTIVE': 'Còn hiệu lực',
  'PENDING_TUTOR': 'Chờ tutor xác nhận',
  'CONFIRMED': 'Đã xác nhận',
  'COMPLETED': 'Đã hoàn tất',
  'NOT_HELD': 'Buổi không diễn ra',
  'CANCELLED': 'Đã hủy',
  'REVOKED': 'Đã thu hồi',
  'SUPERSEDED': 'Đã có consent mới',
  'OBJECTED': 'Learner không muốn chia sẻ',
  'DISPUTED': 'Chờ xử lý tranh chấp',
  'QUEUED': 'Đang chờ xử lý',
  'RUNNING': 'Đang xử lý',
  'NO_MATCH': 'Chưa có ứng viên phù hợp',
  'NEEDS_REVIEW': 'Cần xem dữ liệu thiếu',
  'FAILED': 'Có lỗi · dùng baseline/thủ công',
  'RECEIVED': 'Đã tiếp nhận',
  'UNASSIGNED': 'Chưa có người xử lý',
  'IN_REVIEW': 'Đang xem xét',
  'WAITING_INFO': 'Chờ bổ sung',
  'RESOLVED': 'Đã xử lý',
  'DENIED': 'Không được duyệt',
  'PENDING_REVIEW': 'Chờ tổ chức review',
  'APPROVED': 'Đã được duyệt',
  'REDACTED': 'Đã loại dữ liệu hồ sơ',
  'MANUAL': 'Thủ công',
  'RULE_BASELINE': 'Luật và bảng điểm',
  'SHADOW': 'AI shadow · không đổi thứ tự giới thiệu',
  'MODEL_ASSISTED': 'Gợi ý AI · coordinator quyết định',
  'SAFETY': 'An toàn',
  'QUALITY': 'Chất lượng học',
  'PRIVACY': 'Riêng tư',
  'SCHEDULE': 'Lịch học',
  'ACADEMIC': 'Môn / mục tiêu học',
  'SCORE': 'Thứ tự gợi ý',
  'DATA': 'Dữ liệu',
  'OTHER': 'Khác',
  'SUBJECT': 'Môn học',
  'LEARNING_STYLE': 'Cách học',
  'RESTRICTED': 'Người xử lý và privacy role',
  'HANDLER_ONLY': 'Người xử lý được phân công',
  'NORMAL': 'Hỗ trợ vận hành',
  'URGENT': 'Cần tổ chức hỗ trợ khẩn',
  'VERIFIED_TUTOR': 'Tutor đã được xác minh',
  'SUBJECT_MATCH': 'Đúng môn học',
  'GRADE_MATCH': 'Đúng khối lớp',
  'SCHEDULE_OVERLAP': 'Có lịch rảnh chung',
  'FORMAT_MATCH': 'Có hình thức học chung',
  'TUTOR_PAUSED': 'Tutor đang tạm dừng nhận ca',
  'VERIFICATION_REQUIRED': 'Cần xác minh còn hiệu lực',
  'ACCOUNT_UNAVAILABLE': 'Tài khoản chưa có quyền hoạt động',
  'OUTSIDE_SERVICE_GROUP': 'Ngoài nhóm dịch vụ',
  'SUBJECT_MISMATCH': 'Chưa đáp ứng môn cần học',
  'GRADE_MISMATCH': 'Chưa đáp ứng khối lớp',
  'FORMAT_OR_AREA_MISMATCH': 'Hình thức hoặc địa bàn chưa phù hợp',
  'SCHEDULE_MISMATCH': 'Chưa có khung giờ chung',
  'CAPACITY_REACHED': 'Đã đạt giới hạn ca',
  'LANGUAGE_MISMATCH': 'Ngôn ngữ chưa phù hợp',
  'REQUESTED_SUPPORT_UNAVAILABLE': 'Chưa khai báo điều chỉnh được yêu cầu',
  'MANUAL_OVERRIDE_VERIFIED': 'Coordinator thêm tutor đã kiểm tra điều kiện',
  'GOALS_NOT_SHARED': 'Mục tiêu chưa được chia sẻ cho matching',
  'APPROVE': 'Duyệt shortlist',
  'REORDER': 'Duyệt thứ tự đã điều chỉnh',
  'REJECT': 'Không duyệt',
  'REQUEST_INFO': 'Yêu cầu bổ sung',
  'CLOSE': 'Đóng case',
  'ACCEPT': 'Đồng ý',
  'DECLINE': 'Từ chối',
  'ASK_QUESTION': 'Hỏi thêm',
  'REQUEST_ANOTHER': 'Đề nghị shortlist khác',
};
String tssaStatus(dynamic value) =>
    tssaStatuses[value] ?? value?.toString() ?? '';

class TssaView extends ConsumerStatefulWidget {
  const TssaView({
    required this.path,
    required this.builder,
    this.poll = false,
    super.key,
  });
  final String path;
  final Widget Function(TssaData data, VoidCallback reload) builder;
  final bool poll;
  @override
  ConsumerState<TssaView> createState() => _TssaViewState();
}

class _TssaViewState extends ConsumerState<TssaView>
    with WidgetsBindingObserver {
  Future<TssaData>? _future;
  TssaRepository? _repository;
  Timer? _poll;
  bool _active = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _schedule();
  }

  void _schedule() {
    _poll?.cancel();
    _poll = Timer.periodic(Duration(seconds: widget.poll ? 5 : 30), (_) {
      if (mounted) _reload();
    });
  }

  @override
  void didUpdateWidget(covariant TssaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _future = null;
    if (oldWidget.poll != widget.poll) _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    _poll?.cancel();
    setState(() {
      _active = state == AppLifecycleState.resumed;
      _future = null;
    });
    if (_active) _schedule();
  }

  void _reload() {
    setState(() => _future = null);
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) return const SizedBox.shrink();
    final repository = ref.watch(tssaRepositoryProvider);
    if (!identical(repository, _repository)) {
      _repository = repository;
      _future = null;
    }
    _future ??= repository.read(widget.path);
    return FutureBuilder<TssaData>(
      key: ValueKey('${widget.path}:${identityHashCode(repository)}'),
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined),
                const SizedBox(height: 12),
                Text(tssaError(snapshot.error!), textAlign: TextAlign.center),
                TextButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tải lại'),
                ),
              ],
            ),
          );
        }
        return widget.builder(snapshot.data!, _reload);
      },
    );
  }
}

class TssaList extends StatelessWidget {
  const TssaList({required this.title, required this.children, super.key});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      ...children,
      const SizedBox(height: 24),
    ],
  );
}

class TssaCard extends StatelessWidget {
  const TssaCard({
    required this.title,
    this.subtitle,
    this.onTap,
    this.children = const [],
    super.key,
  });
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: subtitle == null ? null : Text(subtitle!),
            onTap: onTap,
            trailing: onTap == null ? null : const Icon(Icons.chevron_right),
          ),
          ...children,
        ],
      ),
    ),
  );
}

class TssaPanel extends StatelessWidget {
  const TssaPanel(this.data, {super.key});
  final TssaData data;
  static const labels = {
    ...tssaFields,
    'status': 'Trạng thái',
    'grades': 'Các khối lớp',
    'teachingApproach': 'Cách dạy tự mô tả',
    'capacity': 'Giới hạn ca',
    'active': 'Đang nhận ca',
    'verification': 'Xác minh',
    'verificationStatus': 'Xác minh',
    'verificationExpiresAt': 'Hết hạn xác minh',
    'evidenceRef': 'Tham chiếu bằng chứng',
    'criteria': 'Yêu cầu học',
    'start': 'Bắt đầu',
    'end': 'Kết thúc',
    'timezone': 'Múi giờ',
    'format': 'Hình thức',
    'location': 'Địa điểm / cách tham gia',
    'changePolicy': 'Chính sách đổi/hủy',
    'reviewMessage': 'Lời nhắn coordinator',
    'blockedReason': 'Điểm cần xử lý',
    'createdAt': 'Thời điểm tạo',
    'updatedAt': 'Cập nhật gần nhất',
    'expiresAt': 'Hết hạn',
    'reason': 'Lý do',
    'reasonCategory': 'Nhóm lý do',
    'actor': 'Người thao tác',
    'time': 'Thời điểm',
    'timestamp': 'Thời điểm',
    'action': 'Thao tác',
    'history': 'Lịch sử',
    'changes': 'Các lần chỉnh sửa',
    'before': 'Nội dung trước thay đổi',
    'after': 'Nội dung sau thay đổi',
    'purpose': 'Mục đích',
    'fields': 'Trường chia sẻ',
    'profile': 'Hồ sơ được xem',
    'sharedWithFamily': 'Chia sẻ với gia đình',
    'agenda': 'Chuẩn bị buổi',
    'summary': 'Ghi nhận học tập',
    'adjustments': 'Điều chỉnh đã dùng',
    'nextSteps': 'Bước tiếp theo',
    'dataGaps': 'Dữ liệu còn thiếu',
    'uncertainty': 'Giới hạn của gợi ý',
    'reasonCodes': 'Lý do phù hợp',
    'sourceFields': 'Trường tạo lý do',
    'algorithmVersion': 'Phiên bản bảng điểm',
    'mode': 'Chế độ',
    'effectiveMode': 'Phương án thực tế đã chạy',
    'modelVersion': 'Phiên bản model',
    'fallback': 'Phương án khi AI lỗi',
    'snapshotAt': 'Thời điểm đối chiếu',
    'finishedAt': 'Hoàn tất',
    'assignedTo': 'Người phụ trách',
    'handlerId': 'Người xử lý',
    'type': 'Loại yêu cầu',
    'description': 'Mô tả',
    'contact': 'Cách liên hệ',
    'visibility': 'Phạm vi riêng tư',
    'urgency': 'Mức khẩn',
    'reviewedBy': 'Người review',
    'reviewedAt': 'Thời điểm review',
    'learnerParticipation': 'Ý kiến / cách tham gia của learner',
    'purposes': 'Quyền theo mục đích',
    'exceptions': 'Phạm vi ngoại lệ',
    'role': 'Vai trò',
    'experience': 'Trải nghiệm / kinh nghiệm',
    'scheduleFit': 'Lịch có phù hợp',
    'learningFit': 'Cách học có phù hợp',
    'continueDoing': 'Điều nên tiếp tục',
    'change': 'Điều cần thay đổi',
    'signal': 'Cảm nhận',
    'event': 'Cập nhật',
    'preview': 'Thông báo',
    'category': 'Nhóm',
    'read': 'Đã đọc',
    'result': 'Kết quả',
    'resource': 'Tài nguyên',
    'sequence': 'Thứ tự',
    'metadata': 'Thông tin truy vết',
    'retentionDays': 'Thời hạn lưu (ngày)',
    'inventory': 'Nơi lưu/xử lý',
    'system': 'Hệ thống',
    'retention': 'Thời hạn lưu',
    'verified': 'Bằng chứng review',
    'exception': 'Ngoại lệ',
    'access': 'Ai đã xem / nhận',
    'grants': 'Consent đã cấp',
    'stage': 'Giai đoạn được chia sẻ',
    'parentBookingId': 'Booking trước',
    'rematchReason': 'Lý do đổi tutor',
    'ageHours': 'Số giờ chờ',
    'owner': 'Người phụ trách',
    'criteriaVersion': 'Phiên bản tiêu chí',
    'consentVersion': 'Phiên bản consent',
    'profileRevision': 'Phiên bản hồ sơ',
    'requestRevision': 'Phiên bản yêu cầu',
    'supersedesId': 'Tham chiếu bản ghi trước',
    'shareWithFamily': 'Chia sẻ với gia đình',
    'shareWithTutor': 'Chia sẻ với tutor',
    'shareWithCoordinator': 'Chia sẻ với coordinator',
    'familyAccepted': 'Gia đình đã đồng ý',
    'tutorAccepted': 'Tutor đã đồng ý',
    'previousSlot': 'Khung giờ trước khi đề xuất thay đổi',
    'proposedBy': 'Người đề xuất giờ mới',
    'enabled': 'Đang bật',
    'modelCard': 'Model card',
    'testEvidence': 'Bằng chứng đánh giá',
    'rollbackPath': 'Cách rollback',
    'incidentContact': 'Đầu mối model',
    'providerReviewRef': 'Review provider',
    'privacyReviewRef': 'Review privacy',
    'fairnessReviewRef': 'Review fairness',
  };
  String display(dynamic value) {
    if (value == null) return 'Chưa có';
    if (value is bool) return value ? 'Có' : 'Không';
    if (value is List) return value.map(display).join(', ');
    if (value is String && RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(value)) {
      return tssaDate(value);
    }
    return tssaStatus(
      tssaPurposes[value] ?? tssaFields[value] ?? tssaFormats[value] ?? value,
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final entry in data.entries.where(
        (e) => labels.containsKey(e.key) && e.value != null,
      ))
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: entry.value is Map
              ? ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(labels[entry.key]!),
                  children: [
                    TssaPanel(Map<String, dynamic>.from(entry.value as Map)),
                  ],
                )
              : entry.value is List &&
                    (entry.value as List).isNotEmpty &&
                    (entry.value as List).first is Map
              ? ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(labels[entry.key]!),
                  children: [
                    for (final row in entry.value as List)
                      TssaPanel(Map<String, dynamic>.from(row as Map)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labels[entry.key]!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SelectableText(display(entry.value)),
                  ],
                ),
        ),
    ],
  );
}
