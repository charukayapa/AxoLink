import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../widgets/axo_icon.dart';

import '../services/database_service.dart';

class DevicePairScreen extends StatefulWidget {
  final User user;
  final void Function(String deviceId) onPair;
  final VoidCallback onLogout;

  const DevicePairScreen({super.key, required this.user, required this.onPair, required this.onLogout});

  @override
  State<DevicePairScreen> createState() => _DevicePairScreenState();
}

class _DevicePairScreenState extends State<DevicePairScreen> {
  final _deviceCtrl = TextEditingController();
  final _dbService = DatabaseService();
  List<String> _savedDevices = [];
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    // Load from local storage first
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('axo_devices_${widget.user.id}');
    if (stored != null && stored.isNotEmpty) {
      setState(() => _savedDevices = stored);
    }
    // Sync from Supabase
    try {
      final devices = await _dbService.getSavedDevices(widget.user.id);
      if (devices.isNotEmpty) {
        setState(() => _savedDevices = devices);
        await prefs.setStringList('axo_devices_${widget.user.id}', devices);
      }
    } catch (_) {}
  }

  Future<void> _handlePair([String? targetId]) async {
    final t = (targetId ?? _deviceCtrl.text).trim().toUpperCase();
    if (t.isEmpty) { setState(() => _error = 'Please enter a device ID.'); return; }
    if (!t.startsWith('AXO-')) { setState(() => _error = 'Invalid format. Device ID must begin with AXO-'); return; }

    setState(() { _loading = true; _error = ''; });
    try {
      await _dbService.registerDevice(widget.user.id, t);
    } catch (_) {}

    final newList = {..._savedDevices, t}.toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('axo_devices_${widget.user.id}', newList);
    await prefs.setString('active_device_${widget.user.id}', t);
    setState(() { _savedDevices = newList; _loading = false; });
    widget.onPair(t);
  }

  @override
  void dispose() {
    _deviceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = kIsWeb && width >= 768;
    final displayName = widget.user.userMetadata?['display_name'] as String? ?? widget.user.email?.split('@')[0] ?? 'User';

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hello, $displayName 👋', style: const TextStyle(fontSize: 13, color: AppColors.textSub)),
        const SizedBox(height: 4),
        const Text('Connect Your Device', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AppColors.textMain)),
        const SizedBox(height: 28),

        // Saved Devices
        if (_savedDevices.isNotEmpty) ...[
          const Text('REGISTERED DEVICES', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          ..._savedDevices.map((d) => _buildDeviceCard(d)),
          const SizedBox(height: 4),
        ],

        // Divider
        if (_savedDevices.isNotEmpty) _buildDivider('or enter manually'),

        // Manual Input
        const SizedBox(height: 22),
        SizedBox(
          height: 52,
          child: TextField(
            controller: _deviceCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: AppColors.textMain, fontSize: 15, fontFamily: 'monospace', letterSpacing: 1.5),
            decoration: InputDecoration(
              hintText: 'AXO-XXXXXXXX',
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

        // Error
        if (_error.isNotEmpty) Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0x1AF44336), border: Border.all(color: const Color(0x33F44336)), borderRadius: BorderRadius.circular(10)),
          child: Text('⚠ $_error', style: const TextStyle(fontSize: 13, color: Color(0xFFFF6B6B))),
        ),

        // Connect Button
        SizedBox(
          width: double.infinity, height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd])),
            child: ElevatedButton(
              onPressed: _loading ? null : () => _handlePair(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Connect Device', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Info card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x120064FF),
            border: Border.all(color: const Color(0x240064FF)),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('💡 Finding your Device ID', style: TextStyle(fontSize: 12, color: Color(0xFF4A90E2), fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('Printed on the base label of your AxoLink cooler (e.g. AXO-64A22604).', style: TextStyle(fontSize: 12, color: Color(0xFF3A5070), height: 1.5)),
          ]),
        ),
        const SizedBox(height: 20),

        // Logout
        Center(
          child: TextButton(
            onPressed: widget.onLogout,
            child: const Text('Sign Out', style: TextStyle(fontSize: 14, color: AppColors.danger, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
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

  Widget _buildDeviceCard(String deviceId) {
    return GestureDetector(
      onTap: () => _handlePair(deviceId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: const Color(0x1F0064FF), borderRadius: BorderRadius.circular(13)),
            child: const Center(child: AxoIcon(data: IconPaths.shield, size: 22, color: AppColors.accent)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(deviceId, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain, fontFamily: 'monospace')),
            const SizedBox(height: 3),
            const Text('● Active', style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
          ])),
          const AxoIcon(data: IconPaths.arrow, size: 17, color: AppColors.textMuted),
        ]),
      ),
    );
  }

  Widget _buildDivider(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Row(children: [
        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.05))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.05))),
      ]),
    );
  }
}
