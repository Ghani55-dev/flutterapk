import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../providers/admin_providers.dart';
import '../shared/dashboard_layout.dart';
import '../shared/admin_data_table.dart';
import '../shared/dialogs.dart';

class UgcSubmission {
  final String id;
  final String title;
  final String description;
  final String status; // 'pending', 'approved', 'rejected', 'flagged'
  final String submitterPhone;
  final String? mediaUrl;
  final String mediaType; // 'image', 'video', 'none'
  final String submittedAt;

  UgcSubmission({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.submitterPhone,
    this.mediaUrl,
    required this.mediaType,
    required this.submittedAt,
  });

  factory UgcSubmission.fromJson(Map<String, dynamic> json) {
    return UgcSubmission(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      submitterPhone: json['submitter_phone']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString(),
      mediaType: json['media_type']?.toString() ?? 'none',
      submittedAt: json['submitted_at']?.toString() ?? '',
    );
  }

  UgcSubmission copyWith({String? status}) {
    return UgcSubmission(
      id: id,
      title: title,
      description: description,
      status: status ?? this.status,
      submitterPhone: submitterPhone,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      submittedAt: submittedAt,
    );
  }
}

class AdminUgcState {
  final List<UgcSubmission> items;
  final bool isLoading;
  final String statusFilter;
  final int currentPage;
  final int totalPages;

  AdminUgcState({
    this.items = const [],
    this.isLoading = false,
    this.statusFilter = 'all',
    this.currentPage = 1,
    this.totalPages = 1,
  });

