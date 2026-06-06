import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/bookmarks_providers.dart';
import '../../../providers/core_providers.dart';
import '../../../providers/profile_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../auth/auth_controller.dart';
import '../../home/presentation/widgets/shimmer.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileNotifierProvider.notifier).loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileNotifierProvider);
    final profile = state.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile Center')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(profileNotifierProvider.notifier).loadProfile(),
        child: state.loading && profile == null
            ? const _ProfileSkeleton()
            : state.error != null && profile == null
                ? _ProfileError(message: state.error!, onRetry: () => ref.read(profileNotifierProvider.notifier).loadProfile())
                : ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      _ProfileHeader(
                        avatarUrl: profile?.avatarUrl,
                        name: profile?.displayName.isNotEmpty == true ? profile!.displayName : 'VARADHI Reader',
                        email: profile?.email.isNotEmpty == true ? profile!.email : 'Email unavailable',
                        contributorBadge: profile?.contributorBadge,
                        onEdit: () => context.push('/profile/edit'),
                      ),
                      const SizedBox(height: 16),
                      _ProfileAction(icon: Icons.tune_rounded, title: 'Preferences', subtitle: 'Language, theme, font size, location', onTap: () => context.push('/profile/preferences')),
                      _ProfileAction(icon: Icons.bookmark_rounded, title: 'Bookmarks', subtitle: 'Saved stories and articles', onTap: () => context.push('/bookmarks')),
                      _ProfileAction(icon: Icons.campaign_outlined, title: 'Community Reporter', subtitle: 'Submit verified local news', onTap: () => context.push('/community')),
                      const SizedBox(height: 18),
                      FilledButton.tonalIcon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                      ),
                    ],
                  ),
      ),
    );
  }

  Future<void> _logout() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete('pref_theme');
    await storage.delete('pref_lang');
    await storage.delete('pref_notif');
    await storage.delete('pref_font_size');
    ref.invalidate(profileNotifierProvider);
    ref.invalidate(settingsNotifierProvider);
    ref.invalidate(bookmarksNotifierProvider);
    await ref.read(authNotifierProvider.notifier).logout();
    if (mounted) context.go('/login');
  }
}

class _ProfileHeader extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final String email;
  final String? contributorBadge;
  final VoidCallback onEdit;

  const _ProfileHeader({required this.avatarUrl, required this.name, required this.email, required this.contributorBadge, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(url: avatarUrl, size: 76),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: colors.onPrimaryContainer)),
                    const SizedBox(height: 4),
                    Text(email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onPrimaryContainer)),
                    if (contributorBadge?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(999)),
                        child: Text(contributorBadge!, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined), label: const Text('Edit Profile')),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final double size;

  const _Avatar({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (url?.isNotEmpty == true) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(width: size, height: size, color: colors.surfaceVariant),
          errorWidget: (_, __, ___) => _AvatarFallback(size: size),
        ),
      );
    }
    return _AvatarFallback(size: size);
  }
}

class _AvatarFallback extends StatelessWidget {
  final double size;

  const _AvatarFallback({required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: colors.surface, shape: BoxShape.circle),
      child: Icon(Icons.person_rounded, size: size * 0.48, color: colors.primary),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileAction({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        ShimmerPlaceholder(width: double.infinity, height: 172),
        const SizedBox(height: 18),
        ShimmerPlaceholder(width: double.infinity, height: 72),
        const SizedBox(height: 10),
        ShimmerPlaceholder(width: double.infinity, height: 72),
        const SizedBox(height: 10),
        ShimmerPlaceholder(width: double.infinity, height: 72),
      ],
    );
  }
}

class _ProfileError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ProfileError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.error_outline_rounded, size: 56, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 12),
        Text('Unable to load profile', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ],
    );
  }
}
