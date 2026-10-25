import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import 'email_otp_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  bool _appleLoading = false;
  bool _obscurePassword = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = context.read<SupabaseService>();
      await service.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('Failed host lookup') ||
          errStr.contains('SocketException')) {
        setState(() => _error =
            'Network Error: Cannot connect to server. Please check your device\'s internet connection.');
      } else {
        setState(() => _error = errStr);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    try {
      final service = context.read<SupabaseService>();
      await service.signInWithGoogle();
      // OAuth redirects the browser/app - navigation back into the app
      // happens automatically via Supabase's auth state listener once
      // the provider is configured in the dashboard.
    } catch (e) {
      setState(() => _error = 'Google sign-in: $e');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _loginWithApple() async {
    setState(() {
      _appleLoading = true;
      _error = null;
    });
    try {
      final service = context.read<SupabaseService>();
      await service.signInWithApple();
    } catch (e) {
      setState(() => _error = 'Apple sign-in: $e');
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: rich diagonal gradient background - dark theme:
          // deep canopy green fading into the near-black app background,
          // rather than the old green-to-light-parchment fade, so this
          // screen matches the rest of the app's dark aesthetic instead
          // of turning light at the bottom.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.canopy,
                  Color(0xFF3D6B42),
                  AppColors.darkBg,
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          // Layer 2: soft decorative glow shapes for depth
          const Positioned(
            top: -60,
            right: -40,
            child: _GlowCircle(color: AppColors.chlorotic, size: 220),
          ),
          const Positioned(
            bottom: -80,
            left: -60,
            child: _GlowCircle(color: AppColors.canopy, size: 260),
          ),
          // Layer 3: content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5),
                        ),
                        child: const Icon(Icons.eco,
                            size: 44, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Welcome Back',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          shadows: [
                            Shadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Log in to check on your crops',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85)),
                      ),
                      const SizedBox(height: 28),
                      // Glassmorphic frosted card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35)),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _GlassTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) =>
                                        (v == null || !v.contains('@'))
                                            ? 'Enter a valid email'
                                            : null,
                                  ),
                                  const SizedBox(height: 14),
                                  _GlassTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscurePassword = !_obscurePassword),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.length < 6)
                                            ? 'Minimum 6 characters'
                                            : null,
                                    onFieldSubmitted: (_) => _login(),
                                  ),
                                  if (_error != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.red.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 18),
                                  FilledButton(
                                    onPressed: _loading ? null : _login,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.neon,
                                      foregroundColor: AppColors.darkBg,
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.darkBg),
                                          )
                                        : const Text('Log In'),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EmailOtpScreen(
                                          initialEmail:
                                              _emailController.text.trim(),
                                        ),
                                      ),
                                    ),
                                    child: const Text('Use email OTP instead'),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: Divider(
                                              color: Colors.white
                                                  .withValues(alpha: 0.4))),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Text('or',
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.8))),
                                      ),
                                      Expanded(
                                          child: Divider(
                                              color: Colors.white
                                                  .withValues(alpha: 0.4))),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  OutlinedButton.icon(
                                    onPressed: _googleLoading
                                        ? null
                                        : _loginWithGoogle,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.9),
                                      foregroundColor: Colors.black87,
                                      side: BorderSide(
                                          color: Colors.white
                                              .withValues(alpha: 0.6)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                    icon: _googleLoading
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : const _GoogleGlyph(),
                                    label: const Text('Continue with Google'),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed:
                                        _appleLoading ? null : _loginWithApple,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                          color: Colors.white
                                              .withValues(alpha: 0.6)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                    icon: _appleLoading
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : const Icon(Icons.apple, size: 20),
                                    label: const Text('Continue with Apple'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignupScreen()),
                        ),
                        child: Text(
                          "Don't have an account? Sign Up",
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft translucent circle used behind the glass card for visual depth -
/// purely decorative, no interaction.
class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.35),
      ),
    );
  }
}

/// Text field styled for the frosted-glass card: translucent fill,
/// white text/labels/icons so it reads clearly over the gradient.
class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }
}

/// Simple 4-color "G" glyph approximating the Google logo without
/// needing an external image asset or network fetch.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: Color(0xFF4285F4),
      ),
    );
  }
}
