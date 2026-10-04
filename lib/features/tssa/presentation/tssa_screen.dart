import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_controller.dart';
import '../data/tssa_repository.dart';
import 'tssa_form.dart';
import 'tssa_profiles.dart';
import 'tssa_workflows.dart';
import 'tssa_governance.dart';
import 'tssa_ui.dart';

class TssaScreen extends ConsumerStatefulWidget {
  const TssaScreen({super.key});
  @override
  ConsumerState<TssaScreen> createState() => _TssaScreenState();
}

class _TssaScreenState extends ConsumerState<TssaScreen> {
  int _selected = 0;
  @override
  Widget build(BuildContext context) => ref
      .watch(tssaIdentityProvider)
      .when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Hỗ trợ học tập')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Hỗ trợ học tập')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tssaError(error)),
                  TextButton(
                    onPressed: () => ref.invalidate(tssaIdentityProvider),
                    child: const Text('Tải lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (me) {
          final role = me['role'];
          final destinations = role == 'admin'
              ? ['Quản trị', 'Audit', 'Chất lượng', 'Hỗ trợ']
              : role == 'coordinator'
              ? ['Queue', 'Xác minh', 'Lịch', 'Hỗ trợ']
              : role == 'tutor'
              ? ['Hồ sơ', 'Ca được mời', 'Lịch', 'Hỗ trợ']
              : ['Hồ sơ', 'Yêu cầu', 'Lịch', 'Hỗ trợ'];
          final pages = role == 'admin'
              ? <Widget>[
                  TssaGovernance(me: me),
                  const TssaAudit(),
                  const TssaMetrics(),
                  TssaSupport(me: me),
                ]
              : role == 'coordinator'
              ? <Widget>[
                  TssaRequests(me: me),
                  TssaTutors(me: me),
                  TssaBookings(me: me),
                  TssaSupport(me: me),
                ]
              : role == 'tutor'
              ? <Widget>[
                  TssaProfilesHub(me: me),
                  TssaBookings(me: me, invitationsOnly: true),
                  TssaBookings(me: me),
                  TssaSupport(me: me),
                ]
              : <Widget>[
                  TssaProfilesHub(me: me),
                  TssaRequests(me: me),
                  TssaBookings(me: me),
                  TssaSupport(me: me),
                ];
          return Scaffold(
            appBar: AppBar(
              title: Text('TSSA · ${destinations[_selected]}'),
              actions: [
                if (role != 'unassigned')
                  IconButton(
                    tooltip: 'Thông báo của bạn',
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => tssaOpenPage(
                      context,
                      'Thông báo',
                      const TssaNotifications(),
                    ),
                  ),
                PopupMenuButton<String>(
                  tooltip: 'Tùy chọn tài khoản',
                  onSelected: (action) async {
                    if (action == 'logout') {
                      await ref.read(authControllerProvider.notifier).logout();
                    } else if (action == 'refresh') {
                      ref.invalidate(tssaIdentityProvider);
                    } else if (action == 'preferences' && context.mounted) {
                      tssaOpenPage(
                        context,
                        'Tùy chọn',
                        const TssaPreferences(),
                      );
                    } else if (action == 'privacy' && context.mounted) {
                      tssaOpenPage(
                        context,
                        'Quyền dữ liệu',
                        TssaPrivacyQueue(me: me),
                      );
                    } else if (action == 'metrics' && context.mounted) {
                      tssaOpenPage(
                        context,
                        'Chất lượng dịch vụ',
                        const TssaMetrics(),
                      );
                    } else if (action == 'intro' && context.mounted) {
                      tssaOpenPage(
                        context,
                        'Về dịch vụ',
                        const TssaPublicInfo(),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Text('Tải lại quyền và policy'),
                    ),
                    if (role != 'unassigned')
                      const PopupMenuItem(
                        value: 'preferences',
                        child: Text('Tùy chọn sử dụng'),
                      ),
                    if (role != 'unassigned')
                      const PopupMenuItem(
                        value: 'privacy',
                        child: Text('Yêu cầu quyền dữ liệu'),
                      ),
                    if (role == 'coordinator')
                      const PopupMenuItem(
                        value: 'metrics',
                        child: Text('Chất lượng trong nhóm'),
                      ),
                    const PopupMenuItem(
                      value: 'intro',
                      child: Text('Về dịch vụ / giới hạn'),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('Đăng xuất'),
                    ),
                  ],
                ),
              ],
            ),
            body: role == 'unassigned'
                ? TssaProfilesHub(me: me)
                : KeyedSubtree(
                    key: ValueKey('$role:$_selected'),
                    child: pages[_selected],
                  ),
            bottomNavigationBar: role == 'unassigned'
                ? null
                : NavigationBar(
                    animationDuration: MediaQuery.of(context).disableAnimations
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    selectedIndex: _selected,
                    onDestinationSelected: (index) =>
                        setState(() => _selected = index),
                    destinations: [
                      for (var i = 0; i < destinations.length; i++)
                        NavigationDestination(
                          icon: Icon(
                            [
                              Icons.person_outline,
                              Icons.fact_check_outlined,
                              Icons.event_note_outlined,
                              Icons.support_agent,
                            ][i],
                          ),
                          label: destinations[i],
                        ),
                    ],
                  ),
          );
        },
      );
}

