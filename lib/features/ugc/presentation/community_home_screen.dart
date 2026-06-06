import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CommunityHomeScreen extends StatelessWidget {
  const CommunityHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Community Reporter')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.campaign_rounded, size: 44, color: colors.onPrimaryContainer),
                const SizedBox(height: 14),
                Text('Report local news with VARADHI', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: colors.onPrimaryContainer)),
                const SizedBox(height: 8),
                Text('Share verified village, district, and city updates. Reports are reviewed before they appear to readers.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onPrimaryContainer)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle('How reporting works'),
          _InfoRow(icon: Icons.verified_user_outlined, title: 'Verify phone', body: 'OTP verification helps protect the community feed.'),
          _InfoRow(icon: Icons.edit_note_rounded, title: 'Submit evidence', body: 'Add title, description, location, category, and optional media.'),
          _InfoRow(icon: Icons.fact_check_outlined, title: 'Editorial review', body: 'Submissions may be approved, held, or flagged for review.'),
          const SizedBox(height: 18),
          _SectionTitle('Trust levels'),
          _TrustLevels(),
          const SizedBox(height: 18),
          _SectionTitle('Benefits'),
          const _Benefit(text: 'Build credibility as a local reporter'),
          const _Benefit(text: 'Help your area get faster coverage'),
          const _Benefit(text: 'Support verified community updates'),
          const SizedBox(height: 22),
          FilledButton.icon(onPressed: () => context.push('/community/otp'), icon: const Icon(Icons.mobile_friendly), label: const Text('Start Reporting')),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => context.push('/community/feed'), icon: const Icon(Icons.dynamic_feed_outlined), label: const Text('View Community Feed')),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoRow({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(body, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustLevels extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _TrustChip(label: 'New')),
        SizedBox(width: 8),
        Expanded(child: _TrustChip(label: 'Trusted')),
        SizedBox(width: 8),
        Expanded(child: _TrustChip(label: 'Verified')),
      ],
    );
  }
}

class _TrustChip extends StatelessWidget {
  final String label;
  const _TrustChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
      child: Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
    );
  }
}

class _Benefit extends StatelessWidget {
  final String text;
  const _Benefit({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Expanded(child: Text(text))]),
    );
  }
}
