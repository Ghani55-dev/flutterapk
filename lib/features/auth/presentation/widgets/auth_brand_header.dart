import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';

class AuthBrandHeader extends StatefulWidget {
  final String title;
  final String subtitle;

  const AuthBrandHeader({super.key, required this.title, required this.subtitle});

  @override
  State<AuthBrandHeader> createState() => _AuthBrandHeaderState();
}

class _AuthBrandHeaderState extends State<AuthBrandHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final scale = 0.96 + (_controller.value * 0.06);
              return Transform.scale(
                scale: scale,
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(colors: [Color(0xFFFFD166), Color(0xFFFF6B35), Color(0xFFB51724)]),
                    boxShadow: [BoxShadow(color: const Color(0xFFFFA726).withAlpha(70), blurRadius: 28, spreadRadius: 2)],
                  ),
                  child: const Center(child: Text('V', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 34))),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Text(AppConfig.appName, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(widget.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(widget.subtitle, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}

class AuthBenefitsPanel extends StatelessWidget {
  const AuthBenefitsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          _Benefit(text: 'Unlimited News'),
          _Benefit(text: 'Breaking Alerts'),
          _Benefit(text: 'Bookmarks'),
          _Benefit(text: 'Poll Participation'),
          _Benefit(text: 'Community Reporting'),
        ],
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  final String message;

  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontWeight: FontWeight.w700)),
    );
  }
}

class _Benefit extends StatelessWidget {
  final String text;

  const _Benefit({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFFFFC857), size: 18),
          const SizedBox(width: 9),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
