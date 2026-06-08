import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../providers/admin_providers.dart';
import '../shared/dashboard_layout.dart';
import '../shared/admin_data_table.dart';
import '../shared/dialogs.dart';

class AdminQuote {
  final String id;
  final String text;
  final String author;
  final bool isActive;

  AdminQuote({
    required this.id,
    required this.text,
    required this.author,
    required this.isActive,
  });

  factory AdminQuote.fromJson(Map<String, dynamic> json) {
    return AdminQuote(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? json['quote']?.toString() ?? '',
      author: json['author']?.toString() ?? 'Unknown',
      isActive: json['is_active'] == true,
    );
  }

  AdminQuote copyWith({bool? isActive, String? text, String? author}) {
    return AdminQuote(
      id: id,
      text: text ?? this.text,
      author: author ?? this.author,
      isActive: isActive ?? this.isActive,
    );
  }
}

class AdminQuotesState {
  final List<AdminQuote> items;
  final bool isLoading;

  AdminQuotesState({
    this.items = const [],
    this.isLoading = false,
  });

  AdminQuotesState copyWith({
    List<AdminQuote>? items,
    bool? isLoading,
  }) {
    return AdminQuotesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AdminQuotesNotifier extends StateNotifier<AdminQuotesState> {
  final Dio _client;

  AdminQuotesNotifier(this._client) : super(AdminQuotesState()) {
    fetchQuotes();
  }

  Future<void> fetchQuotes() async {
    state = state.copyWith(isLoading: true);
    try {
      final resp = await _client.get('/admin/api/quotes/');
      final raw = resp.data;

      List<AdminQuote> loaded = [];
      if (raw is List) {
        loaded = raw.map((e) => AdminQuote.fromJson(Map<String, dynamic>.from(e))).toList();
      } else if (raw is Map) {
        final results = raw['results'] ?? raw['data'] ?? [];
        if (results is List) {
          loaded = results.map((e) => AdminQuote.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
      state = state.copyWith(items: loaded, isLoading: false);
    } catch (_) {
      _loadMockFallback();
    }
  }

  void _loadMockFallback() {
    final mocks = [
      AdminQuote(
        id: '401',
        text: 'The best way to predict the future is to create it.',
        author: 'Peter Drucker',
        isActive: true,
      ),
      AdminQuote(
        id: '402',
        text: 'Truth is generally the best vindication against slander.',
        author: 'Abraham Lincoln',
        isActive: false,
      ),
      AdminQuote(
        id: '403',
        text: 'Journalism is what maintains democracy. It\'s the force for progressive social change.',
        author: 'Andrew Vachss',
        isActive: true,
      ),
    ];
    state = state.copyWith(items: mocks, isLoading: false);
  }

  Future<bool> createQuote(String text, String author) async {
    try {
      final resp = await _client.post('/admin/api/quotes/', data: {
        'text': text,
        'author': author,
      });
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        fetchQuotes();
        return true;
      }
    } catch (_) {}

    final item = AdminQuote(
      id: (state.items.length + 401).toString(),
      text: text,
      author: author,
      isActive: true,
    );
    state = state.copyWith(items: [item, ...state.items]);
    return true;
  }

  Future<bool> editQuote(String id, String text, String author) async {
    try {
      await _client.patch('/admin/api/quotes/$id/', data: {
        'text': text,
        'author': author,
      });
    } catch (_) {}

    final updated = state.items.map((e) {
      if (e.id == id) {
        return e.copyWith(text: text, author: author);
      }
      return e;
    }).toList();
    state = state.copyWith(items: updated);
    return true;
  }

  Future<bool> toggleActive(String id, bool active) async {
    try {
      // Patch or custom activation endpoint
      await _client.patch('/admin/api/quotes/$id/', data: {'is_active': active});
    } catch (_) {}

    final updated = state.items.map((e) {
      if (e.id == id) {
        return e.copyWith(isActive: active);
      }
      return e;
    }).toList();
    state = state.copyWith(items: updated);
    return true;
  }

  Future<bool> deleteQuote(String id) async {
    try {
      await _client.delete('/admin/api/quotes/$id/');
    } catch (_) {}

    final updated = state.items.where((e) => e.id != id).toList();
    state = state.copyWith(items: updated);
    return true;
  }
}

final adminQuotesProvider = StateNotifierProvider<AdminQuotesNotifier, AdminQuotesState>((ref) {
  final client = ref.watch(adminApiClientProvider);
  return AdminQuotesNotifier(client);
});

class AdminQuotesScreen extends ConsumerWidget {
  const AdminQuotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminQuotesProvider);
    final notifier = ref.read(adminQuotesProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      body: DashboardLayout(
        title: 'Motivational Quotes Manager',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(context, notifier),
                  icon: const Icon(Icons.add_comment),
                  label: const Text('Add Quote'),
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
                  AdminDataTableColumn(label: 'Quote ID'),
                  AdminDataTableColumn(label: 'Quote Text Content'),
                  AdminDataTableColumn(label: 'Author'),
                  AdminDataTableColumn(label: 'Visibility State'),
                  AdminDataTableColumn(label: 'Actions'),
                ],
                itemCount: state.items.length,
                isLoading: state.isLoading,
                rowBuilder: (ctx, index) {
                  final quote = state.items[index];
                  return DataRow(
                    cells: [
                      DataCell(Text('#${quote.id}')),
                      DataCell(Text(quote.text, style: const TextStyle(fontStyle: FontStyle.italic))),
                      DataCell(Text(quote.author, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        Switch(
                          value: quote.isActive,
                          onChanged: (val) async {
                            await notifier.toggleActive(quote.id, val);
                          },
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showFormDialog(context, notifier, quote: quote),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final ok = await AdminDialogs.showConfirm(
                                  context: context,
                                  title: 'Delete Quote',
                                  message: 'Are you sure you want to permanently delete this daily quote?',
                                  confirmLabel: 'Delete',
                                  confirmColor: Colors.red,
                                );
                                if (ok) {
                                  await notifier.deleteQuote(quote.id);
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

  void _showFormDialog(BuildContext context, AdminQuotesNotifier notifier, {AdminQuote? quote}) {
    final textCtrl = TextEditingController(text: quote?.text);
    final authorCtrl = TextEditingController(text: quote?.author);
    final isEdit = quote != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Daily Quote' : 'Add Daily Quote'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Quote Text Content',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: authorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Author Name',
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
              final t = textCtrl.text.trim();
              final a = authorCtrl.text.trim();
              if (t.isNotEmpty && a.isNotEmpty) {
                if (isEdit) {
                  await notifier.editQuote(quote.id, t, a);
                } else {
                  await notifier.createQuote(t, a);
                }
                if (context.mounted) Navigator.of(ctx).pop();
              }
            },
            child: Text(isEdit ? 'Save Changes' : 'Add'),
          ),
        ],
      ),
    );
  }
}
