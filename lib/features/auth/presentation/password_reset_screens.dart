import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/core_providers.dart';
import '../auth_controller.dart';
import 'widgets/auth_brand_header.dart';

class ForgotPasswordRequestScreen extends ConsumerStatefulWidget {
  const ForgotPasswordRequestScreen({super.key});

  @override
  ConsumerState<ForgotPasswordRequestScreen> createState() => _ForgotPasswordRequestScreenState();
}

class _ForgotPasswordRequestScreenState extends ConsumerState<ForgotPasswordRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email: _emailController.text.trim());
      if (!mounted) return;
      context.go('/forgot-password/verify', extra: {
        'email': _emailController.text.trim(),
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFromDio(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to request reset. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ResetShell(
      title: 'Reset password',
      subtitle: 'Enter your email and we will send a secure reset token.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) AuthErrorBanner(message: _error!),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value != null && value.trim().contains('@') ? null : 'Enter a valid email address',
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send Reset Token'),
            ),
            TextButton(onPressed: () => context.go('/login'), child: const Text('Back to Login')),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordVerificationScreen extends ConsumerStatefulWidget {
  final String? email;
  final String? token;

  const ForgotPasswordVerificationScreen({super.key, this.email, this.token});

  @override
  ConsumerState<ForgotPasswordVerificationScreen> createState() => _ForgotPasswordVerificationScreenState();
}

class _ForgotPasswordVerificationScreenState extends ConsumerState<ForgotPasswordVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(text: widget.email ?? '');
  late final TextEditingController _tokenController = TextEditingController(text: widget.token ?? '');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).verifyPasswordReset(
            email: _emailController.text.trim(),
            token: _tokenController.text.trim(),
          );
      if (!mounted) return;
      context.go('/forgot-password/confirm', extra: {
        'email': _emailController.text.trim(),
        'token': _tokenController.text.trim(),
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFromDio(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to verify token. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ResetShell(
      title: 'Verify token',
      subtitle: 'Paste the reset token sent to your email.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) AuthErrorBanner(message: _error!),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value != null && value.trim().contains('@') ? null : 'Enter a valid email address',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _tokenController,
              decoration: const InputDecoration(labelText: 'Reset token', prefixIcon: Icon(Icons.pin_outlined)),
              validator: (value) => value != null && value.trim().length >= 20 ? null : 'Enter the reset token',
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Verify Token'),
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordResetConfirmationScreen extends ConsumerStatefulWidget {
  final String? email;
  final String? token;

  const PasswordResetConfirmationScreen({super.key, this.email, this.token});

  @override
  ConsumerState<PasswordResetConfirmationScreen> createState() => _PasswordResetConfirmationScreenState();
}

class _PasswordResetConfirmationScreenState extends ConsumerState<PasswordResetConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(text: widget.email ?? '');
  late final TextEditingController _tokenController = TextEditingController(text: widget.token ?? '');
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).confirmPasswordReset(
            email: _emailController.text.trim(),
            token: _tokenController.text.trim(),
            newPassword: _passwordController.text,
            newPasswordConfirm: _confirmController.text,
          );
      await ref.read(authNotifierProvider.notifier).clearLocalSession();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successful. Please login.')));
      context.go('/login');
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFromDio(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to reset password. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ResetShell(
      title: 'Create new password',
      subtitle: 'Choose a strong password for your VARADHI account.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) AuthErrorBanner(message: _error!),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
              validator: (value) => value != null && value.trim().contains('@') ? null : 'Enter a valid email address',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _tokenController,
              decoration: const InputDecoration(labelText: 'Reset token', prefixIcon: Icon(Icons.pin_outlined)),
              validator: (value) => value != null && value.trim().length >= 20 ? null : 'Enter the reset token',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'New password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded)),
              ),
              obscureText: _obscure,
              validator: (value) => value != null && value.length >= 8 ? null : 'Password must be at least 8 characters',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmController,
              decoration: const InputDecoration(labelText: 'Confirm new password', prefixIcon: Icon(Icons.verified_user_outlined)),
              obscureText: _obscure,
              validator: (value) => value == _passwordController.text ? null : 'Passwords do not match',
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ResetShell({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: AuthBrandHeader(title: title, subtitle: subtitle)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
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
  return 'Request failed. Please try again.';
}
