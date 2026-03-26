import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'otp_verification_screen.dart';

/// Forgot Password flow: Enter email → receive OTP → verify → set new password
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authService = AuthService();
  final _emailCtrl = TextEditingController();
  String _error = '';
  bool _loading = false;

  Future<void> _sendResetCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email address.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }

    setState(() { _loading = true; _error = ''; });
    try {
      await _authService.sendPasswordResetEmail(email);
      if (!mounted) return;

      // Navigate to OTP screen
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          email: email,
          type: OtpType.recovery,
          title: 'Reset Password',
          subtitle: 'Enter the 6-digit code sent to\n$email',
          onVerified: () {
            // After OTP verified, show new password screen
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => NewPasswordScreen(email: email),
            ));
          },
        ),
      ));
    } catch (e) {
      setState(() => _error = AuthService.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = kIsWeb && width >= 768;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text('← Back to login', style: TextStyle(fontSize: 14, color: AppColors.accent, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 32),

        // Icon
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.lock_reset, size: 32, color: AppColors.accent),
        ),
        const SizedBox(height: 24),

        const Text('Forgot password?', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: AppColors.textMain, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        const Text(
          "No worries! Enter your email and we'll send a verification code to reset your password.",
          style: TextStyle(fontSize: 14, color: AppColors.textSub, height: 1.6),
        ),
        const SizedBox(height: 28),

        // Error
        if (_error.isNotEmpty) Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x1AF44336),
            border: Border.all(color: const Color(0x33F44336)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('⚠ $_error', style: const TextStyle(fontSize: 13, color: Color(0xFFFF6B6B))),
        ),

        // Email field
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: const Text('EMAIL ADDRESS', style: TextStyle(fontSize: 11, color: AppColors.textSub, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
        ),
        SizedBox(
          height: 52,
          child: TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textMain, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'you@example.com',
              hintStyle: const TextStyle(color: AppColors.textSub),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accentDark)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Send button
        SizedBox(
          width: double.infinity, height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]),
            ),
            child: ElevatedButton(
              onPressed: _loading ? null : _sendResetCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Send Verification Code →', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: isWide
                ? Container(
                    width: 440,
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: content,
                  )
                : content,
          ),
        ),
      ),
    );
  }
}

/// New Password screen (shown after OTP verification)
class NewPasswordScreen extends StatefulWidget {
  final String email;
  const NewPasswordScreen({required this.email});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _authService = AuthService();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass = false;
  String _error = '';
  bool _loading = false;

  Future<void> _resetPassword() async {
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    final pwdRegEx = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%])[A-Za-z\d!@#\$%]{8,12}$');
    if (!pwdRegEx.hasMatch(password)) {
      setState(() => _error = 'Password must be 8-12 chars, include upper, lower, number, and a special character (!@#\$%).');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() { _loading = true; _error = ''; });
    try {
      await _authService.updatePassword(password);
      if (mounted) {
        // Pop all the way back to auth screen
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully! Please sign in with your new password.')),
        );
      }
    } catch (e) {
      setState(() => _error = AuthService.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = kIsWeb && width >= 768;

    final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.check_circle_outline, size: 32, color: AppColors.success),
                ),
                const SizedBox(height: 24),

                const Text('Set New Password', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: AppColors.textMain, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                const Text(
                  'Your identity has been verified. Create a new password for your account.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSub, height: 1.6),
                ),
                const SizedBox(height: 28),

                if (_error.isNotEmpty) Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x1AF44336),
                    border: Border.all(color: const Color(0x33F44336)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('⚠ $_error', style: const TextStyle(fontSize: 13, color: Color(0xFFFF6B6B))),
                ),

                const Padding(
                  padding: EdgeInsets.only(bottom: 7),
                  child: Text('NEW PASSWORD', style: TextStyle(fontSize: 11, color: AppColors.textSub, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                ),
                SizedBox(
                  height: 52,
                  child: TextField(
                    controller: _passwordCtrl,
                    obscureText: !_showPass,
                    style: const TextStyle(color: AppColors.textMain, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: const TextStyle(color: AppColors.textSub),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accentDark)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      suffixIcon: IconButton(
                        icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility, size: 20, color: AppColors.textSub),
                        onPressed: () => setState(() => _showPass = !_showPass),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                const Padding(
                  padding: EdgeInsets.only(bottom: 7),
                  child: Text('CONFIRM PASSWORD', style: TextStyle(fontSize: 11, color: AppColors.textSub, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                ),
                SizedBox(
                  height: 52,
                  child: TextField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textMain, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: const TextStyle(color: AppColors.textSub),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accentDark)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Password requirements
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '• 8-12 characters\n• At least one uppercase letter\n• At least one lowercase letter\n• At least one number\n• At least one special character (!@#\$%)',
                    style: TextStyle(fontSize: 11, color: AppColors.textSub, height: 1.6),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity, height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]),
                    ),
                    child: ElevatedButton(
                      onPressed: _loading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Reset Password →', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: isWide
                ? Container(
                    width: 440,
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: content,
                  )
                : content,
          ),
        ),
      ),
    );
  }
}
