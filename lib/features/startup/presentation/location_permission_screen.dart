import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../location/location_provider.dart';

class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends ConsumerState<LocationPermissionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _busy = false;

  static const _states = ['Andhra Pradesh', 'Telangana', 'Karnataka', 'Tamil Nadu', 'Kerala'];
  static const _districts = ['Srikakulam', 'Vizianagaram', 'Visakhapatnam', 'Vijayawada', 'Hyderabad'];
  static const _villages = ['Main Town', 'North Colony', 'Market Area', 'Old Village', 'New Extension'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _allowLocation() async {
    setState(() => _busy = true);
    await ref.read(locationProvider.notifier).refreshFromGps();
    if (!mounted) return;
    setState(() => _busy = false);
    context.go('/notification-permission');
  }

  Future<void> _chooseManually() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ManualLocationSheet(
        states: _states,
        districts: _districts,
        villages: _villages,
      ),
    );

    if (result != null) {
      await ref.read(locationProvider.notifier).saveManual(result);
    }

    if (mounted) context.go('/notification-permission');
  }

  void _skip() => context.go('/notification-permission');

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
                  final scale = 0.96 + (_controller.value * 0.08);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      height: 170,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primary.withAlpha(34),
                            const Color(0xFFFFC857).withAlpha(78),
                            colors.tertiary.withAlpha(30),
                          ],
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.location_on_rounded, size: 74, color: colors.primary),
                          Positioned(
                            bottom: 28,
                            child: Container(
                              width: 120,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colors.primary.withAlpha(32),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                'Get village and district news first',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Text(
                'VARADHI can tune your guest feed around your state, district, and village. You can still read news without sharing GPS.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy ? null : _allowLocation,
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location_rounded),
                label: const Text('Allow Location'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _chooseManually,
                icon: const Icon(Icons.edit_location_alt_rounded),
                label: const Text('Choose Manually'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 8),
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

class _ManualLocationSheet extends StatefulWidget {
  final List<String> states;
  final List<String> districts;
  final List<String> villages;

  const _ManualLocationSheet({
    required this.states,
    required this.districts,
    required this.villages,
  });

  @override
  State<_ManualLocationSheet> createState() => _ManualLocationSheetState();
}

class _ManualLocationSheetState extends State<_ManualLocationSheet> {
  late String _state = widget.states.first;
  late String _district = widget.districts.first;
  late String _village = widget.villages.first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Choose your area', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _state,
            decoration: const InputDecoration(labelText: 'State'),
            items: widget.states.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) => setState(() => _state = value ?? _state),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _district,
            decoration: const InputDecoration(labelText: 'District'),
            items: widget.districts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) => setState(() => _district = value ?? _district),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _village,
            decoration: const InputDecoration(labelText: 'Village'),
            items: widget.villages.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) => setState(() => _village = value ?? _village),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop({
                'country': 'India',
                'state': _state,
                'district': _district,
                'village': _village,
                'city': _village,
              });
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Use This Location'),
          ),
        ],
      ),
    );
  }
}
