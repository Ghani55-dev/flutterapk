import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_controller.dart';

class ProtectedRoute extends ConsumerStatefulWidget {
  final Widget child;
  const ProtectedRoute({required this.child, super.key});

  @override
  ConsumerState<ProtectedRoute> createState() => _ProtectedRouteState();
}

class _ProtectedRouteState extends ConsumerState<ProtectedRoute> {
  bool _redirected = false;

  void _redirectToLogin() {
    if (_redirected) return;
    _redirected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        _redirected = false;
      } else if (next.status == AuthStatus.unauthenticated) {
        _redirectToLogin();
      }
    });

    final auth = ref.watch(authNotifierProvider);
    if (auth.status == AuthStatus.authenticated) {
      _redirected = false;
      return widget.child;
    }
    if (auth.status == AuthStatus.unauthenticated) {
      _redirectToLogin();
    }
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
