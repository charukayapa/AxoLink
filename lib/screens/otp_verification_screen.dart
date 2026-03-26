import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../services/auth_service.dart';

/// Reusable OTP verification screen used for signup, forgot password, and settings password change.
class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final OtpType type;
  final String title;
  final String subtitle;
  final VoidCallback onVerified;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.onVerified,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _authService = AuthService();
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String _error = '';
  bool _loading = false;
  bool _canResend = false;
  int _resendSeconds = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendSeconds--;
          if (_resendSeconds <= 0) {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    final code = _code;
    if (code.length != 6) {
      setState(() => _error = 'Please enter the full 6-digit code.');
      return;
    }

    setState(() { _loading = true; _error = ''; });
    try {
      await _authService.verifyOTP(widget.email, code, widget.type);
      widget.onVerified();
    } catch (e) {
      setState(() => _error = AuthService.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    try {
      if (widget.type == OtpType.signup) {
        await _authService.resendSignupOTP(widget.email);
      } else {
        await _authService.sendPasswordResetEmail(widget.email);
      }
      _startResendTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Code resent to ${widget.email}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = AuthService.getErrorMessage(e));
      }
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                // Icon
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.mark_email_read_outlined, size: 36, color: AppColors.accent),
                ),
                const SizedBox(height: 28),

                Text(widget.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textMain)),
                const SizedBox(height: 10),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSub, height: 1.5),
                ),
                const SizedBox(height: 36),

                // OTP Input boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) => Container(
                    width: 48, height: 56,
                    margin: EdgeInsets.only(left: i > 0 ? 8 : 0, right: i == 2 ? 12 : 0),
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textMain),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: _controllers[i].text.isNotEmpty
                            ? AppColors.accent.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: _controllers[i].text.isNotEmpty ? AppColors.accent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: _controllers[i].text.isNotEmpty ? AppColors.accent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.accent, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {}); // Refresh border colors
                        if (val.isNotEmpty && i < 5) {
                          _focusNodes[i + 1].requestFocus();
                        }
                        if (val.isEmpty && i > 0) {
                          _focusNodes[i - 1].requestFocus();
                        }
                        // Auto-submit on last digit
                        if (_code.length == 6) {
                          _verify();
                        }
                      },
                    ),
                  )),
                ),
                const SizedBox(height: 20),

                // Error
                if (_error.isNotEmpty) Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x1AF44336),
                    border: Border.all(color: const Color(0x33F44336)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('⚠ $_error', style: const TextStyle(fontSize: 13, color: Color(0xFFFF6B6B))),
                ),
                const SizedBox(height: 24),

                // Verify Button
                SizedBox(
                  width: 340, height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]),
                    ),
                    child: ElevatedButton(
                      onPressed: _loading ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Verify Code →', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Resend
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Didn't receive the code? ", style: TextStyle(fontSize: 13, color: AppColors.textSub)),
                  GestureDetector(
                    onTap: _canResend ? _resend : null,
                    child: Text(
                      _canResend ? 'Resend' : 'Resend in ${_resendSeconds}s',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _canResend ? AppColors.accent : AppColors.textMuted),
                    ),
                  ),
                ]),
                const SizedBox(height: 28),

                // Back
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('← Back', style: TextStyle(fontSize: 14, color: AppColors.textSub, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
