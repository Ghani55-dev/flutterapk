import 'package:flutter/material.dart';
import 'cms_page_screen.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) => const CmsPageScreen(slug: 'terms-and-conditions', titleFallback: 'Terms & Conditions');
}
