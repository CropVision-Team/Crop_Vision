import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class EmailOtpScreen extends StatefulWidget {
  final String? initialEmail;

  const EmailOtpScreen({super.key, this.initialEmail});

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  bool _sending = false;
  bool _verifying = false;
  bool _codeSent = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() {
        _error = 'Enter a valid email address.';
        _message = null;
      });
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
      _message = null;
    });
    try {
      await context.read<SupabaseService>().sendEmailOtp(email);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _message = 'A verification code was sent to $email.';
      });
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verifyCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    if (code.length < 6) {
      setState(() => _error = 'Enter the 6-digit code from your email.');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await context.read<SupabaseService>().verifyEmailOtp(
            email: email,
            token: code,
          );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('Failed host lookup') || text.contains('SocketException')) {
      return 'Network error. Check the phone internet connection.';
    }
    if (text.toLowerCase().contains('rate limit')) {
      return 'Too many requests. Wait a moment and try again.';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email OTP Login')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.mark_email_read_outlined,
                          size: 52, color: AppColors.canopy),
                      const SizedBox(height: 12),
                      Text(
                        'Sign in without a password',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _sending ? null : _sendCode,
                        child: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_codeSent ? 'Resend code' : 'Send OTP'),
                      ),
                      if (_codeSent) ...[
                        const SizedBox(height: 18),
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: '6-digit OTP',
                            prefixIcon: Icon(Icons.pin_outlined),
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _verifying ? null : _verifyCode,
                          child: _verifying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Verify and Continue'),
                        ),
                      ],
                      if (_message != null) ...[
                        const SizedBox(height: 14),
                        Text(_message!,
                            style: const TextStyle(color: AppColors.canopy)),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(_error!,
                            style: const TextStyle(color: AppColors.rust)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
