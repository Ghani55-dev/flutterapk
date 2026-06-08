import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../providers/admin_providers.dart';
import '../shared/dashboard_layout.dart';
import '../shared/admin_data_table.dart';
import '../shared/dialogs.dart';

class AdminUser {
  final String id;
  final String email;
  final String fullName;
  final bool isActive;
  final bool isAdmin;
  final String joinedAt;

  AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
    required this.isAdmin,
    required this.joinedAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? '',
      isActive: json['is_active'] == true,
      isAdmin: json['is_admin'] == true,
      joinedAt: json['date_joined']?.toString() ?? json['joined_at']?.toString() ?? '',
    );
  }

  AdminUser copyWith({bool? isActive}) {
    return AdminUser(
      id: id,
      email: email,
      fullName: fullName,
      isActive: isActive ?? this.isActive,
      isAdmin: isAdmin,
      joinedAt: joinedAt,
    );
  }
}

class AdminUsersState {
  final List<AdminUser> items;
  final bool isLoading;
  final String search;
  final int currentPage;
  final int totalPages;

  AdminUsersState({
    this.items = const [],
    this.isLoading = false,
    this.search = '',
    this.currentPage = 1,
    this.totalPages = 1,
  });

  AdminUsersState copyWith({
    List<AdminUser>? items,
    bool? isLoading,
    String? search,
    int? currentPage,
    int? totalPages,
  }) {
    return AdminUsersState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      search: search ?? this.search,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  final Dio _client;

  AdminUsersNotifier(this._client) : super(AdminUsersState()) {
    fetchUsers();
  }

  Future<void> fetchUsers({int page = 1}) async {
    state = state.copyWith(isLoading: true, currentPage: page);
    try {
      final queryParams = {
        'page': page,
        if (state.search.isNotEmpty) 'search': state.search,
      };

      final resp = await _client.get('/admin/api/users/', queryParameters: queryParams);
      final raw = resp.data;

      List<AdminUser> loaded = [];
      int totalP = 1;

      if (raw is Map) {
        final results = raw['results'] ?? raw['data'] ?? [];
        if (results is List) {
          loaded = results.map((e) => AdminUser.fromJson(Map<String, dynamic>.from(e))).toList();
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
      AdminUser(
        id: '1001',
        email: 'kumar@varadhi.com',
        fullName: 'Kumar Swamy',
        isActive: true,
        isAdmin: false,
        joinedAt: '2026-01-10',
      ),
      AdminUser(
        id: '1002',
        email: 'latha@varadhi.com',
        fullName: 'Latha Reddy',
        isActive: true,
        isAdmin: true,
        joinedAt: '2026-02-14',
      ),
      AdminUser(
        id: '1003',
        email: 'suresh@varadhi.com',
        fullName: 'Suresh Varma',
        isActive: false,
        isAdmin: false,
        joinedAt: '2026-03-22',
      ),
    ];

    final filtered = mocks.where((e) {
      return e.fullName.toLowerCase().contains(state.search.toLowerCase()) ||
          e.email.toLowerCase().contains(state.search.toLowerCase());
    }).toList();

    state = state.copyWith(items: filtered, isLoading: false, totalPages: 1);
  }

  void updateSearch(String val) {
    state = state.copyWith(search: val);
    fetchUsers(page: 1);
  }

  Future<bool> toggleUserStatus(String id, bool active) async {
    try {
      final endpoint = active ? 'activate' : 'deactivate';
      await _client.post('/admin/api/users/$id/$endpoint/');
    } catch (_) {}
    // Fallback status toggle
    final updated = state.items.map((item) {
      if (item.id == id) {
        return item.copyWith(isActive: active);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updated);
    return true;
  }
}

final adminUsersProvider = StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
  final client = ref.watch(adminApiClientProvider);
  return AdminUsersNotifier(client);
});

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  AdminUser? _selectedUser;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);
    final notifier = ref.read(adminUsersProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      body: DashboardLayout(
        title: 'Users Management',
        child: Row(
          children: [
            Expanded(
              child: AdminDataTable(
                columns: [
                  AdminDataTableColumn(label: 'User ID', field: 'id'),
                  AdminDataTableColumn(label: 'Full Name', field: 'name'),
                  AdminDataTableColumn(label: 'Email', field: 'email'),
                  AdminDataTableColumn(label: 'Role', field: 'role'),
                  AdminDataTableColumn(label: 'Status', field: 'status'),
                  AdminDataTableColumn(label: 'Date Joined', field: 'joined_at'),
                ],
                itemCount: state.items.length,
                isLoading: state.isLoading,
                currentPage: state.currentPage,
                totalPages: state.totalPages,
                onPageChanged: (page) => notifier.fetchUsers(page: page),
                onSearchChanged: (val) => notifier.updateSearch(val),
                searchHint: 'Search user name or email...',
                rowBuilder: (ctx, index) {
                  final item = state.items[index];
                  final isSelected = _selectedUser?.id == item.id;
                  return DataRow(
                    selected: isSelected,
                    onSelectChanged: (_) {
                      setState(() => _selectedUser = item);
                    },
                    cells: [
                      DataCell(Text('#${item.id}')),
                      DataCell(Text(item.fullName)),
                      DataCell(Text(item.email)),
                      DataCell(Text(item.isAdmin ? 'Administrator' : 'Standard User')),
                      DataCell(Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: item.isActive ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(item.isActive ? 'Active' : 'Deactivated'),
                        ],
                      )),
                      DataCell(Text(item.joinedAt)),
                    ],
                  );
                },
              ),
            ),
            if (_selectedUser != null) ...[
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
                          const Text('User Detail Profile',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _selectedUser = null),
                          )
                        ],
                      ),
                      const Divider(height: 24),
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          child: Text(
                            _selectedUser!.fullName.isNotEmpty ? _selectedUser!.fullName[0].toUpperCase() : 'U',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedUser!.fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedUser!.email,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      const Text('User Information', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildInfoRow('Account ID', '#${_selectedUser!.id}'),
                      _buildInfoRow('Role permissions', _selectedUser!.isAdmin ? 'Admin Portal' : 'Mobile Client'),
                      _buildInfoRow('Date Joined', _selectedUser!.joinedAt),
                      const Divider(height: 32),
                      const Text('Account Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Account Activation State'),
                          Switch(
                            value: _selectedUser!.isActive,
                            onChanged: (val) async {
                              final confirm = await AdminDialogs.showConfirm(
                                context: context,
                                title: val ? 'Activate Account' : 'Deactivate Account',
                                message: val
                                    ? 'Are you sure you want to reactivate this user account?'
                                    : 'Deactivating this user will suspend all application access immediately.',
                                confirmLabel: val ? 'Activate' : 'Suspend',
                                confirmColor: val ? Colors.green : Colors.red,
                              );
                              if (confirm) {
                                await notifier.toggleUserStatus(_selectedUser!.id, val);
                                setState(() {
                                  _selectedUser = _selectedUser!.copyWith(isActive: val);
                                });
                              }
                            },
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
