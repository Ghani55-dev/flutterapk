import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/firebase_service.dart';

// Must be a top-level function
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase once at startup. Background isolates must initialize
  // themselves inside their top-level background handlers.
  await FirebaseService.init();
  runApp(const ProviderScope(child: App()));
}
