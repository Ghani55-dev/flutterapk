import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<void> showAuthGate(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (c) {
      return Padding(
        padding: MediaQuery.of(c).viewInsets.add(const EdgeInsets.all(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Login to personalize your experience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('You can continue browsing, or sign in to save bookmarks, vote in polls and access your profile.'),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(c).pop();
                    context.push('/login');
                  },
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(c).pop();
                    context.push('/register');
                  },
                  child: const Text('Register'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('Continue browsing'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}