class TssaRegistration extends StatelessWidget {
  const TssaRegistration({super.key});
  @override
  Widget build(BuildContext context) => const TssaFormScreen(
    title: 'Tạo tài khoản TSSA',
    path: 'accounts',
    fields: [
      TssaField('displayName', 'Tên hiển thị', required: true),
      TssaField('email', 'Email', required: true),
      TssaField(
        'password',
        'Mật khẩu (ít nhất 12 ký tự)',
        kind: 'password',
        required: true,
      ),
      TssaField(
        'role',
        'Vai trò',
        kind: 'select',
        required: true,
        options: {
          'learner': 'Người học',
          'guardian': 'Phụ huynh / người giám hộ',
          'tutor': 'Tutor',
        },
      ),
    ],
    explanation:
        'Tạo tài khoản không tự xác minh guardian hoặc tutor. Sau khi tạo, đăng nhập để hoàn thiện hồ sơ và được coordinator review.',
  );
}

class TssaPublicInfo extends StatelessWidget {
  const TssaPublicInfo({super.key});
  @override
  Widget build(BuildContext context) => const TssaList(
    title: 'Hỗ trợ học tập theo cách của bạn',
    children: [
      TssaCard(
        title: 'Bạn giữ quyền lựa chọn',
        children: [
          Text(
            'Learner và gia đình chọn mục tiêu, phần được chia sẻ và tutor muốn học. Coordinator review trước khi giới thiệu; tutor xác nhận lịch. Bạn có thể từ chối hoặc đề nghị ghép lại.',
          ),
        ],
      ),
      TssaCard(
        title: 'Thông tin cần thiết',
        children: [
          Text(
            'Môn, khối lớp, mục tiêu, hình thức, lịch rảnh và điều chỉnh tự chọn. Không cần chẩn đoán lâm sàng. Không ghi âm/video mặc định.',
          ),
        ],
      ),
      TssaCard(
        title: 'Riêng tư và phản hồi',
        children: [
          Text(
            'Guardian phải có liên kết được xác minh. Consent có mục đích, trường dữ liệu và thời hạn. Có thể thu hồi, xem ai đã truy cập, yêu cầu bản sao hoặc xóa theo policy. Learner có thể phản hồi ngắn hoặc không trả lời.',
          ),
        ],
      ),
      TssaCard(
        title: 'Giới hạn dịch vụ',
        children: [
          Text(
            'Đây là dịch vụ giáo dục và điều phối tutor, không phải dịch vụ chẩn đoán hoặc điều trị. App không phải kênh khẩn. Tổ chức phải công bố đầu mối và quy trình được xác minh trước pilot.',
          ),
        ],
      ),
      TssaCard(
        title: 'Khi mạng yếu',
        children: [
          Text(
            'Bản nháp được lưu trong kho an toàn trên thiết bị, hết hạn sau 24 giờ và xóa khi đăng xuất hoặc quyền bị thu hồi. Chỉ báo đã gửi khi máy chủ xác nhận. Trang giới thiệu này dùng được offline.',
          ),
        ],
      ),
    ],
  );
}
