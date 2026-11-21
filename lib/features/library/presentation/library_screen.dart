import 'package:flutter/material.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _query = query);
  }

  void _clear() {
    _searchController.clear();
    setState(() => _query = '');
  }

  List<_Book> _booksFor(String query) => [
    _Book(
      id: '1',
      title: '“$query” - Sách 1',
      author: 'Tác giả A, Tác giả B',
      publisher: 'Nhà xuất bản Giáo dục',
      year: '2023',
      isbn: '978-604-0-12345-6',
      description: 'Mô tả minh họa về tài liệu trong lĩnh vực nghiên cứu này.',
      availability: 'Có sẵn',
      location: 'Thư viện Tổng hợp - Tầng 2',
      callNumber: 'QA76.73.P98 T45 2023',
    ),
    _Book(
      id: '2',
      title: '$query - Lý thuyết và Thực hành',
      author: 'Nguyễn Văn A',
      publisher: 'Nhà xuất bản Đại học Quốc gia TP.HCM',
      year: '2022',
      isbn: '978-604-0-54321-7',
      description:
          'Ví dụ giao diện kết quả tìm kiếm; dữ liệu chưa được lấy từ catalog.',
      availability: 'Đang mượn',
      location: 'Thư viện Khoa học Tự nhiên',
      callNumber: 'TA168 .N49 2022',
    ),
    _Book(
      id: '3',
      title: 'Giáo trình $query',
      author: 'PGS.TS. Trần Thị B',
      publisher: 'Nhà xuất bản Bách Khoa',
      year: '2024',
      isbn: '978-604-0-98765-4',
      description: 'Mẫu minh họa giáo trình dành cho sinh viên đại học.',
      availability: 'Có sẵn',
      location: 'Thư viện Tổng hợp - Tầng 3',
      callNumber: 'QC21.3 .T73 2024',
    ),
    _Book(
      id: '4',
      title: 'Advanced $query Techniques',
      author: 'John Smith, Jane Doe',
      publisher: 'International Publishing House',
      year: '2023',
      isbn: '978-1-234-56789-0',
      description:
          'Ví dụ tài liệu tiếng Anh; thông tin mượn chưa kết nối thư viện.',
      availability: 'Đặt trước',
      location: 'Main Library - Floor 4',
      callNumber: 'HD30.28 .S65 2023',
    ),
    _Book(
      id: '5',
      title: '$query - Introduction and Applications',
      author: 'Robert Johnson',
      publisher: 'Academic Press',
      year: '2022',
      isbn: '978-0-123-45678-9',
      description: 'Mẫu giới thiệu chủ đề và ví dụ ứng dụng.',
      availability: 'Có sẵn',
      location: 'Engineering Library',
      callNumber: 'TK5105 .J64 2022',
    ),
    _Book(
      id: '6',
      title: 'Phát triển ứng dụng $query',
      author: 'Lê Văn C, Phạm Thị D',
      publisher: 'NXB Thông tin và Truyền thông',
      year: '2023',
      isbn: null,
      description: 'Mẫu hướng dẫn phát triển ứng dụng từ cơ bản đến nâng cao.',
      availability: 'Có sẵn',
      location: 'Thư viện Công nghệ Thông tin',
      callNumber: 'QA76.76 .L38 2023',
    ),
  ];

  Future<void> _showDetails(_Book book) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _BookDetailsSheet(book: book),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final books = _query.isEmpty ? const <_Book>[] : _booksFor(_query);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.local_library_outlined,
                  size: 34,
                  color: colors.onPrimaryContainer,
                ),
                const SizedBox(height: 16),
                Text(
                  'HCMUT LIBRARY',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Tìm giáo trình và tài liệu học tập.',
                  style: TextStyle(color: colors.onPrimaryContainer),
                ),
                const SizedBox(height: 18),
                SearchBar(
                  controller: _searchController,
                  hintText: 'Nhập tên sách để tìm kiếm',
                  leading: const Icon(Icons.search_rounded),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        tooltip: 'Xóa từ khóa',
                        onPressed: _clear,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    IconButton(
                      tooltip: 'Tìm sách',
                      onPressed: _search,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ],
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _search(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _DemoDataNotice(),
          const SizedBox(height: 20),
          if (_query.isEmpty)
            _LibraryEmpty(
              icon: Icons.menu_book_outlined,
              title: 'Tìm trong thư viện',
              message: 'Nhập từ khóa để xem giao diện kết quả sách.',
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Kết quả cho “$_query”',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text('${books.length} mẫu'),
              ],
            ),
            const SizedBox(height: 10),
            for (final book in books) ...[
              _BookCard(book: book, onTap: () => _showDetails(book)),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _DemoDataNotice extends StatelessWidget {
  const _DemoDataNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: colors.onTertiaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Kết quả hiện là dữ liệu minh họa giống website. Danh mục HCMUT Library chưa được kết nối; trạng thái mượn và vị trí không phải dữ liệu thật.',
                style: TextStyle(color: colors.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryEmpty extends StatelessWidget {
  const _LibraryEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(icon, size: 42, color: colors.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book, required this.onTap});

  final _Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 70,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.menu_book_rounded, color: colors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(book.author),
                    if (book.publisher != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${book.publisher} · ${book.year}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Mẫu minh họa · xem thông tin',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookDetailsSheet extends StatelessWidget {
  const _BookDetailsSheet({required this.book});

  final _Book book;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
    child: ListView(
      shrinkWrap: true,
      children: [
        Text(
          book.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(book.author),
        const SizedBox(height: 18),
        const _DemoDataNotice(),
        const SizedBox(height: 14),
        _DetailRow(label: 'Nhà xuất bản', value: book.publisher ?? 'Chưa có'),
        _DetailRow(label: 'Năm', value: book.year ?? 'Chưa có'),
        _DetailRow(label: 'ISBN', value: book.isbn ?? 'Chưa có'),
        _DetailRow(label: 'Trạng thái mẫu', value: book.availability),
        _DetailRow(label: 'Vị trí mẫu', value: book.location),
        _DetailRow(label: 'Mã xếp giá mẫu', value: book.callNumber),
        const SizedBox(height: 8),
        Text(book.description),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _Book {
  const _Book({
    required this.id,
    required this.title,
    required this.author,
    required this.publisher,
    required this.year,
    required this.isbn,
    required this.description,
    required this.availability,
    required this.location,
    required this.callNumber,
  });

  final String id;
  final String title;
  final String author;
  final String? publisher;
  final String? year;
  final String? isbn;
  final String description;
  final String availability;
  final String location;
  final String callNumber;
}
