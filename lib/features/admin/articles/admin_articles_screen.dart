import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/admin_providers.dart';
import '../shared/dashboard_layout.dart';
import '../shared/dialogs.dart';

// Article class definition
class AdminArticle {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String
  status; // 'draft', 'in_review', 'approved', 'published', 'archived', 'rejected'
  final String authorName;
  final String authorId;
  final String category;
  final String categoryId;
  final String? publishedAt;
  final String? thumbnailUrl;
  final bool isFeatured;
  final bool isBreaking;

  AdminArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.status,
    required this.authorName,
    required this.authorId,
    required this.category,
    required this.categoryId,
    this.publishedAt,
    this.thumbnailUrl,
    this.isFeatured = false,
    this.isBreaking = false,
  });

  factory AdminArticle.fromJson(Map<String, dynamic> json) {
    return AdminArticle(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? json['excerpt']?.toString() ?? '',
      content: json['content']?.toString() ?? json['body']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      authorName: (json['author'] is Map)
          ? (json['author']['full_name'] ?? json['author']['name'] ?? '')
          : (json['author_email']?.toString() ?? 'Unknown'),
      authorId: (json['author'] is Map)
          ? (json['author']['id']?.toString() ?? '')
          : (json['author_id']?.toString() ?? ''),
      category: (json['category'] is Map)
          ? (json['category']['name'] ?? '')
          : (json['category']?.toString() ?? 'General'),
      categoryId: (json['category'] is Map)
          ? (json['category']['id']?.toString() ?? '')
          : (json['category_id']?.toString() ?? ''),
      publishedAt: json['published_at']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      isFeatured: json['is_featured'] == true,
      isBreaking: json['is_breaking'] == true,
    );
  }

  AdminArticle copyWith({
    String? status,
    bool? isFeatured,
    bool? isBreaking,
    String? title,
    String? summary,
    String? content,
    String? authorName,
    String? authorId,
    String? category,
    String? categoryId,
    String? publishedAt,
    String? thumbnailUrl,
  }) {
    return AdminArticle(
      id: id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      status: status ?? this.status,
      authorName: authorName ?? this.authorName,
      authorId: authorId ?? this.authorId,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      publishedAt: publishedAt ?? this.publishedAt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      isBreaking: isBreaking ?? this.isBreaking,
    );
  }
}

// State class for articles notifier
class AdminArticlesState {
  final List<AdminArticle> items;
  final bool isLoading;
  final String? error;
  final String search;
  final String statusFilter;
  final int currentPage;
  final int totalPages;

