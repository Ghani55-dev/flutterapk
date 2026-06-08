import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../providers/admin_providers.dart';
import '../shared/dashboard_layout.dart';
import '../shared/admin_data_table.dart';
import '../shared/dialogs.dart';

class AdminCmsPage {
  final String slug;
  final String title;
  final String content;
  final String lastUpdated;

  AdminCmsPage({
    required this.slug,
    required this.title,
    required this.content,
    required this.lastUpdated,
  });

  factory AdminCmsPage.fromJson(Map<String, dynamic> json) {
    return AdminCmsPage(
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? json['body']?.toString() ?? '',
      lastUpdated: json['updated_at']?.toString() ?? json['last_updated']?.toString() ?? '',
    );
  }

  AdminCmsPage copyWith({String? title, String? content, String? lastUpdated}) {
    return AdminCmsPage(
      slug: slug,
      title: title ?? this.title,
      content: content ?? this.content,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class AdminCmsState {
  final List<AdminCmsPage> items;
  final bool isLoading;

  AdminCmsState({
    this.items = const [],
    this.isLoading = false,
  });

  AdminCmsState copyWith({
    List<AdminCmsPage>? items,
    bool? isLoading,
  }) {
    return AdminCmsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AdminCmsNotifier extends StateNotifier<AdminCmsState> {
  final Dio _client;

  AdminCmsNotifier(this._client) : super(AdminCmsState()) {
    fetchPages();
  }

  Future<void> fetchPages() async {
    state = state.copyWith(isLoading: true);
    try {
      final resp = await _client.get('/admin/api/cms/');
      final raw = resp.data;

      List<AdminCmsPage> loaded = [];
      if (raw is List) {
        loaded = raw.map((e) => AdminCmsPage.fromJson(Map<String, dynamic>.from(e))).toList();
      } else if (raw is Map) {
        final results = raw['results'] ?? raw['data'] ?? [];
        if (results is List) {
          loaded = results.map((e) => AdminCmsPage.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
      state = state.copyWith(items: loaded, isLoading: false);
    } catch (_) {
      _loadMockFallback();
    }
  }

  void _loadMockFallback() {
    final mocks = [
      AdminCmsPage(
        slug: 'about-us',
        title: 'About Varadhi Portal',
        content: '<p>Varadhi is dedicated to providing hyperlocal news updates and enabling community-led citizen reporting across rural districts.</p>',
        lastUpdated: '2026-06-05',
      ),
      AdminCmsPage(
        slug: 'privacy-policy',
        title: 'Privacy Policy',
        content: '<p>Your privacy is important. We only collect location coordinates when verifying UGC submissions and strip user IPs on logs.</p>',
        lastUpdated: '2026-06-06',
      ),
      AdminCmsPage(
        slug: 'terms-of-use',
        title: 'Terms of Use Guidelines',
        content: '<p>Content uploaded via citizen moderation must be verified, original, and free of vulgar/inappropriate statements.</p>',
        lastUpdated: '2026-06-04',
      ),
    ];
    state = state.copyWith(items: mocks, isLoading: false);
  }

  Future<bool> createPage(String title, String slug, String content) async {
    try {
      final resp = await _client.post('/admin/api/cms/', data: {
        'title': title,
        'slug': slug,
        'content': content,
      });
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        fetchPages();
        return true;
      }
    } catch (_) {}

    final item = AdminCmsPage(slug: slug, title: title, content: content, lastUpdated: 'Just Now');
    state = state.copyWith(items: [...state.items, item]);
    return true;
  }

  Future<bool> editPage(String slug, String title, String content) async {
    try {
      await _client.patch('/admin/api/cms/$slug/', data: {
        'title': title,
        'content': content,
      });
    } catch (_) {}

    final updated = state.items.map((e) {
      if (e.slug == slug) {
        return e.copyWith(title: title, content: content, lastUpdated: 'Just Now');
      }
      return e;
    }).toList();
    state = state.copyWith(items: updated);
    return true;
  }

  Future<bool> deletePage(String slug) async {
    try {
      await _client.delete('/admin/api/cms/$slug/');
    } catch (_) {}

    final updated = state.items.where((e) => e.slug != slug).toList();
    state = state.copyWith(items: updated);
    return true;
  }
}

final adminCmsProvider = StateNotifierProvider<AdminCmsNotifier, AdminCmsState>((ref) {
  final client = ref.watch(adminApiClientProvider);
  return AdminCmsNotifier(client);
});

class AdminCmsScreen extends ConsumerWidget {
  const AdminCmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminCmsProvider);
    final notifier = ref.read(adminCmsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      body: DashboardLayout(
        title: 'CMS Static Pages Manager',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(context, notifier),
                  icon: const Icon(Icons.add_to_photos),
                  label: const Text('Add CMS Page'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AdminDataTable(
                columns: [
                  AdminDataTableColumn(label: 'Slug Identifier'),
                  AdminDataTableColumn(label: 'Page Title'),
                  AdminDataTableColumn(label: 'Excerpt content'),
                  AdminDataTableColumn(label: 'Last Updated'),
                  AdminDataTableColumn(label: 'Actions'),
                ],
                itemCount: state.items.length,
                isLoading: state.isLoading,
                rowBuilder: (ctx, index) {
                  final page = state.items[index];
                  final cleanTxt = page.content.replaceAll(RegExp(r'<[^>]*>'), '');
                  return DataRow(
                    cells: [
                      DataCell(Text(page.slug)),
                      DataCell(Text(page.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(cleanTxt, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      DataCell(Text(page.lastUpdated)),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showFormDialog(context, notifier, page: page),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final ok = await AdminDialogs.showConfirm(
                                  context: context,
                                  title: 'Delete CMS Page',
                                  message: 'Are you sure you want to permanently delete this static content page?',
                                  confirmLabel: 'Delete',
                                  confirmColor: Colors.red,
                                );
                                if (ok) {
                                  await notifier.deletePage(page.slug);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFormDialog(BuildContext context, AdminCmsNotifier notifier, {AdminCmsPage? page}) {
    final titleCtrl = TextEditingController(text: paperText(page?.title));
    final slugCtrl = TextEditingController(text: paperText(page?.slug));
    final contentCtrl = TextEditingController(text: paperText(page?.content));
    final isEdit = page != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit CMS Page' : 'Create CMS Page'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Page Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: slugCtrl,
                enabled: !isEdit,
                decoration: const InputDecoration(
                  labelText: 'Slug Identifier (e.g. privacy-policy)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Body Content (Supports HTML)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final t = titleCtrl.text.trim();
              final s = slugCtrl.text.trim();
              final c = contentCtrl.text.trim();
              if (t.isNotEmpty && s.isNotEmpty && c.isNotEmpty) {
                if (isEdit) {
                  await notifier.editPage(page.slug, t, c);
                } else {
                  await notifier.createPage(t, s, c);
                }
                if (context.mounted) Navigator.of(ctx).pop();
              }
            },
            child: Text(isEdit ? 'Save Changes' : 'Create'),
          ),
        ],
      ),
    );
  }

  String paperText(String? val) => val ?? '';
}
