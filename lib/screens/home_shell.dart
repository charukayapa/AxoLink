import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../theme.dart';

import '../models/device_data.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'dashboard_screen.dart';
import 'alerts_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  final User user;
  final String deviceId;
  final VoidCallback onLogout;
  final VoidCallback onSwitchDevice;

  const HomeShell({super.key, required this.user, required this.deviceId, required this.onLogout, required this.onSwitchDevice});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _dbService = DatabaseService();
  final _authService = AuthService();
  int _activeTab = 0;
  DeviceData? _sysData;
  final List<double> _intH = [];
  final List<double> _extH = [];
  final List<AlertItem> _liveAlerts = [];
  int _alertBadge = 0;
  StreamSubscription? _dbSub;
  StreamSubscription? _profileSub;
  String? _profileName;
  String? _profilePhotoUrl;
  bool _isLoadingData = true;  
  Timer? _offlineTimer;
  
  void _resetOfflineTimer() {
    _offlineTimer?.cancel();
    _offlineTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted) return;
      setState(() {
        _sysData = null; // Trigger offline UI
      });
      _checkAlerts(null).then((_) => _loadAlerts());
    });
  }

  @override
  void initState() {
    super.initState();
    _loadAlerts();
    _listenProfile();
    _dbSub = _dbService.listenToDevice(widget.deviceId, (data) {
      if (!mounted) return;
      
      if (data != null) {
        _resetOfflineTimer();
      } else {
        _offlineTimer?.cancel();
      }

      setState(() {
        _isLoadingData = false;
        _sysData = data;
        if (data != null) {
          _intH.add(data.internalTemp);
          if (_intH.length > 25) _intH.removeAt(0);
          _extH.add(data.externalTemp);
          if (_extH.length > 25) _extH.removeAt(0);
        }
      });
      _checkAlerts(data).then((_) => _loadAlerts());
    });
  }

  void _listenProfile() {
    _profileSub = _authService.profileStream(widget.user.id).listen((data) {
      if (!mounted) return;
      setState(() {
        _profileName = data['name'] as String?;
        _profilePhotoUrl = data['photo_url'] as String?;
      });
    });
  }

  Future<void> _loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final alertsStr = prefs.getStringList('saved_alerts') ?? [];
    if (mounted) {
      setState(() {
        _liveAlerts.clear();
        for (var s in alertsStr) {
          try {
            final map = jsonDecode(s);
            _liveAlerts.add(AlertItem(type: map['type'], title: map['title'], body: map['body'], id: map['id']));
          } catch (_) {}
        }
        _liveAlerts.sort((a, b) => b.id.compareTo(a.id));
      });
    }
  }

  Future<void> _checkAlerts(DeviceData? d) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    
    Future<void> fire(String key, String type, String title, String body) async {
      await prefs.reload();
      
      // Check user preferences
      bool masterNotif = prefs.getBool('notif_enable') ?? true;
      if (!masterNotif) return;
      
      if (key == 'device_offline' && !(prefs.getBool('notif_device_offline') ?? false)) return;
      if ((key == 'over_cool' || key == 'over_heat') && !(prefs.getBool('notif_temp_range') ?? true)) return;
      if (key == 'ext_heat' && !(prefs.getBool('notif_ext_heat') ?? true)) return;

      final last = prefs.getInt('alert_cooldown_$key') ?? 0;
      if (now - last > 30000) {
        await prefs.setInt('alert_cooldown_$key', now);
        
        final newItem = AlertItem(type: type, title: title, body: body);
        setState(() {
          _liveAlerts.insert(0, newItem);
          if (_liveAlerts.length > 50) _liveAlerts.removeLast();
          _alertBadge++;
        });
        
        final alertsStr = prefs.getStringList('saved_alerts') ?? [];
        alertsStr.add(jsonEncode(newItem.toJson()));
        if (alertsStr.length > 50) alertsStr.removeAt(0);
        await prefs.setStringList('saved_alerts', alertsStr);

        NotificationService.showNotification(
          id: key.hashCode,
          title: title,
          body: body,
        );
      }
    }

    if (d == null) {
      await fire('device_offline', 'danger', '🔴 Device Offline', 'Device not connected to the internet. Check device wifi connection.');
      return;
    }

    if (d.internalTemp < 2)  await fire('over_cool', 'danger',  '🧊 Overcooling Alert',   'Internal compartment is getting overcooled.');
    if (d.internalTemp > 8)  await fire('over_heat', 'danger',  '🔥 Overheating Alert',   'Internal compartment is getting overheated.');
    if (d.externalTemp > 25) await fire('ext_heat',  'warning', '☀️ High External Heat',   'High external heat detected. Please change the device location.');
  }

  @override
  void dispose() {
    _offlineTimer?.cancel();
    _dbSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWeb = kIsWeb && width >= 768;
    final ai = _sysData != null ? getStatus(_sysData!.aiStatus) : getStatus('Offline');

    if (isWeb) return _buildWebLayout(ai);
    return _buildMobileLayout(ai);
  }

  Widget _buildWebLayout(AiStatusStyle ai) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(children: [
        // Sidebar
        _buildSidebar(ai),
        // Main content
        Expanded(child: Column(children: [
          // Top bar
          Container(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 14),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x0AFFFFFF)))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('AxoLink', style: TextStyle(fontSize: 12, color: AppColors.textLabel, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  _activeTab == 0 ? 'Axo Insulin Dashboard' : _activeTab == 1 ? 'Alerts' : 'Settings',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textMain, letterSpacing: -0.4),
                ),
              ]),
              _aiBadge(ai),
            ]),
          ),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 28), child: _buildTabContent(true))),
        ])),
      ]),
    );
  }

  Widget _buildMobileLayout(AiStatusStyle ai) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final navBarBottom = bottomInset > 0 ? bottomInset + 8 : 24;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false, // We handle bottom safe area manually for floating nav
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 12),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('AxoLink', style: TextStyle(fontSize: 12, color: AppColors.textLabel, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    const Text('Axo Insulin Dashboard', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textMain, letterSpacing: -0.4)),
                  ]),
                  _aiBadge(ai),
                ]),
              ),
              Expanded(child: _buildTabContent(false)),
            ]),
          ),
          // Bottom nav bar - dynamic safe area offset
          Positioned(
            bottom: navBarBottom.toDouble(), left: 16, right: 16,
            child: Container(
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xF21E2332),
                borderRadius: BorderRadius.circular(38),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _navItem(0, 'Monitor', Icons.show_chart),
                _navItem(1, 'Alerts', Icons.notifications_outlined),
                _navItem(2, 'Settings', Icons.shield_outlined),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTabContent(bool isWeb) {
    switch (_activeTab) {
      case 0:
        return DashboardScreen(deviceId: widget.deviceId, sysData: _sysData, intH: _intH, extH: _extH, isWeb: isWeb, isLoading: _isLoadingData);
      case 1:
        return AlertsScreen(deviceId: widget.deviceId, liveAlerts: _liveAlerts, isWeb: isWeb);
      case 2:
        return SettingsScreen(user: widget.user, deviceId: widget.deviceId, onSwitchDevice: widget.onSwitchDevice, onLogout: widget.onLogout, isWeb: isWeb);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _aiBadge(AiStatusStyle ai) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(color: ai.bg, border: Border.all(color: ai.border), borderRadius: BorderRadius.circular(100)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: ai.color, borderRadius: BorderRadius.circular(3.5))),
        const SizedBox(width: 6),
        Text(_sysData?.aiStatus ?? 'Offline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: ai.color)),
      ]),
    );
  }

  Widget _navItem(int idx, String label, IconData icon) {
    final isActive = _activeTab == idx;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _activeTab = idx;
          if (idx == 1) _alertBadge = 0;
        });
      },
      child: SizedBox(
        width: 80, height: 76,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(icon, size: 28, color: isActive ? AppColors.accent : AppColors.textMuted),
            if (idx == 1 && _alertBadge > 0)
              Positioned(top: -4, right: -14, child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18, padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(9), border: Border.all(color: const Color(0xF21E2332), width: 2)),
                child: Center(child: Text(_alertBadge > 9 ? '9+' : '$_alertBadge', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white))),
              )),
          ]),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: isActive ? AppColors.accent : AppColors.textMuted)),
        ]),
      ),
    );
  }

  Widget _buildSidebar(AiStatusStyle ai) {
    final displayName = _profileName ?? widget.user.userMetadata?['display_name'] as String? ?? widget.user.email?.split('@')[0] ?? 'U';
    final initial = (displayName.isNotEmpty ? displayName[0] : 'U').toUpperCase();

    return Container(
      width: 230,
      decoration: const BoxDecoration(
        color: Color(0xFA0C101C),
        border: Border(right: BorderSide(color: Color(0x0FFFFFFF))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(children: [
        // Logo
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset('assets/logo.png', width: 38, height: 38, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AxoLink', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textMain, letterSpacing: -0.5)),
            Text('INSULIN MONITOR', style: TextStyle(fontSize: 9, color: AppColors.textLabel, letterSpacing: 1.2)),
          ]),
        ]),
        const SizedBox(height: 28),

        // AI Status Badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: ai.bg, border: Border.all(color: ai.border), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: ai.color, borderRadius: BorderRadius.circular(3.5))),
            const SizedBox(width: 8),
            Text(_sysData?.aiStatus ?? 'Offline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: ai.color)),
          ]),
        ),
        const SizedBox(height: 24),

        // Nav
        const Align(alignment: Alignment.centerLeft, child: Text('NAVIGATION', style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w800, letterSpacing: 1.4))),
        const SizedBox(height: 10),
        _sidebarNavItem(0, 'Dashboard', Icons.show_chart),
        _sidebarNavItem(1, 'Alerts', Icons.notifications_outlined),
        _sidebarNavItem(2, 'Settings', Icons.shield_outlined),

        const Spacer(),

        // Profile
        Container(
          padding: const EdgeInsets.only(top: 16),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x0FFFFFFF)))),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF00BBFF),
                borderRadius: BorderRadius.circular(10),
                image: _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                  ? DecorationImage(
                      image: _profilePhotoUrl!.startsWith('http')
                        ? NetworkImage(_profilePhotoUrl!) as ImageProvider
                        : MemoryImage(base64Decode(_profilePhotoUrl!.split(',').last)),
                      fit: BoxFit.cover,
                    )
                  : null,
              ),
              child: (_profilePhotoUrl == null || _profilePhotoUrl!.isEmpty)
                ? Center(child: Text(initial, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)))
                : null,
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain), overflow: TextOverflow.ellipsis),
              Text(widget.user.email ?? '', style: const TextStyle(fontSize: 10, color: AppColors.textLabel), overflow: TextOverflow.ellipsis),
            ])),
            IconButton(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout, size: 16, color: AppColors.danger),
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _sidebarNavItem(int idx, String label, IconData icon) {
    final isActive = _activeTab == idx;
    return GestureDetector(
      onTap: () => setState(() { _activeTab = idx; if (idx == 1) _alertBadge = 0; }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0x1A4FC3F7) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: isActive ? AppColors.accent : const Color(0xFF5A6A88)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.w700 : FontWeight.w600, color: isActive ? AppColors.accent : const Color(0xFF5A6A88)))),
          if (idx == 1 && _alertBadge > 0) Container(
            constraints: const BoxConstraints(minWidth: 20),
            height: 20, padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(_alertBadge > 9 ? '9+' : '$_alertBadge', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white))),
          ),
        ]),
      ),
    );
  }
}
