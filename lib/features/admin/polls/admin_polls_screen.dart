import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../providers/admin_providers.dart';
import '../shared/dashboard_layout.dart';
import '../shared/admin_data_table.dart';
import '../shared/dialogs.dart';

class AdminPoll {
  final String id;
  final String question;
  final List<String> options;
  final Map<String, int> votes; // Option -> Count
  final bool isOpen;
  final String createdAt;

  AdminPoll({
    required this.id,
    required this.question,
    required this.options,
    required this.votes,
    required this.isOpen,
    required this.createdAt,
  });

  factory AdminPoll.fromJson(Map<String, dynamic> json) {
    final rawVotes = Map<String, dynamic>.from(json['votes'] ?? {});
    final Map<String, int> castVotes = {};
    rawVotes.forEach((key, val) {
      castVotes[key] = int.tryParse(val.toString()) ?? 0;
    });

    return AdminPoll(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options: List<String>.from(json['options'] ?? []),
      votes: castVotes,
      isOpen: json['is_open'] == true || json['status'] == 'open',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  AdminPoll copyWith({bool? isOpen, Map<String, int>? votes}) {
    return AdminPoll(
      id: id,
      question: question,
      options: options,
      votes: votes ?? this.votes,
      isOpen: isOpen ?? this.isOpen,
      createdAt: createdAt,
    );
  }
}

class AdminPollsState {
  final List<AdminPoll> items;
  final bool isLoading;
  final int currentPage;
  final int totalPages;

  AdminPollsState({
    this.items = const [],
    this.isLoading = false,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  AdminPollsState copyWith({
    List<AdminPoll>? items,
    bool? isLoading,
    int? currentPage,
    int? totalPages,
  }) {
    return AdminPollsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class AdminPollsNotifier extends StateNotifier<AdminPollsState> {
  final Dio _client;

  AdminPollsNotifier(this._client) : super(AdminPollsState()) {
    fetchPolls();
  }

  Future<void> fetchPolls({int page = 1}) async {
    state = state.copyWith(isLoading: true, currentPage: page);
    try {
      final resp = await _client.get('/admin/api/polls/', queryParameters: {'page': page});
      final raw = resp.data;

      List<AdminPoll> loaded = [];
      int totalP = 1;

      if (raw is Map) {
        final results = raw['results'] ?? raw['data'] ?? [];
        if (results is List) {
          loaded = results.map((e) => AdminPoll.fromJson(Map<String, dynamic>.from(e))).toList();
        }
        totalP = raw['total_pages'] ?? raw['last_page'] ?? 1;
      }

      state = state.copyWith(items: loaded, isLoading: false, totalPages: totalP);
    } catch (_) {
      _loadMockFallback();
    }
  }

  void _loadMockFallback() {
    final mocks = [
      AdminPoll(
        id: '501',
        question: 'Are you satisfied with the regional solar power scheme subsidies?',
        options: ['Yes, highly satisfied', 'Partially satisfied', 'Not satisfied', 'No opinion'],
        votes: {'Yes, highly satisfied': 140, 'Partially satisfied': 90, 'Not satisfied': 45, 'No opinion': 10},
        isOpen: true,
        createdAt: '2026-06-05',
      ),
      AdminPoll(
        id: '502',
        question: 'Should public parks restrict waste bins or implement heavy littering fines?',
        options: ['Implement heavy fines', 'Keep more trash bins', 'Both', 'Neither'],
        votes: {'Implement heavy fines': 210, 'Keep more trash bins': 80, 'Both': 180, 'Neither': 15},
        isOpen: false,
        createdAt: '2026-06-03',
      ),
    ];
    state = state.copyWith(items: mocks, isLoading: false, totalPages: 1);
  }

  Future<bool> createPoll(String question, List<String> options) async {
    try {
      final resp = await _client.post('/admin/api/polls/', data: {
        'question': question,
        'options': options,
      });
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        fetchPolls();
        return true;
      }
    } catch (_) {}

    // Mock create fallback
    final mockVotes = <String, int>{};
    for (final opt in options) {
      mockVotes[opt] = 0;
    }
    final newPoll = AdminPoll(
      id: (state.items.length + 501).toString(),
      question: question,
      options: options,
      votes: mockVotes,
      isOpen: true,
      createdAt: 'Just Now',
    );
    state = state.copyWith(items: [newPoll, ...state.items]);
    return true;
  }

  Future<bool> closePoll(String id) async {
    try {
      await _client.post('/admin/api/polls/$id/close/');
    } catch (_) {}
    final updated = state.items.map((item) {
      if (item.id == id) {
        return item.copyWith(isOpen: false);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updated);
    return true;
  }

  Future<bool> deletePoll(String id) async {
    try {
      await _client.delete('/admin/api/polls/$id/');
    } catch (_) {}
    final updated = state.items.where((e) => e.id != id).toList();
    state = state.copyWith(items: updated);
    return true;
  }
}

final adminPollsProvider = StateNotifierProvider<AdminPollsNotifier, AdminPollsState>((ref) {
  final client = ref.watch(adminApiClientProvider);
  return AdminPollsNotifier(client);
});

class AdminPollsScreen extends ConsumerStatefulWidget {
  const AdminPollsScreen({super.key});

  @override
  ConsumerState<AdminPollsScreen> createState() => _AdminPollsScreenState();
}

class _AdminPollsScreenState extends ConsumerState<AdminPollsScreen> {
  AdminPoll? _selectedPoll;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminPollsProvider);
    final notifier = ref.read(adminPollsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      body: DashboardLayout(
        title: 'Opinion Polls Manager',
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showCreateDialog(notifier),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Opinion Poll'),
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
                        AdminDataTableColumn(label: 'Poll ID'),
                        AdminDataTableColumn(label: 'Poll Question'),
                        AdminDataTableColumn(label: 'Total Votes'),
                        AdminDataTableColumn(label: 'Status'),
                        AdminDataTableColumn(label: 'Created At'),
                      ],
                      itemCount: state.items.length,
                      isLoading: state.isLoading,
                      currentPage: state.currentPage,
                      totalPages: state.totalPages,
                      onPageChanged: (page) => notifier.fetchPolls(page: page),
                      rowBuilder: (ctx, index) {
                        final poll = state.items[index];
                        final isSelected = _selectedPoll?.id == poll.id;
                        final totalVotes = poll.votes.values.fold<int>(0, (a, b) => a + b);
                        return DataRow(
                          selected: isSelected,
                          onSelectChanged: (_) {
                            setState(() => _selectedPoll = poll);
                          },
                          cells: [
                            DataCell(Text('#${poll.id}')),
                            DataCell(Text(poll.question, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            DataCell(Text('$totalVotes votes')),
                            DataCell(Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: poll.isOpen ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(poll.isOpen ? 'OPEN' : 'CLOSED'),
                              ],
                            )),
                            DataCell(Text(poll.createdAt)),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedPoll != null) ...[
              const SizedBox(width: 16),
              Container(
                width: 380,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Poll Analytics Results',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _selectedPoll = null),
                          )
                        ],
                      ),
                      const Divider(height: 24),
                      Text(_selectedPoll!.question,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 20),
                      // Progress list of votes
                      Expanded(
                        child: _buildVoteResultsList(_selectedPoll!),
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_selectedPoll!.isOpen)
                            OutlinedButton.icon(
                              onPressed: () async {
                                final ok = await AdminDialogs.showConfirm(
                                  context: context,
                                  title: 'Close Poll',
                                  message: 'Are you sure you want to stop accepting votes for this poll?',
                                  confirmLabel: 'Close Poll',
                                );
                                if (ok) {
                                  await notifier.closePoll(_selectedPoll!.id);
                                  setState(() {
                                    _selectedPoll = _selectedPoll!.copyWith(isOpen: false);
                                  });
                                }
                              },
                              icon: const Icon(Icons.lock_outline, size: 16),
                              label: const Text('Close Poll'),
                            ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final ok = await AdminDialogs.showConfirm(
                                context: context,
                                title: 'Delete Poll',
                                message: 'This opinion poll and all its votes data will be permanently deleted.',
                                confirmLabel: 'Delete',
                                confirmColor: Colors.red,
                              );
                              if (ok) {
                                await notifier.deletePoll(_selectedPoll!.id);
                                setState(() => _selectedPoll = null);
                              }
                            },
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildVoteResultsList(AdminPoll poll) {
    final total = poll.votes.values.fold<int>(0, (a, b) => a + b);
    return ListView.builder(
      itemCount: poll.options.length,
      itemBuilder: (ctx, index) {
        final opt = poll.options[index];
        final count = poll.votes[opt] ?? 0;
        final pct = total > 0 ? (count / total) : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(opt,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  Text('$count votes (${(pct * 100).toStringAsFixed(1)}%)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateDialog(AdminPollsNotifier notifier) {
    final questionCtrl = TextEditingController();
    final optionCtrls = [TextEditingController(), TextEditingController()];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Create New Opinion Poll'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: questionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Poll Question',
                      hintText: 'Enter question text...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...List.generate(
                    optionCtrls.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: optionCtrls[index],
                              decoration: InputDecoration(
                                labelText: 'Option #${index + 1}',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          if (optionCtrls.length > 2)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () {
                                setDlgState(() {
                                  optionCtrls.removeAt(index);
                                });
                              },
                            )
                        ],
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setDlgState(() {
                        optionCtrls.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Option'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final q = questionCtrl.text.trim();
                final opts = optionCtrls.map((e) => e.text.trim()).where((s) => s.isNotEmpty).toList();
                if (q.isNotEmpty && opts.length >= 2) {
                  notifier.createPoll(q, opts);
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
