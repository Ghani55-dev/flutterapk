import 'package:flutter/material.dart';
import 'cms_page_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) => const CmsPageScreen(slug: 'help', titleFallback: 'Help & Support');
}
