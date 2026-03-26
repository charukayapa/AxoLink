import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/device_data.dart';
import '../supabase_config.dart';

class DatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Listen to device data in real-time (from Firebase RTDB — IoT data)
  StreamSubscription<DatabaseEvent> listenToDevice(
    String deviceId,
    void Function(DeviceData? data) onData,
  ) {
    final ref = _db.ref('Devices/$deviceId');
    return ref.onValue.listen((event) {
      final val = event.snapshot.value;
      if (val != null && val is Map) {
        onData(DeviceData.fromMap(val));
      } else {
        onData(null); // Device offline / no data
      }
    });
  }

  /// Register a device under a user (stored in Supabase)
  Future<void> registerDevice(String uid, String deviceId) async {
    await _supabase.from('user_devices').upsert({
      'user_id': uid,
      'device_id': deviceId,
      'added_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get user's saved devices (from Supabase)
  Future<List<String>> getSavedDevices(String uid) async {
    final response = await _supabase
        .from('user_devices')
        .select('device_id')
        .eq('user_id', uid);
    return (response as List)
        .map((row) => row['device_id'] as String)
        .toList();
  }
}
