/// Data model for sensor readings from Firebase Realtime Database
class DeviceData {
  final double internalTemp;
  final double externalTemp;
  final double internalHumidity;
  final String climateControl;
  final String aiStatus;
  final double scattering;
  final double transmission;

  DeviceData({
    required this.internalTemp,
    required this.externalTemp,
    required this.internalHumidity,
    required this.climateControl,
    required this.aiStatus,
    required this.scattering,
    required this.transmission,
  });

  factory DeviceData.fromMap(Map<dynamic, dynamic> map) {
    return DeviceData(
      internalTemp: (map['InternalTemp'] ?? 0).toDouble(),
      externalTemp: (map['ExternalTemp'] ?? 0).toDouble(),
      internalHumidity: (map['InternalHumidity'] ?? 0).toDouble(),
      climateControl: (map['ClimateControl'] ?? 'Idle').toString(),
      aiStatus: (map['AI_Status'] ?? 'Idle').toString(),
      scattering: (map['Scattering'] ?? 0).toDouble(),
      transmission: (map['Transmission'] ?? 0).toDouble(),
    );
  }

  bool get isSafe => internalTemp >= 2 && internalTemp <= 8;
  bool get isOvercooling => internalTemp < 2;
  bool get isOverheating => internalTemp > 8;
  bool get isExternalHot => externalTemp > 25;
}
