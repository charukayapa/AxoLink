import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../widgets/axo_icon.dart';
import '../services/auth_service.dart';
import 'otp_verification_screen.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  bool _isLogin = true;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _showPass = false;
  String _error = '';
  bool _loading = false;
  bool _gLoading = false;

  Future<void> _handleSubmit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'All fields are required.');
      return;
    }
    if (!_isLogin && name.isEmpty) {
      setState(() => _error = 'Please enter your full name.');
      return;
    }
    if (!_isLogin) {
      final pwdRegEx = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%])[A-Za-z\d!@#\$%]{8,12}$');
      if (!pwdRegEx.hasMatch(password)) {
        setState(() => _error = 'Password must be 8-12 chars, include upper, lower, number, and a special character (!@#\$%).');
        return;
      }
    } else {
      if (password.length < 6) {
        setState(() => _error = 'Password is required.');
        return;
      }
    }

    setState(() { _loading = true; _error = ''; });
    try {
      if (_isLogin) {
        await _authService.signInWithEmail(email, password);
      } else {
        // Sign up — Supabase sends verification OTP email automatically
        final response = await _authService.signUpWithEmail(email, password, name);
        
        // Supabase returns a "fake" user for already-registered emails to prevent
        // email enumeration. Detect this by checking for empty identities or
        // already-confirmed email.
        final user = response.user;
        if (user != null && (user.identities == null || user.identities!.isEmpty)) {
          // Email is already registered
          setState(() => _error = 'This email is already registered. Please sign in instead.');
          return;
        }
        if (user != null && user.emailConfirmedAt != null) {
          // Email already exists and is confirmed
          setState(() => _error = 'This email is already registered. Please sign in instead.');
          return;
        }

        // Check if email confirmation is required (new user)
        if (user != null && user.emailConfirmedAt == null) {
          if (mounted) {
            // Navigate to OTP verification screen
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                email: email,
                type: OtpType.signup,
                title: 'Verify Your Email',
                subtitle: 'We sent a 6-digit code to\n$email',
                onVerified: () {
                  // On successful verification, pop back to auth screen
                  // The auth state listener will pick up the new session
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email verified! You are now signed in.')),
                  );
                },
              ),
            ));
          }
        }
        // If email is already confirmed (e.g., when email confirmation is disabled in Supabase),
        // the user will be auto-logged in via the auth state listener
      }
    } catch (e) {
      setState(() => _error = AuthService.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() { _gLoading = true; _error = ''; });
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      final msg = e.toString();
      if (!msg.contains('cancelled') && !msg.contains('popup-closed') && !msg.contains('OAuth redirect')) {
        setState(() => _error = 'Google Sign-In failed: $msg');
      }
    } finally {
      if (mounted) setState(() => _gLoading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = kIsWeb && width >= 768;

    final formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset('assets/logo.png', width: 46, height: 46, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('AxoLink', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textMain, letterSpacing: -0.5)),
            Text('INSULIN MONITOR', style: TextStyle(fontSize: 11, color: AppColors.textLabel, letterSpacing: 1.2)),
          ]),
        ]),
        const SizedBox(height: 44),

        // Heading
        Text(
          _isLogin ? 'Welcome back' : 'Create account',
          style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: AppColors.textMain, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin
            ? 'Sign in to monitor your insulin cooler in real-time.'
            : 'Start protecting your insulin with AI-powered monitoring.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSub, height: 1.6),
        ),
        const SizedBox(height: 32),

        // Error
        if (_error.isNotEmpty) _buildErrorBox(),

        // Full Name (signup)
        if (!_isLogin) ...[
          _buildLabel('Full Name'),
          _buildTextField(_nameCtrl, 'Jane Doe'),
          const SizedBox(height: 14),
        ],

        // Email
        _buildLabel('Email Address'),
        _buildTextField(_emailCtrl, 'you@example.com', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),

        // Password
        _buildLabel('Password'),
        _buildPasswordField(),

        // Forgot Password (login only)
        if (_isLogin) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              ),
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Submit
        _buildGradientButton(
          onPressed: _loading ? null : _handleSubmit,
          child: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(_isLogin ? 'Sign In →' : 'Create Account →', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
        ),
        const SizedBox(height: 18),

        // Divider
        _buildDivider('or'),
        const SizedBox(height: 18),

        // Google
        _buildOutlineButton(
          onPressed: _gLoading ? null : _handleGoogleSignIn,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset('assets/google.png', width: 18, height: 18),
            const SizedBox(width: 10),
            Text(_gLoading ? 'Connecting…' : 'Continue with Google', style: const TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 22),

        // Toggle
        Center(
          child: GestureDetector(
            onTap: () => setState(() { _isLogin = !_isLogin; _error = ''; }),
            child: RichText(text: TextSpan(
              style: const TextStyle(fontSize: 14, color: AppColors.textLabel),
              children: [
                TextSpan(text: _isLogin ? "Don't have an account? " : 'Already have an account? '),
                TextSpan(text: _isLogin ? 'Sign up' : 'Sign in', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
              ],
            )),
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
                  child: formContent,
                )
              : formContent,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textSub, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
  );

  Widget _buildTextField(TextEditingController c, String hint, {TextInputType? keyboardType, TextInputAction? textInputAction}) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: c,
        keyboardType: keyboardType,
        textInputAction: textInputAction ?? TextInputAction.next,
        style: const TextStyle(color: AppColors.textMain, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSub),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.04),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accentDark)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: _passwordCtrl,
        obscureText: !_showPass,
        onSubmitted: (_) => _handleSubmit(),
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
            icon: AxoIcon(data: _showPass ? IconPaths.eyeOff : IconPaths.eye, size: 17, color: AppColors.textSub),
            onPressed: () => setState(() => _showPass = !_showPass),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({VoidCallback? onPressed, required Widget child}) {
    return SizedBox(
      width: double.infinity, height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildOutlineButton({VoidCallback? onPressed, required Widget child}) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: child,
      ),
    );
  }

  Widget _buildDivider(String text) {
    return Row(children: [
      Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.05))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
      Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.05))),
    ]);
  }

  Widget _buildErrorBox() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x1AF44336),
        border: Border.all(color: const Color(0x33F44336)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('⚠ $_error', style: const TextStyle(fontSize: 13, color: Color(0xFFFF6B6B))),
    );
  }
}
