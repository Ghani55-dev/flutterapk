import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth_controller.dart';
import 'widgets/auth_brand_header.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String _language = 'en';
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final ok = await ref.read(authNotifierProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            passwordConfirm: _confirmController.text,
            name: _nameController.text.trim(),
            preferredLanguage: _language,
          );
      if (!mounted) return;
      if (ok) {
        context.go('/');
      } else {
        setState(() => _formError = 'We could not create your account. Please review your details.');
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
    return 'Registration failed. Please check your details.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: AuthBrandHeader(title: 'Join VARADHI', subtitle: 'Create your account for alerts, bookmarks, polls, and community reporting.')),
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
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded)),
                        textInputAction: TextInputAction.next,
                        validator: (value) => value != null && value.trim().length > 1 ? null : 'Enter your full name',
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) => value != null && value.trim().contains('@') ? null : 'Enter a valid email address',
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _language,
                        decoration: const InputDecoration(labelText: 'Language Preference', prefixIcon: Icon(Icons.language_rounded)),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                          DropdownMenuItem(value: 'te', child: Text('Telugu')),
                          DropdownMenuItem(value: 'ta', child: Text('Tamil')),
                          DropdownMenuItem(value: 'ar', child: Text('Arabic')),
                          DropdownMenuItem(value: 'ur', child: Text('Urdu')),
                        ],
                        onChanged: (value) => setState(() => _language = value ?? 'en'),
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
                        textInputAction: TextInputAction.next,
                        validator: (value) => value != null && value.length >= 8 ? null : 'Password must be at least 8 characters',
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmController,
                        decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.verified_user_outlined)),
                        obscureText: _obscurePassword,
                        validator: (value) => value == _passwordController.text ? null : 'Passwords do not match',
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create account'),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.g_mobiledata_rounded),
                        label: const Text('Social signup coming soon'),
                      ),
                      const SizedBox(height: 18),
                      const AuthBenefitsPanel(),
                      const SizedBox(height: 18),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Already have an account?'),
                            TextButton(onPressed: () => context.go('/login'), child: const Text('Login')),
                          ],
                        ),
                      ),
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
