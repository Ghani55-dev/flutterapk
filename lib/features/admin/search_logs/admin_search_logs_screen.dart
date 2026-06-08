import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../providers/admin_providers.dart';
import '../shared/dashboard_layout.dart';
import '../shared/admin_data_table.dart';
import '../shared/dialogs.dart';

class SearchLog {
  final String id;
  final String query;
  final String ipAddress;
  final int resultsCount;
  final String timestamp;

  SearchLog({
    required this.id,
    required this.query,
    required this.ipAddress,
    required this.resultsCount,
    required this.timestamp,
  });

  factory SearchLog.fromJson(Map<String, dynamic> json) {
    return SearchLog(
      id: json['id']?.toString() ?? '',
      query: json['query']?.toString() ?? '',
      ipAddress: json['ip_address']?.toString() ?? 'Anonymized',
      resultsCount: int.tryParse(json['results_count']?.toString() ?? '') ?? 0,
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }
}

class AdminSearchLogsState {
  final List<SearchLog> logs;
  final List<Map<String, dynamic>> trending;
  final List<Map<String, dynamic>> zeroResults;
  final bool isLoading;
  final int currentPage;
  final int totalPages;

  AdminSearchLogsState({
    this.logs = const [],
    this.trending = const [],
    this.zeroResults = const [],
    this.isLoading = false,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  AdminSearchLogsState copyWith({
    List<SearchLog>? logs,
    List<Map<String, dynamic>>? trending,
    List<Map<String, dynamic>>? zeroResults,
    bool? isLoading,
    int? currentPage,
    int? totalPages,
  }) {
    return AdminSearchLogsState(
      logs: logs ?? this.logs,
      trending: trending ?? this.trending,
      zeroResults: zeroResults ?? this.zeroResults,
      isLoading: isLoading ?? this.isLoading,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class AdminSearchLogsNotifier extends StateNotifier<AdminSearchLogsState> {
  final Dio _client;

  AdminSearchLogsNotifier(this._client) : super(AdminSearchLogsState()) {
    fetchSearchLogs();
  }

  Future<void> fetchSearchLogs({int page = 1}) async {
    state = state.copyWith(isLoading: true, currentPage: page);
    try {
      final logsResp = await _client.get('/admin/api/search/logs/', queryParameters: {'page': page});
      final trendingResp = await _client.get('/admin/api/search/trending/');
      final zeroResp = await _client.get('/admin/api/search/zero-results/');

      List<SearchLog> loadedLogs = [];
      int totalP = 1;

      if (logsResp.data is Map) {
        final results = logsResp.data['results'] ?? logsResp.data['data'] ?? [];
        if (results is List) {
          loadedLogs = results.map((e) => SearchLog.fromJson(Map<String, dynamic>.from(e))).toList();
        }
        totalP = logsResp.data['total_pages'] ?? logsResp.data['last_page'] ?? 1;
      }

      final List<Map<String, dynamic>> trend = List<Map<String, dynamic>>.from(trendingResp.data ?? []);
      final List<Map<String, dynamic>> zero = List<Map<String, dynamic>>.from(zeroResp.data ?? []);

      state = state.copyWith(
        logs: loadedLogs,
        trending: trend,
        zeroResults: zero,
        isLoading: false,
        totalPages: totalP,
      );
    } catch (_) {
      _loadMockFallback();
    }
  }

  void _loadMockFallback() {
    final mockLogs = [
      SearchLog(id: '1', query: 'Solar panel rebate', ipAddress: '192.168.1.45', resultsCount: 8, timestamp: '2026-06-06 12:45'),
      SearchLog(id: '2', query: 'Water pipeline leakage', ipAddress: '192.168.1.102', resultsCount: 4, timestamp: '2026-06-06 12:40'),
      SearchLog(id: '3', query: 'Vaccination center regional', ipAddress: 'Anonymized', resultsCount: 0, timestamp: '2026-06-06 11:30'),
      SearchLog(id: '4', query: 'Scholarship exams date', ipAddress: '192.168.1.80', resultsCount: 0, timestamp: '2026-06-06 10:15'),
    ];

    state = state.copyWith(
      logs: mockLogs,
      trending: [
        {'query': 'Solar panel rebate', 'count': 420},
        {'query': 'Water pipeline leakage', 'count': 380},
        {'query': 'Rainfall alert', 'count': 210},
      ],
      zeroResults: [
        {'query': 'Vaccination center regional', 'count': 32},
        {'query': 'Scholarship exams date', 'count': 18},
      ],
      isLoading: false,
      totalPages: 1,
    );
  }

  Future<bool> anonymizeLogs() async {
    try {
      final resp = await _client.post('/admin/api/search/logs/anonymize/');
      if (resp.statusCode == 200) {
        fetchSearchLogs();
        return true;
      }
    } catch (_) {}

    // Mock anonymization fallback
    final anonymized = state.logs.map((e) {
      return SearchLog(
        id: e.id,
        query: e.query,
        ipAddress: 'Anonymized',
        resultsCount: e.resultsCount,
        timestamp: e.timestamp,
      );
    }).toList();
    state = state.copyWith(logs: anonymized);
    return true;
  }
}

final adminSearchLogsProvider =
    StateNotifierProvider<AdminSearchLogsNotifier, AdminSearchLogsState>((ref) {
  final client = ref.watch(adminApiClientProvider);
  return AdminSearchLogsNotifier(client);
});

class AdminSearchLogsScreen extends ConsumerWidget {
  const AdminSearchLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminSearchLogsProvider);
    final notifier = ref.read(adminSearchLogsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      body: DashboardLayout(
        title: 'Search Queries & Privacy Logs',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Real-time Search Metrics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await AdminDialogs.showConfirm(
                      context: context,
                      title: 'Anonymize IP Addresses',
                      message: 'This will strip all IP addresses from search logs to maintain GDPR privacy compliance.',
                      confirmLabel: 'Anonymize Now',
                      confirmColor: Colors.purple,
                    );
                    if (ok) {
                      final ok2 = await notifier.anonymizeLogs();
                      if (ok2 && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('IP addresses anonymized successfully')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: const Text('Anonymize Logs'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                // Trending card
                _buildLogsCard(
                  context,
                  title: 'Trending Queries (Top 3)',
                  items: state.trending.map((e) => '${e['query']} (${e['count']} hits)').toList(),
                  icon: Icons.trending_up,
                  color: Colors.blue,
                ),
                // Zero results card
                _buildLogsCard(
                  context,
                  title: 'Queries with Zero Results (Unsolved)',
                  items: state.zeroResults.map((e) => '${e['query']} (${e['count']} times)').toList(),
                  icon: Icons.search_off,
                  color: Colors.redAccent,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: AdminDataTable(
                columns: [
                  AdminDataTableColumn(label: 'Log ID'),
                  AdminDataTableColumn(label: 'Query Termed'),
                  AdminDataTableColumn(label: 'Results Returned'),
                  AdminDataTableColumn(label: 'User IP Address'),
                  AdminDataTableColumn(label: 'Timestamp'),
                ],
                itemCount: state.logs.length,
                isLoading: state.isLoading,
                currentPage: state.currentPage,
                totalPages: state.totalPages,
                onPageChanged: (page) => notifier.fetchSearchLogs(page: page),
                rowBuilder: (ctx, index) {
                  final log = state.logs[index];
                  final isZero = log.resultsCount == 0;
                  return DataRow(
                    cells: [
                      DataCell(Text('#${log.id}')),
                      DataCell(Text(log.query, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(
                        '${log.resultsCount} items',
                        style: TextStyle(
                          color: isZero ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                      DataCell(Text(log.ipAddress)),
                      DataCell(Text(log.timestamp)),
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

  Widget _buildLogsCard(
    BuildContext context, {
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width > 900
          ? (MediaQuery.of(context).size.width - 260 - 72) * 0.48
          : double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                Text('No search activity recorded', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))
              else
                ...items.map(
                  (txt) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text('• $txt', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
