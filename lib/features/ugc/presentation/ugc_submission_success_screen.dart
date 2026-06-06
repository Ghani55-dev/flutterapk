import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/ugc_models.dart';

class UGCSubmissionSuccessScreen extends StatelessWidget {
  final UGCSubmissionResult? result;

  const UGCSubmissionSuccessScreen({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final flagged = result?.flaggedForReview == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Submitted')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(color: flagged ? colors.errorContainer : colors.primaryContainer, shape: BoxShape.circle),
                child: Icon(flagged ? Icons.flag_outlined : Icons.check_circle_outline, size: 56, color: flagged ? colors.onErrorContainer : colors.onPrimaryContainer),
              ),
              const SizedBox(height: 22),
              Text('Submitted', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                flagged ? 'Flagged For Review' : 'Under Review',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: flagged ? colors.error : colors.primary),
              ),
              const SizedBox(height: 12),
              Text(
                'VARADHI will review your community report before it appears in the feed.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => context.go('/community/feed'), child: const Text('View Community Feed')),
              const SizedBox(height: 8),
              TextButton(onPressed: () => context.go('/'), child: const Text('Back to Home')),
            ],
          ),
        ),
      ),
    );
  }
}