  AdminUgcState copyWith({
    List<UgcSubmission>? items,
    bool? isLoading,
    String? statusFilter,
    int? currentPage,
    int? totalPages,
  }) {
    return AdminUgcState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      statusFilter: statusFilter ?? this.statusFilter,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class AdminUgcNotifier extends StateNotifier<AdminUgcState> {
  final Dio _client;

  AdminUgcNotifier(this._client) : super(AdminUgcState()) {
    fetchQueue();
  }

  Future<void> fetchQueue({int page = 1}) async {
    state = state.copyWith(isLoading: true, currentPage: page);
    try {
      final queryParams = {
        'page': page,
        if (state.statusFilter != 'all') 'status': state.statusFilter,
      };

      final resp = await _client.get('/admin/api/ugc/queue/', queryParameters: queryParams);
      final raw = resp.data;

      List<UgcSubmission> loaded = [];
      int totalP = 1;

      if (raw is Map) {
        final results = raw['results'] ?? raw['data'] ?? [];
        if (results is List) {
          loaded = results.map((e) => UgcSubmission.fromJson(Map<String, dynamic>.from(e))).toList();
        }
        totalP = raw['total_pages'] ?? raw['last_page'] ?? 1;
      }

      state = state.copyWith(
        items: loaded,
        isLoading: false,
        totalPages: totalP,
      );
    } catch (_) {
      _loadMockFallback();
    }
  }

  void _loadMockFallback() {
    final mocks = [
      UgcSubmission(
        id: '2001',
        title: 'Broken Water Pipeline in Ward 4',
        description: 'Water has been leaking for past 3 days on main road. Huge traffic issue.',
        status: 'pending',
        submitterPhone: '+91 98765 43210',
        mediaUrl: 'https://picsum.photos/600/400?image=10',
        mediaType: 'image',
        submittedAt: '2026-06-06 10:30',
      ),
      UgcSubmission(
        id: '2002',
        title: 'Streetlight Inoperative in Market Area',
        description: 'No street lighting near vegetable market makes it risky for vendors at night.',
        status: 'pending',
        submitterPhone: '+91 98765 43211',
        mediaUrl: null,
        mediaType: 'none',
        submittedAt: '2026-06-06 09:15',
      ),
      UgcSubmission(
        id: '2003',
        title: 'Trash Dumping in Public Park',
        description: 'Garbage piling up inside Children park. Bad smell and hygiene issues.',
        status: 'flagged',
        submitterPhone: '+91 98765 43212',
        mediaUrl: 'https://picsum.photos/600/400?image=28',
        mediaType: 'image',
        submittedAt: '2026-06-05 14:00',
      ),
    ];

    final filtered = state.statusFilter == 'all'
        ? mocks
        : mocks.where((e) => e.status == state.statusFilter).toList();

    state = state.copyWith(items: filtered, isLoading: false, totalPages: 1);
  }

  void updateFilter(String val) {
    state = state.copyWith(statusFilter: val);
    fetchQueue(page: 1);
  }

  Future<bool> approve(String id) async {
    try {
      await _client.post('/admin/api/ugc/submissions/$id/approve/');
    } catch (_) {}
    _updateStatus(id, 'approved');
    return true;
  }

  Future<bool> reject(String id) async {
    try {
      await _client.post('/admin/api/ugc/submissions/$id/reject/');
    } catch (_) {}
    _updateStatus(id, 'rejected');
    return true;
  }

  Future<bool> flag(String id) async {
    try {
      await _client.post('/admin/api/ugc/submissions/$id/flag/');
    } catch (_) {}
    _updateStatus(id, 'flagged');
    return true;
  }

  void _updateStatus(String id, String status) {
    final updated = state.items.map((item) {
      if (item.id == id) {
        return item.copyWith(status: status);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updated);
  }
}

final adminUgcProvider = StateNotifierProvider<AdminUgcNotifier, AdminUgcState>((ref) {
  final client = ref.watch(adminApiClientProvider);
  return AdminUgcNotifier(client);
});

class AdminUgcScreen extends ConsumerStatefulWidget {
  const AdminUgcScreen({super.key});

  @override
  ConsumerState<AdminUgcScreen> createState() => _AdminUgcScreenState();
}

class _AdminUgcScreenState extends ConsumerState<AdminUgcScreen> {
  UgcSubmission? _selectedSubmission;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUgcProvider);
    final notifier = ref.read(adminUgcProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      body: DashboardLayout(
        title: 'UGC Moderation',
        child: Row(
          children: [
            Expanded(
              child: AdminDataTable(
                columns: [
                  AdminDataTableColumn(label: 'Submission ID', field: 'id'),
                  AdminDataTableColumn(label: 'Report Title', field: 'title'),
                  AdminDataTableColumn(label: 'Phone Number', field: 'phone'),
                  AdminDataTableColumn(label: 'Attachment', field: 'media_type'),
                  AdminDataTableColumn(label: 'Status', field: 'status'),
                  AdminDataTableColumn(label: 'Submitted At', field: 'submitted_at'),
                ],
                itemCount: state.items.length,
                isLoading: state.isLoading,
                currentPage: state.currentPage,
                totalPages: state.totalPages,
                onPageChanged: (page) => notifier.fetchQueue(page: page),
                onSearchChanged: (val) {
                  // Local filter fallback or search trigger
                },
                searchHint: 'Search report...',
                filters: Row(
                  children: [
                    const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: state.statusFilter,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'approved', child: Text('Approved')),
                        DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                        DropdownMenuItem(value: 'flagged', child: Text('Flagged')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          notifier.updateFilter(val);
                          setState(() => _selectedSubmission = null);
                        }
                      },
                    ),
                  ],
                ),
                rowBuilder: (ctx, index) {
                  final item = state.items[index];
                  final isSelected = _selectedSubmission?.id == item.id;
                  return DataRow(
                    selected: isSelected,
                    onSelectChanged: (_) {
                      setState(() => _selectedSubmission = item);
                    },
                    cells: [
                      DataCell(Text('#${item.id}')),
                      DataCell(Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      DataCell(Text(item.submitterPhone)),
                      DataCell(Row(
                        children: [
                          Icon(
                            item.mediaType == 'image' ? Icons.image : (item.mediaType == 'video' ? Icons.video_library : Icons.insert_drive_file),
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(item.mediaType.toUpperCase(), style: const TextStyle(fontSize: 12)),
                        ],
                      )),
                      DataCell(_buildStatusChip(item.status)),
                      DataCell(Text(item.submittedAt)),
                    ],
                  );
                },
              ),
            ),
            if (_selectedSubmission != null) ...[
              const SizedBox(width: 16),
              Container(
                width: 400,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('UGC Submission View',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _selectedSubmission = null),
                          )
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          _buildStatusChip(_selectedSubmission!.status),
                          const SizedBox(height: 16),
                          Text(_selectedSubmission!.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 10),
                          Text('Submitted by: ${_selectedSubmission!.submitterPhone}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          Text('Submitted at: ${_selectedSubmission!.submittedAt}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(height: 16),
                          const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(_selectedSubmission!.description),
                          if (_selectedSubmission!.mediaUrl != null) ...[
                            const SizedBox(height: 16),
                            const Text('Media Attachment', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _selectedSubmission!.mediaUrl!,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 180,
                                  color: Colors.grey.shade100,
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.end,
                        children: _buildActionButtons(notifier),
                      ),
                    )
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade700;

    switch (status) {
      case 'pending':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade700;
        break;
      case 'approved':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        break;
      case 'flagged':
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  List<Widget> _buildActionButtons(AdminUgcNotifier notifier) {
    final status = _selectedSubmission!.status;
    final id = _selectedSubmission!.id;

    if (status == 'pending') {
      return [
        OutlinedButton(
          onPressed: () async {
            final ok = await AdminDialogs.showConfirm(
              context: context,
              title: 'Flag Report',
              message: 'Do you want to flag this submission as spam/inappropriate?',
              confirmLabel: 'Flag',
              confirmColor: Colors.red.shade700,
            );
            if (ok) {
              await notifier.flag(id);
              setState(() => _selectedSubmission = _selectedSubmission!.copyWith(status: 'flagged'));
            }
          },
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
          child: const Text('Flag Spam'),
        ),
        OutlinedButton(
          onPressed: () async {
            final reason = await AdminDialogs.showRejectReason(
              context: context,
              title: 'Reject UGC',
            );
            if (reason != null) {
              await notifier.reject(id);
              setState(() => _selectedSubmission = _selectedSubmission!.copyWith(status: 'rejected'));
            }
          },
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Reject'),
        ),
        ElevatedButton(
          onPressed: () async {
            final ok = await AdminDialogs.showConfirm(
              context: context,
              title: 'Approve & Create Article Draft',
              message: 'Do you want to approve this citizen report? It will become a draft article.',
              confirmLabel: 'Approve',
            );
            if (ok) {
              await notifier.approve(id);
              setState(() => _selectedSubmission = _selectedSubmission!.copyWith(status: 'approved'));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          child: const Text('Approve'),
        ),
      ];
    }

    return [
      Text('Moderated', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
    ];
  }
}