  AdminArticlesState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.statusFilter = 'all',
    this.currentPage = 1,
    this.totalPages = 1,
  });

  AdminArticlesState copyWith({
    List<AdminArticle>? items,
    bool? isLoading,
    String? error,
    String? search,
    String? statusFilter,
    int? currentPage,
    int? totalPages,
  }) {
    return AdminArticlesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      search: search ?? this.search,
      statusFilter: statusFilter ?? this.statusFilter,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

// Controller for managing state
class AdminArticlesNotifier extends StateNotifier<AdminArticlesState> {
  final Dio _client;

  AdminArticlesNotifier(this._client) : super(AdminArticlesState()) {
    fetchArticles();
  }

  Future<void> fetchArticles({int page = 1}) async {
    state = state.copyWith(isLoading: true, currentPage: page);
    try {
      final queryParams = {
        'page': page,
        if (state.search.isNotEmpty) 'search': state.search,
        if (state.statusFilter != 'all') 'status': state.statusFilter,
      };

      final resp = await _client.get(
        '/admin/api/articles/',
        queryParameters: queryParams,
      );
      final raw = resp.data;

      List<AdminArticle> loaded = [];
      int totalP = 1;

      if (raw is Map) {
        final results = raw['results'] ?? raw['data'] ?? [];
        if (results is List) {
          loaded = results
              .map((e) => AdminArticle.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
        totalP = raw['total_pages'] ?? raw['last_page'] ?? 1;
      } else if (raw is List) {
        loaded = raw
            .map((e) => AdminArticle.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      state = state.copyWith(
        items: loaded,
        isLoading: false,
        totalPages: totalP,
        error: null,
      );
    } catch (e) {
      debugPrint('Articles fetch failed: $e');
      state = state.copyWith(isLoading: false, error: e.toString(), items: []);
    }
  }

  void updateSearch(String val) {
    state = state.copyWith(search: val);
    fetchArticles(page: 1);
  }

  void updateFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
    fetchArticles(page: 1);
  }

  Future<bool> updateArticleStatus(String id, String newStatus) async {
    try {
      final endpoint =
          '/admin/api/articles/$id/${newStatus == 'approved' ? 'approve' : newStatus}/';
      await _client.post(endpoint);
      _updateItemStatus(id, newStatus);
      return true;
    } catch (e) {
      debugPrint('Status update failed: $e');
      return false;
    }
  }

  Future<bool> createArticle(Map<String, dynamic> data) async {
    try {
      final resp = await _client.post('/api/v1/articles/', data: data);
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        await fetchArticles(page: 1);
        return true;
      }
    } catch (e) {
      debugPrint('Create article failed: $e');
    }
    return false;
  }

  Future<bool> updateArticle(String id, Map<String, dynamic> data) async {
    try {
      final patchData = Map<String, dynamic>.from(data)
        ..remove('id')
        ..remove('slug')
        ..remove('author')
        ..remove('author_id')
        ..remove('author_email')
        ..remove('category_name')
        ..remove('status')
        ..remove('published_at')
        ..remove('created_at')
        ..remove('updated_at');

      await _client.patch('/admin/api/articles/$id/', data: patchData);
      await fetchArticles(page: state.currentPage);
      return true;
    } catch (e) {
      debugPrint('Update article failed: $e');
    }
    return false;
  }

  void _updateItemStatus(String id, String status) {
    final updated = state.items.map((item) {
      if (item.id == id) {
        return item.copyWith(status: status);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updated);
  }
}

// Riverpod binding
final adminArticlesProvider =
    StateNotifierProvider<AdminArticlesNotifier, AdminArticlesState>((ref) {
      final client = ref.watch(adminApiClientProvider);
      return AdminArticlesNotifier(client);
    });

// Categories provider
final adminCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final client = ref.watch(adminApiClientProvider);
  try {
    final resp = await client.get('/api/v1/categories/');
    final data = resp.data;

    if (data is Map && data['data'] is List) {
      return List<Map<String, dynamic>>.from(data['data'] as List);
    } else if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
  } catch (e) {
    debugPrint('Categories fetch failed: $e');
  }
  return [];
});

// Users/Authors provider
final adminUsersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final client = ref.watch(adminApiClientProvider);
  try {
    final resp = await client.get('/admin/api/users/');
    final data = resp.data;

    if (data is Map && data['data'] is List) {
      return List<Map<String, dynamic>>.from(data['data'] as List);
    } else if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
  } catch (e) {
    debugPrint('Users fetch failed: $e');
  }
  return [];
});

class AdminArticlesScreen extends ConsumerStatefulWidget {
  const AdminArticlesScreen({super.key});

  @override
  ConsumerState<AdminArticlesScreen> createState() =>
      _AdminArticlesScreenState();
}

class _AdminArticlesScreenState extends ConsumerState<AdminArticlesScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminArticlesProvider);
    final notifier = ref.read(adminArticlesProvider.notifier);
    final theme = Theme.of(context);
    final total = state.items.length;
    final published = _countStatus(state.items, 'published');
    final review = _countStatus(state.items, 'in_review');
    final featured = state.items.where((item) => item.isFeatured).length;

    return Scaffold(
      body: DashboardLayout(
        title: 'Articles Management',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Compact 2x2 metrics grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.8,
              children: [
                _MetricTile(
                  icon: Icons.article_outlined,
                  label: 'Total',
                  value: total.toString(),
                  color: theme.colorScheme.primary,
                ),
                _MetricTile(
                  icon: Icons.public,
                  label: 'Published',
                  value: published.toString(),
                  color: const Color(0xFF0F766E),
                ),
                _MetricTile(
                  icon: Icons.rate_review_outlined,
                  label: 'In Review',
                  value: review.toString(),
                  color: const Color(0xFFB45309),
                ),
                _MetricTile(
                  icon: Icons.star_outline,
                  label: 'Featured',
                  value: featured.toString(),
                  color: const Color(0xFF7C3AED),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildToolbar(context, state, notifier),
            const SizedBox(height: 10),
            Expanded(child: _buildArticlesSurface(context, state, notifier)),
          ],
        ),
      ),
    );
  }

  int _countStatus(List<AdminArticle> articles, String status) {
    return articles.where((item) => item.status == status).length;
  }

  Widget _buildToolbar(
    BuildContext context,
    AdminArticlesState state,
    AdminArticlesNotifier notifier,
  ) {
    final theme = Theme.of(context);
    const filters = [
      ('all', 'All'),
      ('draft', 'Draft'),
      ('in_review', 'Review'),
      ('approved', 'Approved'),
      ('published', 'Published'),
      ('rejected', 'Rejected'),
      ('archived', 'Archived'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 280,
            height: 40,
            child: TextField(
              onChanged: notifier.updateSearch,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 18),
                hintText: 'Search articles...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: filters.map((filter) {
                  final selected = state.statusFilter == filter.$1;
                  final isDark = theme.brightness == Brightness.dark;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      selected: selected,
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      avatar: selected
                          ? Icon(
                              Icons.check_circle,
                              size: 14,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      label: Text(
                        filter.$2,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      side: BorderSide(
                        color: selected
                            ? theme.colorScheme.primary.withAlpha(120)
                            : (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                      ),
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      selectedColor: theme.colorScheme.primary.withAlpha(32),
                      onSelected: (_) => notifier.updateFilter(filter.$1),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: () => _showArticleModal(context, ref, notifier),
            icon: const Icon(Icons.add),
            label: const Text('New Article'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(130, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticlesSurface(
    BuildContext context,
    AdminArticlesState state,
    AdminArticlesNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Editorial Queue',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Text(\n                    '${state.items.length} visible',\n                    style: theme.textTheme.bodySmall?.copyWith(\n                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E40AF),\n                      fontWeight: FontWeight.w700,\n                      fontSize: 11,\n                    ),\n                  ),\n                ),\n                const Spacer(),\n                IconButton(\n                  tooltip: 'Refresh',\n                  icon: Icon(\n                    Icons.refresh,\n                    size: 20,\n                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),\n                  ),\n                  onPressed: () =>\n                      notifier.fetchArticles(page: state.currentPage),\n                ),\n              ],\n            ),\n          ),
          if (state.isLoading)
            Expanded(child: _buildSkeletonLoader())
          else if (state.error != null)
            Expanded(child: _buildErrorState(state, notifier))
          else if (state.items.isEmpty)
            Expanded(child: _buildEmptyState(context, notifier))
          else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 1080),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dataTableTheme: DataTableThemeData(
                          headingRowColor: WidgetStateProperty.all(
                            isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          ),
                        ),
                      ),
                      child: DataTable(
                        headingRowHeight: 50,
                        dataRowMinHeight: 72,
                        dataRowMaxHeight: 82,
                        horizontalMargin: 18,
                        columnSpacing: 28,
                        headingRowColor: WidgetStateProperty.all(
                          isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        ),
                        dividerThickness: 0.8,
                        columns: [
                          DataColumn(
                            label: Text(
                              'Article',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Author',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Category',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(\n                              'Schedule',\n                              style: TextStyle(\n                                fontWeight: FontWeight.w700,\n                                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),\n                                fontSize: 12,\n                              ),\n                            ),\n                          ),\n                          DataColumn(\n                            label: Text(\n                              'Media',\n                              style: TextStyle(\n                                fontWeight: FontWeight.w700,\n                                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),\n                                fontSize: 12,\n                              ),\n                            ),\n                          ),\n                          DataColumn(\n                            label: Text(\n                              'State',\n                              style: TextStyle(\n                                fontWeight: FontWeight.w700,\n                                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),\n                                fontSize: 12,\n                              ),\n                            ),\n                          ),\n                          DataColumn(\n                            label: Text(\n                              'Actions',\n                              style: TextStyle(\n                                fontWeight: FontWeight.w700,\n                                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),\n                                fontSize: 12,\n                              ),\n                            ),\n                          ),\n                        ],\n                        rows: state.items.map((article) {\n                          return DataRow(\n                            cells: [\n                              DataCell(_buildArticleTitle(article)),\n                              DataCell(_mutedCell(article.authorName)),\n                              DataCell(_categoryPill(article.category)),\n                              DataCell(_mutedCell(article.publishedAt ?? '-')),\n                              DataCell(_buildThumbnail(article.thumbnailUrl)),\n                              DataCell(_buildStatusChip(article.status)),\n                              DataCell(\n                                SizedBox(\n                                  width: 290,\n                                  child: Wrap(\n                                    spacing: 6,\n                                    runSpacing: 6,\n                                    children: _buildRowActionButtons(\n                                      context,\n                                      article,\n                                      notifier,\n                                    ),\n                                  ),\n                                ),\n                              ),\n                            ],\n                          );\n                        }).toList(),\n                      ),\n                    ),\n                  ),\n                ),\n              ),\n            ),
        ],
      ),
    );
  }

  Widget _buildArticleTitle(AdminArticle article) {
    return Consumer(builder: (context, ref, _) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return SizedBox(
        width: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            if (article.summary.isNotEmpty)
              Text(
                article.summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              )
            else
              Text(
                'No summary',
                style: TextStyle(
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _mutedCell(String value) {
    return Consumer(builder: (context, ref, _) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return SizedBox(
        width: 120,
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      );
    });
  }

  Widget _categoryPill(String value) {
    return Consumer(builder: (context, ref, _) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return Container(
        constraints: const BoxConstraints(maxWidth: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
    });
  }

  Widget _buildThumbnail(String? url) {
    return Consumer(builder: (context, ref, _) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final hasUrl = url != null && url.isNotEmpty;
      return Container(
        width: 58,
        height: 46,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: hasUrl
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.broken_image_outlined,
                  color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                ),
              )
            : Icon(
                Icons.image_outlined,
                color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
              ),
      );
    });
  }

  Widget _buildErrorState(
    AdminArticlesState state,
    AdminArticlesNotifier notifier,
  ) {
    return Consumer(builder: (context, ref, _) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.error_outline,
                size: 32,
                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load articles',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              state.error ?? 'An error occurred while loading articles',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => notifier.fetchArticles(page: 1),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSkeletonLoader() {
    final itemsCount = 5;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemsCount,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail skeleton
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              // Title and metadata skeleton
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity * 0.6,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      width: double.infinity * 0.4,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Action buttons skeleton
              Container(
                width: 60,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AdminArticlesNotifier notifier,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.article_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No articles to display',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create your first article or adjust filters to see content',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showArticleModal(context, ref, notifier),
            icon: const Icon(Icons.add),
            label: const Text('Create Article'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRowActionButtons(
    BuildContext context,
    AdminArticle article,
    AdminArticlesNotifier notifier,
  ) {
    final buttons = <Widget>[];

    // Approve button (for draft/in_review)
    if (['draft', 'in_review'].contains(article.status)) {
      buttons.add(
        _ActionButton(
          label: 'Approve',
          icon: Icons.check,
          color: Colors.green,
          onPressed: () async {
            final ok = await notifier.updateArticleStatus(
              article.id,
              'approved',
            );
            if (ok && context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Article approved')));
            }
          },
        ),
      );
    }

    // Publish button (for approved)
    if (article.status == 'approved') {
      buttons.add(
        _ActionButton(
          label: 'Publish',
          icon: Icons.publish,
          color: Colors.blue,
          onPressed: () async {
            final ok = await notifier.updateArticleStatus(
              article.id,
              'published',
            );
            if (ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Article published')),
              );
            }
          },
        ),
      );
    }

    // Archive button (for published)
    if (article.status == 'published') {
      buttons.add(
        _ActionButton(
          label: 'Archive',
          icon: Icons.archive,
          color: Colors.orange,
          onPressed: () async {
            final confirmed = await AdminDialogs.showConfirm(
              context: context,
              title: 'Archive Article',
              message: 'Archive this published article?',
            );
            if (confirmed) {
              final ok = await notifier.updateArticleStatus(
                article.id,
                'archived',
              );
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Article archived')),
                );
              }
            }
          },
        ),
      );
    }

    // Reject button (for pending statuses)
    if (['draft', 'in_review'].contains(article.status)) {
      buttons.add(
        _ActionButton(
          label: 'Reject',
          icon: Icons.close,
          color: Colors.red,
          onPressed: () async {
            final confirmed = await AdminDialogs.showConfirm(
              context: context,
              title: 'Reject Article',
              message: 'Reject this article?',
            );
            if (confirmed) {
              final ok = await notifier.updateArticleStatus(
                article.id,
                'rejected',
              );
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Article rejected')),
                );
              }
            }
          },
        ),
      );
    }

    // Edit button (always available)
    buttons.add(
      _ActionButton(
        label: 'Edit',
        icon: Icons.edit,
        color: Colors.purple,
        onPressed: () => _showArticleModal(
          context,
          ref,
          ref.read(adminArticlesProvider.notifier),
          article: article,
        ),
      ),
    );

    return buttons;
  }

  Widget _buildStatusChip(String status) {
    return Consumer(builder: (context, ref, _) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      Color bg = Colors.grey.shade100;
      Color fg = Colors.grey.shade700;
      IconData icon = Icons.circle;

      switch (status) {
        case 'draft':
          bg = isDark ? const Color(0xFF334155) : Colors.grey.shade50;
          fg = isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700;
          icon = Icons.edit_note;
          break;
        case 'in_review':
          bg = isDark ? const Color(0xFF713F12) : Colors.amber.shade50;
          fg = isDark ? const Color(0xFFFCD34D) : Colors.amber.shade700;
          icon = Icons.rate_review_outlined;
          break;
        case 'approved':
          bg = isDark ? const Color(0xFF165E26) : Colors.green.shade50;
          fg = isDark ? const Color(0xFF86EFAC) : Colors.green.shade700;
          icon = Icons.verified_outlined;
          break;
        case 'rejected':
          bg = isDark ? const Color(0xFF7F1D1D) : Colors.red.shade50;
          fg = isDark ? const Color(0xFFFCA5A5) : Colors.red.shade700;
          icon = Icons.block;
          break;
        case 'published':
          bg = isDark ? const Color(0xFF1E40AF) : Colors.blue.shade50;
          fg = isDark ? const Color(0xFF93C5FD) : Colors.blue.shade700;
          icon = Icons.public;
          break;
        case 'archived':
          bg = isDark ? const Color(0xFF334155) : Colors.grey.shade200;
          fg = isDark ? const Color(0xFFA1A1AA) : Colors.grey.shade700;
          icon = Icons.archive_outlined;
          break;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fg.withAlpha(76)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              status.toUpperCase().replaceAll('_', ' '),
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showArticleModal(
    BuildContext context,
    WidgetRef ref,
    AdminArticlesNotifier notifier, {
    AdminArticle? article,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => ArticleFormModal(
        article: article,
        onSave: (data) async {
          bool ok;
          if (article != null) {
            ok = await notifier.updateArticle(article.id, data);
          } else {
            ok = await notifier.createArticle(data);
          }

          if (ok && ctx.mounted && context.mounted) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  article != null ? 'Article updated' : 'Article created',
                ),
              ),
            );
          }
        },
        ref: ref,
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A0F172A).withAlpha(isDark ? 30 : 16),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 40 : 24),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          foregroundColor: color,
          backgroundColor: color.withAlpha(18),
          side: BorderSide(color: color.withAlpha(62)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

// Article Form Modal
class ArticleFormModal extends ConsumerStatefulWidget {
  final AdminArticle? article;
  final Function(Map<String, dynamic>) onSave;
  final WidgetRef ref;

  const ArticleFormModal({
    super.key,
    required this.onSave,
    required this.ref,
    this.article,
  });

  @override
  ConsumerState<ArticleFormModal> createState() => _ArticleFormModalState();
}

class _ArticleFormModalState extends ConsumerState<ArticleFormModal> {
  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  late TextEditingController _contentController;
  late TextEditingController _seoTitleController;
  late TextEditingController _seoDescriptionController;
  late TextEditingController _seoTagsController;
  late TextEditingController _sourceUrlController;
  late TextEditingController _sourceNameController;
  late TextEditingController _stateController;
  late TextEditingController _districtController;
  late TextEditingController _priorityScoreController;
  late TextEditingController _thumbnailUrlController;

  String? _selectedCategoryId;
  String? _selectedAuthorId;
  String _selectedStatus = 'draft';
  String _selectedLanguage = 'en';
  bool _isFeatured = false;
  bool _isBreaking = false;
  bool _isLoading = false;
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article?.title ?? '');
    _summaryController = TextEditingController(
      text: widget.article?.summary ?? '',
    );
    _contentController = TextEditingController(
      text: widget.article?.content ?? '',
    );
    _seoTitleController = TextEditingController();
    _seoDescriptionController = TextEditingController();
    _seoTagsController = TextEditingController();
    _sourceUrlController = TextEditingController();
    _sourceNameController = TextEditingController();
    _stateController = TextEditingController();
    _districtController = TextEditingController();
    _priorityScoreController = TextEditingController(text: '100');
    _thumbnailUrlController = TextEditingController(
      text: widget.article?.thumbnailUrl ?? '',
    );

    _selectedCategoryId = widget.article?.categoryId;
    _selectedAuthorId = widget.article?.authorId;
    _selectedStatus = widget.article?.status ?? 'draft';
    _isFeatured = widget.article?.isFeatured ?? false;
    _isBreaking = widget.article?.isBreaking ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _seoTitleController.dispose();
    _seoDescriptionController.dispose();
    _seoTagsController.dispose();
    _sourceUrlController.dispose();
    _sourceNameController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _priorityScoreController.dispose();
    _thumbnailUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    final data = {
      'title': _titleController.text,
      'summary': _summaryController.text,
      'content': _contentController.text,
      'category': _selectedCategoryId,
      'language': _selectedLanguage,
      'status': _selectedStatus,
      'is_featured': _isFeatured,
      'is_breaking': _isBreaking,
      if (_thumbnailUrlController.text.isNotEmpty)
        'thumbnail_url': _thumbnailUrlController.text,
      if (_scheduledAt != null) 'scheduled_at': _scheduledAt!.toIso8601String(),
      if (_seoTitleController.text.isNotEmpty)
        'seo_title': _seoTitleController.text,
      if (_seoDescriptionController.text.isNotEmpty)
        'seo_description': _seoDescriptionController.text,
      if (_seoTagsController.text.isNotEmpty)
        'seo_tags': _seoTagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .toList(),
      if (_sourceUrlController.text.isNotEmpty)
        'source_url': _sourceUrlController.text,
      if (_sourceNameController.text.isNotEmpty)
        'source_name': _sourceNameController.text,
      if (_stateController.text.isNotEmpty) 'state': _stateController.text,
      if (_districtController.text.isNotEmpty)
        'district': _districtController.text,
      if (_priorityScoreController.text.isNotEmpty)
        'priority_score': int.tryParse(_priorityScoreController.text) ?? 100,
    };

    await widget.onSave(data);
    if (mounted) setState(() => _isLoading = false);
  }

  bool _validateForm() {
    if (_titleController.text.isEmpty) {
      _showError('Title is required');
      return false;
    }
    if (_summaryController.text.isEmpty) {
      _showError('Summary is required');
      return false;
    }
    if (_contentController.text.isEmpty) {
      _showError('Content is required');
      return false;
    }
    if (_selectedCategoryId == null) {
      _showError('Category is required');
      return false;
    }
    if (_selectedAuthorId == null) {
      _showError('Author is required');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _pickScheduleDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _scheduledAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _uploadThumbnail() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final adminClient = widget.ref.read(adminApiClientProvider);

      // Step 1: Get presigned URL
      final presignedResp = await adminClient.post(
        '/admin/api/articles/thumbnail-upload-url/',
        data: {
          'filename': pickedFile.name,
          'content_type': _contentTypeForFile(pickedFile.name),
        },
      );

      if (presignedResp.statusCode != 200 && presignedResp.statusCode != 201) {
        _showError('Failed to get upload URL');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final presignedData = _extractUploadPayload(presignedResp.data);
      final uploadUrl = _resolveUploadUrl(presignedData);
      final fields = presignedData['fields'] ?? {};
      final finalUrl = _resolveUploadedThumbnailUrl(presignedData, uploadUrl);

      if (uploadUrl.isEmpty) {
        _showError('Invalid upload URL received');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Step 2: Upload file to presigned URL with form data
      final formData = FormData();

      // Add fields if provided
      if (fields is Map) {
        fields.forEach((key, value) {
          formData.fields.add(MapEntry(key.toString(), value.toString()));
        });
      }

      // Add file
      formData.files.add(
        MapEntry(
          'file',
          MultipartFile.fromBytes(
            await pickedFile.readAsBytes(),
            filename: pickedFile.name,
          ),
        ),
      );

      // Upload to presigned URL (use plain Dio, not authenticated client)
      final uploadResp = await Dio().post(
        uploadUrl,
        data: formData,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
        ),
      );

      if (uploadResp.statusCode != null &&
          uploadResp.statusCode! >= 200 &&
          uploadResp.statusCode! < 400) {
        // Step 3: Use the returned URL or the final URL from presigned response
        final resultUrl = finalUrl;

        if (resultUrl.isEmpty) {
          _showError('Image uploaded, but thumbnail URL was not returned');
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        if (mounted) {
          setState(() {
            _thumbnailUrlController.text = resultUrl;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        _showError('Upload failed: ${uploadResp.statusCode}');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Upload error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _contentTypeForFile(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  Map<String, dynamic> _extractUploadPayload(dynamic raw) {
    if (raw is! Map) return {};

    final map = Map<String, dynamic>.from(raw);
    for (final key in ['data', 'result', 'payload']) {
      final nested = map[key];
      if (nested is Map) {
        final nestedMap = Map<String, dynamic>.from(nested);
        if (_resolveUploadUrl(nestedMap).isNotEmpty ||
            nestedMap.containsKey('fields')) {
          return nestedMap;
        }
      }
    }

    return map;
  }

  String _resolveUploadUrl(Map<String, dynamic> data) {
    for (final key in [
      'upload_url',
      'uploadUrl',
      'uploadURL',
      'presigned_url',
      'presignedUrl',
      'signed_url',
      'signedUrl',
      'url',
    ]) {
      final value = data[key]?.toString();
      if (value != null && value.isNotEmpty) return value;
    }

    return '';
  }

  String _resolveUploadedThumbnailUrl(
    Map<String, dynamic> data,
    String uploadUrl,
  ) {
    for (final key in ['thumbnail_url', 'url', 'file_url', 'public_url']) {
      final value = data[key]?.toString();
      if (value != null && value.isNotEmpty && value != uploadUrl) return value;
    }

    final fields = data['fields'];
    if (uploadUrl.isEmpty || fields is! Map) return '';

    final objectKey = fields['key']?.toString();
    if (objectKey == null || objectKey.isEmpty) return '';

    return '${uploadUrl.split('?').first.replaceFirst(RegExp(r'/$'), '')}/$objectKey';
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);
    final usersAsync = ref.watch(adminUsersProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.article != null ? Icons.edit_note : Icons.note_add,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.article != null ? 'Edit Article' : 'Add Article'),
                Text(
                  'Manage story details, metadata, scheduling, and thumbnail.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 920,
        height: MediaQuery.of(context).size.height * 0.78,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Title *',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter article title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // Summary
              const Text(
                'Summary *',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _summaryController,
                decoration: InputDecoration(
                  hintText: 'Brief summary of the article',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // Content
              const Text(
                'Content *',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  hintText: 'Article content (HTML supported)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 12),

              // Category
              const Text(
                'Category *',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  'Error loading categories: $e',
                  style: const TextStyle(fontSize: 12),
                ),
                data: (categories) {
                  // Ensure selected category ID exists in the list
                  final categoryIds = categories
                      .map((c) => c['id']?.toString())
                      .toSet();
                  if (_selectedCategoryId != null &&
                      !categoryIds.contains(_selectedCategoryId)) {
                    // If edit mode and category not found, select first available
                    _selectedCategoryId = categories.isNotEmpty
                        ? categories[0]['id']?.toString()
                        : null;
                  }
                  return DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCategoryId,
                    hint: const Text('Select category'),
                    items: categories
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat['id']?.toString(),
                            child: Text(cat['name']?.toString() ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategoryId = val),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Author
              const Text(
                'Author *',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              usersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  'Error loading authors: $e',
                  style: const TextStyle(fontSize: 12),
                ),
                data: (users) {
                  // Ensure selected author ID exists in the list
                  final userIds = users.map((u) => u['id']?.toString()).toSet();
                  if (_selectedAuthorId != null &&
                      !userIds.contains(_selectedAuthorId)) {
                    // If edit mode and author not found, select first available
                    _selectedAuthorId = users.isNotEmpty
                        ? users[0]['id']?.toString()
                        : null;
                  }
                  return DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedAuthorId,
                    hint: const Text('Select author'),
                    items: users
                        .map(
                          (user) => DropdownMenuItem(
                            value: user['id']?.toString(),
                            child: Text(
                              user['full_name']?.toString() ??
                                  user['name']?.toString() ??
                                  '',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedAuthorId = val),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Language
              const Text(
                'Language',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButton<String>(
                isExpanded: true,
                value: _selectedLanguage,
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'te', child: Text('Telugu')),
                  DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                  DropdownMenuItem(value: 'ta', child: Text('Tamil')),
                ],
                onChanged: (val) =>
                    setState(() => _selectedLanguage = val ?? 'en'),
              ),
              const SizedBox(height: 12),

              // Status
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButton<String>(
                isExpanded: true,
                value: _selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(
                    value: 'in_review',
                    child: Text('In Review'),
                  ),
                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                  DropdownMenuItem(
                    value: 'published',
                    child: Text('Published'),
                  ),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  DropdownMenuItem(value: 'archived', child: Text('Archived')),
                ],
                onChanged: (val) =>
                    setState(() => _selectedStatus = val ?? 'draft'),
              ),
              const SizedBox(height: 12),

              // Featured
              CheckboxListTile(
                title: const Text('Featured'),
                value: _isFeatured,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _isFeatured = val ?? false),
              ),
              const SizedBox(height: 8),
              // Breaking News
              CheckboxListTile(
                title: const Text('Breaking News'),
                value: _isBreaking,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _isBreaking = val ?? false),
              ),
              const SizedBox(height: 12),

              // Scheduled At
              const Text(
                'Scheduled At (Optional)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _pickScheduleDateTime,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _scheduledAt != null
                      ? _scheduledAt!.toString().split('.')[0]
                      : 'Select date & time',
                ),
              ),
              const SizedBox(height: 12),

              // Thumbnail URL
              const Text(
                'Thumbnail Image (Optional)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 108,
                      width: 132,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _thumbnailUrlController.text.isNotEmpty
                          ? Image.network(
                              _thumbnailUrlController.text,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image_outlined,
                                color: Color(0xFF94A3B8),
                              ),
                            )
                          : const Icon(
                              Icons.image_outlined,
                              color: Color(0xFF94A3B8),
                              size: 34,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_isLoading)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.icon(
                                  onPressed: _uploadThumbnail,
                                  icon: const Icon(Icons.cloud_upload),
                                  label: const Text('Upload Image'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => setState(
                                    () => _thumbnailUrlController.clear(),
                                  ),
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Clear'),
                                ),
                              ],
                            )
                          else
                            const LinearProgressIndicator(),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _thumbnailUrlController,
                            decoration: InputDecoration(
                              hintText: 'Paste CDN image URL',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: const Icon(Icons.image),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // SEO Title
              const Text(
                'SEO Title (Optional)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _seoTitleController,
                decoration: InputDecoration(
                  hintText: 'SEO title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // SEO Description
              const Text(
                'SEO Description (Optional)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _seoDescriptionController,
                decoration: InputDecoration(
                  hintText: 'SEO description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // SEO Tags
              const Text(
                'SEO Tags (Optional)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _seoTagsController,
                decoration: InputDecoration(
                  hintText: 'Comma-separated tags (e.g. tag1, tag2, tag3)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Source URL
              const Text(
                'Source URL (Optional)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _sourceUrlController,
                decoration: InputDecoration(
                  hintText: 'Original source URL',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Source Name
              const Text(
                'Source Name (Optional)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _sourceNameController,
                decoration: InputDecoration(
                  hintText: 'Source name (e.g., Reuters, AFP)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // State & District
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'State (Optional)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _stateController,
                          decoration: InputDecoration(
                            hintText: 'State name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'District (Optional)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _districtController,
                          decoration: InputDecoration(
                            hintText: 'District name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Priority Score
              const Text(
                'Priority Score (1-100)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _priorityScoreController,
                decoration: InputDecoration(
                  hintText: 'Priority score',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _handleSave,
          icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save),
          label: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.article != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
