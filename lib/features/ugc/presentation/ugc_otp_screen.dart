import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/ugc_providers.dart';

class UGCOtpScreen extends ConsumerStatefulWidget {
  const UGCOtpScreen({super.key});

  @override
  ConsumerState<UGCOtpScreen> createState() => _UGCOtpScreenState();
}

class _UGCOtpScreenState extends ConsumerState<UGCOtpScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ugcProvider);
    final notifier = ref.read(ugcProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Reporter Verification')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.verified_user_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 18),
          Text('Verify before reporting', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('VARADHI verifies community reporters to reduce spam and protect local readers.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 22),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Mobile number', prefixIcon: Icon(Icons.phone_android)),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: state.otpSending || state.resendCooldown > 0
                ? null
                : () => notifier.sendOtp(_phoneCtrl.text.trim()),
            icon: state.otpSending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sms_outlined),
            label: Text(state.resendCooldown > 0 ? 'Resend in ${state.resendCooldown}s' : 'Send OTP'),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'OTP', prefixIcon: Icon(Icons.pin_outlined)),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: state.otpVerifying
                ? null
                : () async {
                    final ok = await notifier.verifyOtp(phone: _phoneCtrl.text.trim(), otp: _otpCtrl.text.trim());
                    if (!mounted || !ok) return;
                    context.go('/community/submit');
                  },
            child: state.otpVerifying ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Verify and Continue'),
          ),
          if (state.otpError != null) ...[
            const SizedBox(height: 12),
            Text(state.otpError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
