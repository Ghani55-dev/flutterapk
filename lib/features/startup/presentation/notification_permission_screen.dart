import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/config/app_config.dart';

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() => _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState extends State<NotificationPermissionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _allow() async {
    setState(() => _busy = true);
    await Permission.notification.request();
    if (!mounted) return;
    context.go('/guest-home');
  }

  void _skip() => context.go('/guest-home');

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppConfig.appName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Container(
                    height: 170,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: colors.primary.withAlpha(18),
                    ),
                    child: Center(
                      child: Transform.scale(
                        scale: 1 + (_controller.value * 0.1),
                        child: Icon(Icons.notifications_active_rounded, size: 78, color: colors.primary),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                'Breaking news alerts',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Text(
                'Enable alerts for major local updates, live bulletins, and community news. You can change this later in settings.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy ? null : _allow,
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.notifications_rounded),
                label: const Text('Allow Notifications'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _busy ? null : _skip,
                style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Not Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
