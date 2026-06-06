import 'package:flutter/material.dart';
import 'cms_page_screen.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => const CmsPageScreen(slug: 'privacy-policy', titleFallback: 'Privacy Policy');
}
