import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../providers/admin_providers.dart';
import '../../../providers/core_providers.dart';
import '../auth_controller.dart';
import 'widgets/auth_brand_header.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _formError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final ok = await ref.read(authNotifierProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      if (ok) {
        // Get the authenticated user - adding a small delay to ensure state is updated
        await Future.delayed(const Duration(milliseconds: 100));
        
        final authState = ref.read(authNotifierProvider);
        final user = authState.user;
        
        if (user != null && user.isAdmin) {
          // Bridge the admin auth state with the same tokens so the admin
          // panel routes work without requiring a separate admin login.
          try {
            final tokenManager = ref.read(tokenManagerProvider);
            final access = await tokenManager.getAccessToken();
            final refresh = await tokenManager.getRefreshToken();
            
            if (access != null && refresh != null) {
              final userMap = <String, dynamic>{
                'id': user.rawId,
                'email': user.email,
                'full_name': user.name ?? '',
                'is_admin': true,
              };
              
              // Authenticate the admin and then redirect
              await ref.read(adminAuthNotifierProvider.notifier).loginWithTokens(
                    access: access,
                    refresh: refresh,
                    user: userMap,
                  );
              
              if (mounted) {
                context.go('/admin/dashboard');
              }
            } else {
              // Tokens not available, redirect to home
              if (mounted) context.go('/');
            }
          } catch (e) {
            // Error setting up admin auth, still redirect to home as regular user
            if (mounted) context.go('/');
          }
        } else {
          // Regular user login
          if (mounted) context.go('/');
        }
      } else {
        setState(() => _formError = 'We could not sign you in. Please check your details.');
      }
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _formError = _messageFromDio(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _messageFromDio(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'You appear to be offline. Check your connection and try again.';
    }
    final data = error.response?.data;
    if (data is Map && data['errors'] is List && (data['errors'] as List).isNotEmpty) {
      return (data['errors'] as List).first.toString();
    }
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    return 'Login failed. Please check your email and password.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: AuthBrandHeader(title: 'Welcome back', subtitle: 'Sign in to continue your VARADHI news journey.')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_formError != null) AuthErrorBanner(message: _formError!),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) => value != null && value.trim().contains('@') ? null : 'Enter a valid email address',
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(_obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) => value != null && value.length >= 8 ? null : 'Password must be at least 8 characters',
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(onPressed: () => context.go('/forgot-password'), child: const Text('Forgot Password?')),
                      ),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Login'),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.g_mobiledata_rounded),
                        label: const Text('Google login coming soon'),
                      ),
                      const SizedBox(height: 18),
                      const AuthBenefitsPanel(),
                      const SizedBox(height: 18),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('New to VARADHI?'),
                            TextButton(onPressed: () => context.go('/register'), child: const Text('Create account')),
                          ],
                        ),
                      ),
                      Center(child: Text('${AppConfig.appName} protects your local news preferences.', style: Theme.of(context).textTheme.labelMedium)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
