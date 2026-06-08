import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/admin_providers.dart';
import '../shared/dashboard_layout.dart';

// Providers for dashboard stats
final adminDashboardSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.watch(adminApiClientProvider);
  final resp = await client.get('/admin/api/dashboard/summary/');
  final data = resp.data;
  
  if (data is Map && data['data'] is Map) {
    final summaryData = Map<String, dynamic>.from(data['data'] as Map);
    
    // Extract and map the data structure
    final users = summaryData['users'] as Map<String, dynamic>? ?? {};
    final articles = summaryData['articles'] as Map<String, dynamic>? ?? {};
    final ugc = summaryData['ugc'] as Map<String, dynamic>? ?? {};
    final liveNews = summaryData['live_news'] as Map<String, dynamic>? ?? {};
    final notifications = summaryData['notifications'] as Map<String, dynamic>? ?? {};
    
    return {
      'total_users': users['total'] ?? 0,
      'total_articles': articles['total'] ?? 0,
      'pending_ugc': ugc['total'] ?? 0,
      'live_news_count': liveNews['active'] ?? 0,
      'total_notifications': notifications['total'] ?? 0,
      'daily_active_users': users['active'] ?? 0,
    };
  }
  
  throw Exception('Invalid response format');
});

final adminDashboardQueuesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(adminApiClientProvider);
  final resp = await client.get('/admin/api/dashboard/queues/');
  final data = resp.data;
  
  if (data is Map && data['data'] is Map) {
    final queuesData = Map<String, dynamic>.from(data['data'] as Map);
    
    final queues = <Map<String, dynamic>>[];
    
    // Articles queue
    if (queuesData['articles'] is Map) {
      final articles = Map<String, dynamic>.from(queuesData['articles'] as Map);
      final inReview = articles['in_review'] as int? ?? 0;
      if (inReview > 0) {
        queues.add({
          'name': 'Article Moderation',
          'pending': inReview,
          'status_key': 'in_review',
        });
      }
    }
    
    // UGC queue
    if (queuesData['ugc'] is Map) {
      final ugc = Map<String, dynamic>.from(queuesData['ugc'] as Map);
      final underReview = (ugc['UNDER_REVIEW'] as int? ?? 0) + (ugc['PENDING_REVIEW'] as int? ?? 0);
      if (underReview > 0 || (ugc['PENDING'] as int? ?? 0) > 0) {
        queues.add({
          'name': 'UGC Verification',
          'pending': underReview > 0 ? underReview : (ugc['PENDING'] as int? ?? 0),
          'status_key': 'ugc',
        });
      }
    }
    
    // Live news queue
    if (queuesData['live_news'] is Map) {
      final liveNews = Map<String, dynamic>.from(queuesData['live_news'] as Map);
      final active = liveNews['active'] as int? ?? 0;
      queues.add({
        'name': 'Live News Active',
        'pending': active,
        'status_key': 'live_news',
      });
    }
    
    // Notifications queue
    if (queuesData['notifications'] is Map) {
      final notifs = Map<String, dynamic>.from(queuesData['notifications'] as Map);
      final processing = (notifs['processing'] as int? ?? 0) + (notifs['failed'] as int? ?? 0);
      if (processing > 0 || (notifs['pending'] as int? ?? 0) > 0) {
        queues.add({
          'name': 'Notification Dispatch',
          'pending': processing > 0 ? processing : (notifs['pending'] as int? ?? 0),
          'status_key': 'notifications',
        });
      }
    }
    
    return queues;
  }
  
  throw Exception('Invalid response format');
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(adminDashboardSummaryProvider);
    final queuesAsync = ref.watch(adminDashboardQueuesProvider);
    final theme = Theme.of(context);

    return DashboardLayout(
      title: 'Dashboard Overview',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Metric Cards
            summaryAsync.when(
              loading: () => const _MetricsSkeleton(),
              error: (err, st) {
                debugPrint('Summary fetch error: $err\n$st');
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Failed to load dashboard summary', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(err.toString(), style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
              data: (data) => _buildMetricsGrid(context, data),
            ),
            const SizedBox(height: 24),

            // Charts & Queues row
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                // Analytics Line Chart
                SizedBox(
                  width: MediaQuery.of(context).size.width > 1200
                      ? (MediaQuery.of(context).size.width - 260 - 72) * 0.65
                      : double.infinity,
                  height: 380,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Engagement & Activity (Last 7 Days)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: LineChart(
                              LineChartData(
                                gridData: const FlGridData(show: true, drawVerticalLine: false),
                                titlesData: FlTitlesData(
                                  show: true,
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (val, meta) {
                                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                        final idx = val.toInt();
                                        if (idx >= 0 && idx < days.length) {
                                          return Text(days[idx], style: const TextStyle(fontSize: 11));
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                minX: 0,
                                maxX: 6,
                                minY: 0,
                                maxY: 10,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: const [
                                      FlSpot(0, 3),
                                      FlSpot(1, 4.5),
                                      FlSpot(2, 4),
                                      FlSpot(3, 6.5),
                                      FlSpot(4, 5.8),
                                      FlSpot(5, 8),
                                      FlSpot(6, 9.5),
                                    ],
                                    isCurved: true,
                                    color: theme.colorScheme.primary,
                                    barWidth: 4,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: theme.colorScheme.primary.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Pending Queues Table
                SizedBox(
                  width: MediaQuery.of(context).size.width > 1200
                      ? (MediaQuery.of(context).size.width - 260 - 72) * 0.31
                      : double.infinity,
                  height: 380,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Work Queues',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: queuesAsync.when(
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, _) => const Center(child: Text('Error loading queues')),
                              data: (queues) => queues.isEmpty
                                  ? const Center(child: Text('All queues cleared'))
                                  : ListView.separated(
                                      itemCount: queues.length,
                                      separatorBuilder: (_, __) => const Divider(),
                                      itemBuilder: (ctx, i) {
                                        final q = queues[i];
                                        final pending = q['pending'] as int;
                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(q['name'].toString(),
                                              style: const TextStyle(fontWeight: FontWeight.w600)),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: pending > 0
                                                  ? Colors.amber.shade100
                                                  : Colors.green.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              pending.toString(),
                                              style: TextStyle(
                                                color: pending > 0
                                                    ? Colors.amber.shade900
                                                    : Colors.green.shade900,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, Map<String, dynamic> data) {
    final items = [
      _MetricItem(
        label: 'Total Active Users',
        value: data['total_users'].toString(),
        icon: Icons.people_outline,
        color: Colors.blue,
      ),
      _MetricItem(
        label: 'Total Published Articles',
        value: data['total_articles'].toString(),
        icon: Icons.article_outlined,
        color: const Color(0xFF10B981),
      ),
      _MetricItem(
        label: 'Pending UGC Submissions',
        value: data['pending_ugc'].toString(),
        icon: Icons.rate_review_outlined,
        color: Colors.amber,
      ),
      _MetricItem(
        label: 'Notifications Broadcasted',
        value: data['total_notifications'].toString(),
        icon: Icons.notifications_none,
        color: Colors.purple,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100
            ? 4
            : (constraints.maxWidth > 700 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
          ),
          itemCount: items.length,
          itemBuilder: (ctx, idx) {
            final m = items[idx];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: m.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(m.icon, color: m.color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            m.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.value,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MetricItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _MetricsSkeleton extends StatelessWidget {
  const _MetricsSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100 ? 4 : (constraints.maxWidth > 700 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
          ),
          itemCount: 4,
          itemBuilder: (ctx, idx) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 100, height: 12, color: Colors.grey.shade100),
                        const SizedBox(height: 8),
                        Container(width: 60, height: 20, color: Colors.grey.shade100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
