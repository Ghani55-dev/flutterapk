import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/admin_providers.dart';
import 'admin_theme.dart';

class DashboardLayout extends ConsumerWidget {
  final Widget child;
  final String title;

  const DashboardLayout({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 960;
    final theme = Theme.of(context);

    // Current route location matching
    final state = GoRouterState.of(context);
    final currentPath = state.location;

    final menuItems = [
      _MenuEntry(icon: Icons.dashboard, label: 'Dashboard', path: '/admin/dashboard'),
      _MenuEntry(icon: Icons.article, label: 'Articles', path: '/admin/articles'),
      _MenuEntry(icon: Icons.rate_review, label: 'UGC Moderation', path: '/admin/ugc'),
      _MenuEntry(icon: Icons.people, label: 'Users', path: '/admin/users'),
      _MenuEntry(icon: Icons.analytics, label: 'Analytics', path: '/admin/analytics'),
      _MenuEntry(icon: Icons.notifications, label: 'Notifications', path: '/admin/notifications'),
      _MenuEntry(icon: Icons.poll, label: 'Polls', path: '/admin/polls'),
      _MenuEntry(icon: Icons.picture_as_pdf, label: 'E-Papers', path: '/admin/epapers'),
      _MenuEntry(icon: Icons.search_off, label: 'Search Logs', path: '/admin/search-logs'),
      _MenuEntry(icon: Icons.wysiwyg, label: 'CMS Pages', path: '/admin/cms'),
      _MenuEntry(icon: Icons.format_quote, label: 'Quotes', path: '/admin/quotes'),
      _MenuEntry(icon: Icons.dns, label: 'System Health', path: '/admin/system'),
    ];

    Widget buildSidebar() {
      return Container(
        width: 260,
        color: theme.brightness == Brightness.light ? Colors.white : const Color(0xFF1E293B),
        child: Column(
          children: [
            // Admin Logo / Brand Header
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.brightness == Brightness.light
                        ? Colors.grey.shade200
                        : Colors.grey.shade800,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.security, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'VARADHI ADMIN',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                children: [
                  ...menuItems.map((item) {
                    final selected = currentPath == item.path ||
                        (item.path != '/admin/dashboard' && currentPath.startsWith(item.path));
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        leading: Icon(
                          item.icon,
                          color: selected ? theme.colorScheme.primary : Colors.grey.shade500,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            color: selected
                                ? theme.colorScheme.primary
                                : (theme.brightness == Brightness.light
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300),
                          ),
                        ),
                        selected: selected,
                        selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onTap: () {
                          if (isMobile) {
                            Navigator.of(context).pop(); // Dismiss drawer
                          }
                          context.go(item.path);
                        },
                      ),
                    );
                  }),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.redAccent),
                      title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () {
                        ref.read(adminAuthNotifierProvider.notifier).logout();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Theme(
      data: theme.brightness == Brightness.light ? AdminTheme.light() : AdminTheme.dark(),
      child: Scaffold(
        drawer: isMobile ? Drawer(child: buildSidebar()) : null,
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          leading: isMobile
              ? Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                )
              : null,
          actions: [
            // Dark mode Toggle
            IconButton(
              icon: Icon(
                theme.brightness == Brightness.light ? Icons.dark_mode : Icons.light_mode,
              ),
              onPressed: () {
                // If the app has theme provider we toggle it, or just use system switcher.
                // We'll show a snackbar or implement quick toggle if needed.
              },
            ),
            const SizedBox(width: 8),
            // Profile display
            ref.watch(adminAuthNotifierProvider).user != null
                ? Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          (ref.read(adminAuthNotifierProvider).user?['full_name'] ?? 'A')[0]
                              .toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isMobile)
                        Text(
                          ref.read(adminAuthNotifierProvider).user?['full_name'] ?? 'Admin',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      const SizedBox(width: 16),
                    ],
                  )
                : const SizedBox.shrink(),
          ],
        ),
        body: Row(
          children: [
            if (!isMobile) buildSidebar(),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(isMobile ? 12 : 24),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuEntry {
  final IconData icon;
  final String label;
  final String path;

  _MenuEntry({
    required this.icon,
    required this.label,
    required this.path,
  });
}
