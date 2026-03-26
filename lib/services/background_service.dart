import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_config.dart';
import '../models/device_data.dart';
import '../services/notification_service.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> initializeBackgroundService() async {
  if (kIsWeb) return;
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'axolink_bg_service',
    'Background Service',
    description: 'Runs continuously to monitor insulin cooler',
    importance: Importance.low, 
  );
  
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'axolink_bg_service',
      initialNotificationTitle: 'AxoLink Monitor',
      initialNotificationContent: 'Monitoring cooler status',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  print("BACKGROUND SERVICE ONSTART EXECUTING");
  DartPluginRegistrant.ensureInitialized();
  // Initialize Firebase for RTDB access in background isolate
  await FirebaseConfig.initialize();

  final prefs = await SharedPreferences.getInstance();
  
  String? deviceId = prefs.getString('current_active_device');
  if (deviceId == null) return;

  final dbRef = FirebaseDatabase.instance.ref('Devices/$deviceId');
  print("BACKGROUND SERVICE: Listening to device $deviceId");

  Timer? bgOfflineTimer;

  dbRef.onValue.listen((event) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
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
        await NotificationService.initialize();
        NotificationService.showNotification(id: key.hashCode, title: title, body: body);
        
        await prefs.reload();
        final alertsStr = prefs.getStringList('saved_alerts') ?? [];
        final newAlert = {'type': type, 'title': title, 'body': body, 'id': DateTime.now().millisecondsSinceEpoch.toString()};
        alertsStr.add(jsonEncode(newAlert));
        if (alertsStr.length > 50) alertsStr.removeAt(0);
        await prefs.setStringList('saved_alerts', alertsStr);
      }
    }

    if (event.snapshot.value == null) {
      // Device is offline or no data
      try {
        bgOfflineTimer?.cancel();
        await fire('device_offline', 'danger', '🔴 Device Offline', 'Device not connected to the internet. Check device wifi connection.');
      } catch (_) {}
      return;
    }

    try {
      // Data received, reset the offline timer
      bgOfflineTimer?.cancel();
      bgOfflineTimer = Timer(const Duration(seconds: 30), () async {
        await fire('device_offline', 'danger', '🔴 Device Offline', 'Device not connected to the internet. Check device wifi connection.');
      });

      final map = Map<String, dynamic>.from(event.snapshot.value as Map);
      final d = DeviceData.fromMap(map);
      
      if (d.internalTemp < 2)  await fire('over_cool', 'danger',  '🧊 Overcooling Alert',   'Internal compartment is getting overcooled.');
      if (d.internalTemp > 8)  await fire('over_heat', 'danger',  '🔥 Overheating Alert',   'Internal compartment is getting overheated.');
      if (d.externalTemp > 25) await fire('ext_heat',  'warning', '☀️ High External Heat',   'High external heat detected. Please change the device location.');
      
    } catch (e) {
      // Ignore background errors
    }
  });
}
