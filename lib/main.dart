import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_config.dart';
import 'supabase_config.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'screens/auth_screen.dart';
import 'screens/device_pair_screen.dart';
import 'screens/home_shell.dart';
import 'screens/pin_screen.dart';

void main() async {
  try {
    print("APP_START: Initializing WidgetsFlutterBinding");
    WidgetsFlutterBinding.ensureInitialized();

    // Edge-to-edge system navigation (respects user's gesture/3-button choice)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    print("APP_START: Initializing Supabase");
    await SupabaseConfig.initialize();

    print("APP_START: Initializing Firebase (for RTDB)");
    await FirebaseConfig.initialize();
    
    print("APP_START: Initializing Notifications");
    await NotificationService.initialize();
    
    print("APP_START: Requesting Notification Permission");
    await NotificationService.requestPermission();
    
    print("APP_START: Initializing Background Service");
    await initializeBackgroundService();
    
    print("APP_START: Running App");
    runApp(const AxoLinkApp());
  } catch (e, stack) {
    print("APP_CRASH: Fatal error during initialization: $e");
    print("APP_CRASH: Stack trace: $stack");
    runApp(MaterialApp(home: Scaffold(body: Center(child: SelectableText("Fatal Error: $e\n$stack")))));
  }
}

class AxoLinkApp extends StatelessWidget {
  const AxoLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AxoLink Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.bg,
          primary: AppColors.accent,
        ),
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  final _authService = AuthService();
  User? _user;
  String? _deviceId;
  bool _loadingApp = true;
  PinMode? _pinMode; // null = no PIN screen shown

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Check if already logged in
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      _user = currentUser;
      _handleUserLogin(currentUser);
    }

    // Listen to auth state changes
    _authService.authStateChanges.listen((user) async {
      if (!mounted) return;
      setState(() => _user = user);
      if (user != null) {
        await _handleUserLogin(user);
      } else {
        setState(() { _deviceId = null; _pinMode = null; });
      }
      if (_loadingApp) setState(() => _loadingApp = false);
    });

    // If no auth event fires within 2 seconds, stop loading
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _loadingApp) setState(() => _loadingApp = false);
    });
  }

  Future<void> _handleUserLogin(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('active_device_${user.id}');
    if (saved != null) {
      setState(() => _deviceId = saved);
      await prefs.setString('current_active_device', saved);
    }
    // PIN check on login (mobile only)
    if (!kIsWeb) {
      final hasPin = await PinScreen.hasPin();
      setState(() => _pinMode = hasPin ? PinMode.verify : PinMode.create);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _user != null && !kIsWeb) {
      PinScreen.hasPin().then((has) {
        if (has && _pinMode != PinMode.create) {
          setState(() => _pinMode = PinMode.verify);
        }
      });
    }
  }

  Future<void> _handlePair(String id) async {
    setState(() => _deviceId = id);
    if (_user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_device_${_user!.id}', id);
      await prefs.setString('current_active_device', id);
    }
  }

  Future<void> _handleSwitchDevice() async {
    setState(() => _deviceId = null);
    if (_user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_device_${_user!.id}');
    }
  }

  void _handleLogout() {
    _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingApp) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: const Center(child: Text('Loading AxoLink…', style: TextStyle(color: AppColors.textSub, fontSize: 16))),
      );
    }

    if (_user == null) return const AuthScreen();

    // PIN Lock Screen (mobile only)
    if (_pinMode != null && !kIsWeb) {
      return PinScreen(
        mode: _pinMode!,
        onSuccess: () => setState(() => _pinMode = null),
      );
    }

    if (_deviceId == null) {
      return DevicePairScreen(user: _user!, onPair: _handlePair, onLogout: _handleLogout);
    }

    return HomeShell(
      user: _user!,
      deviceId: _deviceId!,
      onLogout: _handleLogout,
      onSwitchDevice: _handleSwitchDevice,
    );
  }
}
