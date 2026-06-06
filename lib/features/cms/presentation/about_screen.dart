import 'package:flutter/material.dart';
import 'cms_page_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => const CmsPageScreen(slug: 'about', titleFallback: 'About');
}
