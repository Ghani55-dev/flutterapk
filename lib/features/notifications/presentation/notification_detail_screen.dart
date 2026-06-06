import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/notification_providers.dart';
import '../data/notification_models.dart';

class NotificationDetailScreen extends ConsumerStatefulWidget {
  final String id;
  final NotificationInboxItem? initialItem;

  const NotificationDetailScreen({super.key, required this.id, this.initialItem});

  @override
  ConsumerState<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends ConsumerState<NotificationDetailScreen> {
  late final Future<NotificationInboxItem> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = ref.read(notificationRepositoryProvider).fetchNotification(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification')),
      body: FutureBuilder<NotificationInboxItem>(
        future: _detailFuture,
        initialData: widget.initialItem,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return _DetailError(message: snapshot.error.toString());
          }

          final item = snapshot.data;
          if (item == null) return const _DetailEmpty();
          return _NotificationDetailBody(item: item);
        },
      ),
    );
  }
}

class _NotificationDetailBody extends StatelessWidget {
  final NotificationInboxItem item;

  const _NotificationDetailBody({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.notifications_active_outlined, size: 42, color: colors.onPrimaryContainer),
        ),
        const SizedBox(height: 20),
        Text(item.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        if (item.createdAt != null) ...[
          const SizedBox(height: 8),
          Text(
            item.createdAt!.toLocal().toString().split('.').first,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
        if (item.body.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(item.body, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45)),
        ],
        if (item.deepLink?.isNotEmpty == true) ...[
          const SizedBox(height: 20),
          Text('Link: ${item.deepLink}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ],
    );
  }
}

class _DetailError extends StatelessWidget {
  final String message;

  const _DetailError({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.error)),
      ),
    );
  }
}

class _DetailEmpty extends StatelessWidget {
  const _DetailEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Notification not found'));
  }
}
