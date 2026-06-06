import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/ugc_providers.dart';

class UGCMediaUploadScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> draft;

  const UGCMediaUploadScreen({super.key, required this.draft});

  @override
  ConsumerState<UGCMediaUploadScreen> createState() => _UGCMediaUploadScreenState();
}

class _UGCMediaUploadScreenState extends ConsumerState<UGCMediaUploadScreen> {
  final _pathCtrl = TextEditingController();

  @override
  void dispose() {
    _pathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ugcProvider);
    final notifier = ref.read(ugcProvider.notifier);
    final contentType = widget.draft['content_type']?.toString() ?? 'image';
    final hasDraft = widget.draft['title'] != null && widget.draft['description'] != null && widget.draft['category'] != null && widget.draft['location'] is Map;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Media')),
      body: !hasDraft
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_note_rounded, size: 56),
                    const SizedBox(height: 12),
                    Text('Start with report details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    const Text('Media upload needs a report draft first.', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: () => context.go('/community/submit'), child: const Text('Create Report')),
                  ],
                ),
              ),
            )
          : ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text('Add evidence', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Paste a local image or video file path from this device. Upload progress and backend processing status will appear below.'),
          const SizedBox(height: 18),
          TextField(
            controller: _pathCtrl,
            decoration: InputDecoration(
              labelText: contentType == 'image' ? 'Image file path' : 'Video file path',
              prefixIcon: const Icon(Icons.attach_file),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: state.uploadStatus == 'PROCESSING'
                ? null
                : () => notifier.uploadMedia(filePath: _pathCtrl.text.trim(), contentType: contentType),
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Upload Media'),
          ),
          const SizedBox(height: 18),
          _UploadStatusCard(progress: state.uploadProgress, status: state.uploadStatus, error: state.uploadError),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: state.submitting || state.uploadStatus == 'PROCESSING'
                ? null
                : () async {
                    final result = await notifier.submit(
                      title: widget.draft['title'] as String,
                      description: widget.draft['description'] as String,
                      category: widget.draft['category'] as String,
                      location: Map<String, String>.from(widget.draft['location'] as Map),
                      contentType: contentType,
                    );
                    if (!mounted || result == null) return;
                    context.go('/community/success', extra: result);
                  },
            child: state.submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit Report'),
          ),
          if (state.submissionError != null) ...[
            const SizedBox(height: 12),
            Text(state.submissionError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}

class _UploadStatusCard extends StatelessWidget {
  final double progress;
  final String status;
  final String? error;

  const _UploadStatusCard({required this.progress, required this.status, this.error});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = status == 'FAILED' ? colors.error : colors.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(status == 'FAILED' ? Icons.error_outline : Icons.hourglass_top_rounded, color: statusColor),
              const SizedBox(width: 8),
              Text(status, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: statusColor)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress.clamp(0, 1).toDouble()),
          const SizedBox(height: 8),
          Text('${(progress.clamp(0, 1).toDouble() * 100).round()}% uploaded'),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: TextStyle(color: colors.error)),
          ],
        ],
      ),
    );
  }
}
