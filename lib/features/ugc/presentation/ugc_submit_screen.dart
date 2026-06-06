import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../location/location_provider.dart';
import '../../../providers/ugc_providers.dart';

class UGCSubmitScreen extends ConsumerStatefulWidget {
  const UGCSubmitScreen({super.key});

  @override
  ConsumerState<UGCSubmitScreen> createState() => _UGCSubmitScreenState();
}

class _UGCSubmitScreenState extends ConsumerState<UGCSubmitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  String _category = 'local';
  String _contentType = 'image';

  @override
  void initState() {
    super.initState();
    Future.microtask(_prefillLocation);
  }

  Future<void> _prefillLocation() async {
    final locAv = ref.read(locationProvider);
    final loc = locAv.valueOrNull;
    if (loc == null || !mounted) return;
    _stateCtrl.text = loc['state'] ?? '';
    _districtCtrl.text = loc['district'] ?? '';
    _villageCtrl.text = loc['village'] ?? loc['city'] ?? '';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _stateCtrl.dispose();
    _districtCtrl.dispose();
    _villageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ugcProvider);
    final notifier = ref.read(ugcProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Submit News')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text('What happened?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title'), validator: _required),
            const SizedBox(height: 12),
            TextFormField(controller: _descCtrl, minLines: 4, maxLines: 7, decoration: const InputDecoration(labelText: 'Description'), validator: _required),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'local', child: Text('Local')),
                DropdownMenuItem(value: 'civic', child: Text('Civic')),
                DropdownMenuItem(value: 'crime', child: Text('Crime')),
                DropdownMenuItem(value: 'weather', child: Text('Weather')),
                DropdownMenuItem(value: 'event', child: Text('Event')),
              ],
              onChanged: (value) => setState(() => _category = value ?? _category),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _contentType,
              decoration: const InputDecoration(labelText: 'Content Type'),
              items: const [
                DropdownMenuItem(value: 'image', child: Text('Image')),
                DropdownMenuItem(value: 'video', child: Text('Video')),
                DropdownMenuItem(value: 'short_video', child: Text('Short Video')),
              ],
              onChanged: (value) => setState(() => _contentType = value ?? _contentType),
            ),
            const SizedBox(height: 18),
            Text('Location', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TextFormField(controller: _stateCtrl, decoration: const InputDecoration(labelText: 'State'), validator: _required),
            const SizedBox(height: 12),
            TextFormField(controller: _districtCtrl, decoration: const InputDecoration(labelText: 'District'), validator: _required),
            const SizedBox(height: 12),
            TextFormField(controller: _villageCtrl, decoration: const InputDecoration(labelText: 'Village / City'), validator: _required),
            if (state.submissionError != null) ...[
              const SizedBox(height: 12),
              Text(state.submissionError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                final draft = _draft();
                if (draft == null) return;
                context.push('/community/media', extra: draft);
              },
              icon: const Icon(Icons.perm_media_outlined),
              label: const Text('Add Media'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: state.submitting
                  ? null
                  : () async {
                      final draft = _draft();
                      if (draft == null) return;
                      final result = await notifier.submit(
                        title: draft['title'] as String,
                        description: draft['description'] as String,
                        category: draft['category'] as String,
                        location: Map<String, String>.from(draft['location'] as Map),
                        contentType: draft['content_type'] as String,
                      );
                      if (!mounted || result == null) return;
                      context.go('/community/success', extra: result);
                    },
              child: state.submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit Without Media'),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _draft() {
    if (!_formKey.currentState!.validate()) return null;
    return {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'category': _category,
      'content_type': _contentType,
      'location': {
        'state': _stateCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
        'village': _villageCtrl.text.trim(),
      },
    };
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
}
