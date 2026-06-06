import 'package:flutter/material.dart';
import '../../../core/ui/design_system.dart';

class EpaperReader extends StatelessWidget {
  final List<String> pages;
  const EpaperReader({super.key, this.pages = const []});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: PageView.builder(
            itemCount: pages.isEmpty ? 5 : pages.length,
            itemBuilder: (ctx, i) => _page(context, i),
          ),
        ),
      ),
    );
  }

  Widget _page(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: Container(color: Colors.white12)),
          const SizedBox(height: 12),
          Text('Epaper Headline #$index', style: AppTypography.headline1(Colors.white)),
          const SizedBox(height: 8),
          Text('By Reporter • 2h ago', style: AppTypography.body1(Colors.white70)),
          const SizedBox(height: 12),
          Text('Lead paragraph of the epaper article. Immersive reading experience optimized for long-form content and regional scripts.', style: AppTypography.body1(Colors.white70)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(onPressed: () {}, icon: const Icon(Icons.share)), Row(children: [IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)), IconButton(onPressed: () {}, icon: const Icon(Icons.bookmark_border))])])
        ],
      ),
    );
  }
}
