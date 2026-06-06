import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';

class StartupErrorScreen extends StatelessWidget {
  final String? message;

  const StartupErrorScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF12151C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withAlpha(28),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.redAccent.withAlpha(90)),
                ),
                child: const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 38),
              ),
              const SizedBox(height: 24),
              Text(
                'VARADHI is taking a short pause',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                message ?? 'We could not verify the news service health. Please try again.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => context.go('/splash'),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const Spacer(),
              Text(
                '${AppConfig.appName} v${AppConfig.appVersion}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
