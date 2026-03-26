import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import '../theme.dart';
import '../services/auth_service.dart';
import '../supabase_config.dart';
import 'pin_screen.dart';
import 'otp_verification_screen.dart';
import 'forgot_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  final User user;
  final String deviceId;
  final VoidCallback onSwitchDevice;
  final VoidCallback onLogout;
  final bool isWeb;

  const SettingsScreen({super.key, required this.user, required this.deviceId, required this.onSwitchDevice, required this.onLogout, this.isWeb = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  bool _n1 = true, _n2 = true, _n3 = true, _n4 = false;
  String? _photoUrl;
  String? _profileName;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadNotifPrefs();
  }

  Future<void> _loadNotifPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _n1 = prefs.getBool('notif_enable') ?? true;
        _n2 = prefs.getBool('notif_temp_range') ?? true;
        _n3 = prefs.getBool('notif_ext_heat') ?? true;
        _n4 = prefs.getBool('notif_device_offline') ?? false;
      });
    }
  }

  Future<void> _saveNotifPref(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  void _loadProfile() {
    // Listen to Supabase profile changes
    _authService.profileStream(widget.user.id).listen((data) {
      if (mounted) {
        setState(() {
          _photoUrl = data['photo_url'] as String?;
          _profileName = data['name'] as String?;
        });
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 30);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        if (mounted) setState(() => _photoUrl = base64Image);
        
        // Update Supabase profile
        await _authService.updateProfile({'photo_url': base64Image});
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _showNameDialog() async {
    final currentName = _profileName ?? widget.user.userMetadata?['display_name'] as String? ?? '';
    final ctrl = TextEditingController(text: currentName);
    String error = '';
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: const Text('Edit Display Name', style: TextStyle(color: AppColors.textMain)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (error.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(error, style: const TextStyle(color: AppColors.danger))),
          TextField(
            controller: ctrl,
            style: const TextStyle(color: AppColors.textMain),
            decoration: InputDecoration(hintText: 'New Name', hintStyle: const TextStyle(color: AppColors.textSub), filled: true, fillColor: Colors.white.withValues(alpha: 0.05)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSub))),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) { setDialogState(() => error = 'Name cannot be empty.'); return; }
              try {
                await _authService.updateDisplayName(ctrl.text.trim());
                await _authService.updateProfile({'name': ctrl.text.trim()});
                if (mounted) { setState(() => _profileName = ctrl.text.trim()); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated'))); }
              } catch(e) { setDialogState(() => error = e.toString()); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    ));
  }

  Future<void> _startPasswordChangeFlow() async {
    final email = widget.user.email;
    if (email == null) return;
    
    try {
      // Show loading indicator while sending email
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
      
      // Send OTP to user's email for verification
      await _authService.sendPasswordResetEmail(email);
      
      if (!mounted) return;
      Navigator.pop(context); // pop loading dialog
      
      // Navigate to OTP verification screen
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          email: email,
          type: OtpType.recovery,
          title: 'Verify Password Change',
          subtitle: 'Enter the 6-digit code sent to\n$email',
          onVerified: () {
            // After OTP verified, show the new password screen
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => NewPasswordScreen(email: email),
            ));
          },
        ),
      ));
    } catch(e) {
      if (!mounted) return;
      Navigator.pop(context); // pop loading dialog
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AuthService.getErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.user;
    final displayName = _profileName ?? currentUser.userMetadata?['display_name'] as String? ?? currentUser.email?.split('@')[0] ?? 'User';
    final displayEmail = currentUser.email ?? 'N/A';
    final provider = currentUser.appMetadata['provider'] as String? ?? '';
    final isGoogle = provider == 'google';
    final initial = isGoogle ? 'G' : (displayName.isNotEmpty ? displayName[0] : 'U').toUpperCase();

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 10,
        right: widget.isWeb ? 20 : 10,
        bottom: widget.isWeb ? 40 : 130,
        top: 10
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.isWeb ? 700 : double.infinity),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: Colors.white)),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.cardBg, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BBFF), 
                    borderRadius: BorderRadius.circular(15),
                    image: _photoUrl != null && _photoUrl!.isNotEmpty 
                      ? DecorationImage(
                          image: _photoUrl!.startsWith('http') 
                              ? NetworkImage(_photoUrl!) as ImageProvider
                              : MemoryImage(base64Decode(_photoUrl!.split(',').last)),
                          fit: BoxFit.cover,
                        )
                      : null,
                  ),
                  child: _photoUrl == null || _photoUrl!.isEmpty
                    ? Center(child: Text(initial, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)))
                    : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textMain)),
                const SizedBox(height: 3),
                Text(displayEmail, style: const TextStyle(fontSize: 12, color: AppColors.textLabel)),
                if (isGoogle) ...[const SizedBox(height: 3), const Text('via Google OAuth', style: TextStyle(fontSize: 11, color: Color(0xFF4A90E2), fontWeight: FontWeight.w600))],
              ])),
            ]),
          ),
          const SizedBox(height: 26),

          // Profile Settings
          _sectionTitle('Profile Settings'),
          _linkRow('Change Display Name', const Color(0xFF4CAF50), Icons.person, _showNameDialog),
          _linkRow('Change Password', AppColors.danger, Icons.lock, _startPasswordChangeFlow),

          // Notifications
          _sectionTitle('Push Notifications'),
          _toggleRow('Enable Notifications', _n1, (v) { setState(() => _n1 = v); _saveNotifPref('notif_enable', v); }, AppColors.accent, Icons.notifications_outlined),
          _toggleRow('Temp Range Alerts (2–8°C)', _n2, (v) { setState(() => _n2 = v); _saveNotifPref('notif_temp_range', v); }, AppColors.danger, Icons.notifications_outlined),
          _toggleRow('External Heat (>25°C)', _n3, (v) { setState(() => _n3 = v); _saveNotifPref('notif_ext_heat', v); }, AppColors.warning, Icons.notifications_outlined),
          _toggleRow('Device Offline Alert', _n4, (v) { setState(() => _n4 = v); _saveNotifPref('notif_device_offline', v); }, const Color(0xFF8B95B0), Icons.notifications_outlined),

          // Device
          _sectionTitle('Device'),
          _linkRow('Switch Device', AppColors.accent, Icons.devices, widget.onSwitchDevice),
          _linkRow('Wi-Fi Captive Portal', AppColors.accent, Icons.wifi, () {
            if (kIsWeb) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wi-Fi Captive Portal is only available on the mobile app.')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scanning for nearby Bluetooth devices…')),
              );
            }
          }),


          // Account
          _sectionTitle('Account'),
          if (!kIsWeb) _linkRow('Change App PIN', const Color(0xFFFF9500), Icons.pin, () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PinScreen(
                mode: PinMode.change,
                onSuccess: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN changed successfully.')));
                },
                onCancel: () => Navigator.pop(context),
              ),
            ));
          }),
          _linkRow('Sign Out', AppColors.danger, Icons.logout, widget.onLogout, danger: true),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(t.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
  );

  Widget _toggleRow(String label, bool val, ValueChanged<bool> onChanged, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 11),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textMain))),
        Transform.scale(scale: 0.85, child: Switch(
          value: val,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF0072FF),
          inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
        )),
      ]),
    );
  }

  Widget _linkRow(String label, Color color, IconData icon, VoidCallback onTap, {bool danger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: danger ? const Color(0x33F44336) : Colors.white.withValues(alpha: 0.06)),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: danger ? AppColors.danger : AppColors.textMain))),
          if (!danger) const Icon(Icons.chevron_right, size: 15, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}
