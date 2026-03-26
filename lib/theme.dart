import 'package:flutter/material.dart';

// ─── Design System ────────────────────────────────────────────────────────────
class AppColors {
  static const bg = Color(0xFF080B14);
  static const cardBg = Color(0x0AFFFFFF);       // rgba(255,255,255,0.04)
  static const cardBorder = Color(0x12FFFFFF);   // rgba(255,255,255,0.07)
  static const textMain = Color(0xFFF0F4FF);
  static const textSub = Color(0xFF4A5A78);
  static const textMuted = Color(0xFF2D3550);
  static const textLabel = Color(0xFF3D4760);
  static const accent = Color(0xFF4FC3F7);
  static const accentDark = Color(0xFF0060FF);
  static const danger = Color(0xFFF44336);
  static const dangerBg = Color(0x17F44336);      // rgba(244,67,54,0.09)
  static const dangerBorder = Color(0x47F44336);  // rgba(244,67,54,0.28)
  static const success = Color(0xFF4CAF50);
  static const successBg = Color(0x144CAF50);     // rgba(76,175,80,0.08)
  static const warning = Color(0xFFFFB300);
  static const warningBg = Color(0x17FFB300);     // rgba(255,179,0,0.09)
  static const warningBorder = Color(0x47FFB300); // rgba(255,179,0,0.28)
  static const info = Color(0xFF4FC3F7);
  static const infoBg = Color(0x174FC3F7);        // rgba(79,195,247,0.09)
  static const infoBorder = Color(0x474FC3F7);    // rgba(79,195,247,0.28)
  static const humidity = Color(0xFFA78BFA);
  static const gradientStart = Color(0xFF0055FF);
  static const gradientEnd = Color(0xFF00BBFF);
  static const navBg = Color(0xF8081420);        // rgba(8,11,20,0.97)
}

// ─── AI Status Styles ─────────────────────────────────────────────────────────
class AiStatusStyle {
  final Color color;
  final Color bg;
  final Color border;
  const AiStatusStyle({required this.color, required this.bg, required this.border});
}

const Map<String, AiStatusStyle> statusStyles = {
  'Reading': AiStatusStyle(color: Color(0xFF4FC3F7), bg: Color(0x1F4FC3F7), border: Color(0x404FC3F7)), // rgba(79,195,247,0.12/0.25)
  'Safe':    AiStatusStyle(color: Color(0xFF4CAF50), bg: Color(0x1F4CAF50), border: Color(0x404CAF50)), // rgba(76,175,80,0.12/0.25)
  'Warning': AiStatusStyle(color: Color(0xFFFFB300), bg: Color(0x1FFFB300), border: Color(0x40FFB300)), // rgba(255,179,0,0.12/0.25)
  'Spoiled': AiStatusStyle(color: Color(0xFFF44336), bg: Color(0x1FF44336), border: Color(0x40F44336)), // rgba(244,67,54,0.12/0.25)
  'Idle':    AiStatusStyle(color: Color(0xFF8B95B0), bg: Color(0x1A8B95B0), border: Color(0x338B95B0)), // rgba(139,149,176,0.1/0.2)
  'Offline': AiStatusStyle(color: Color(0xFFEF5350), bg: Color(0x26EF5350), border: Color(0x4DEF5350)), // Red distinct styling
};

AiStatusStyle getStatus(String? s) => statusStyles[s] ?? statusStyles['Reading']!;

// ─── SVG Icon Path Data ───────────────────────────────────────────────────────
class IconPaths {
  static const shield      = 'M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z';
  static const wifi        = 'M5 12.55a11 11 0 0 1 14.08 0 M1.42 9a16 16 0 0 1 21.16 0 M8.53 16.11a6 6 0 0 1 6.95 0 M12 20h.01';
  static const device      = 'M4 8V4a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v4 M4 16v4a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-4 M9 12h6';
  static const eye         = 'M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z';
  static const eyeOff      = 'M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24M1 1l22 22';
  static const logout      = 'M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4 M16 17l5-5-5-5 M21 12H9';
  static const activity    = 'M22 12h-4l-3 9L9 3l-3 9H2';
  static const droplet     = 'M12 22a7 7 0 0 0 7-7c0-2-1-3.9-3-5.5s-3.5-4-4-6.5c-.5 2.5-2 4.9-4 6.5C6 11.1 5 13 5 15a7 7 0 0 0 7 7z';
  static const bell        = 'M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9 M13.73 21a2 2 0 0 1-3.46 0';
  static const arrow       = 'M9 18l6-6-6-6';
  static const snowflake   = 'M12 2v20 M2 12h20 M4.93 4.93l14.14 14.14 M19.07 4.93L4.93 19.07';
  static const flame       = 'M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z';
  static const thermometer = 'M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z';
  static const home        = 'M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z M9 22V12h6v10';
  static const google      = 'M4 9c.7-1 2-2 3.8-2 1.4 0 2.5.5 3.3 1.3l2.4-2.4C12 4.3 10.1 3.5 8 3.5 4 3.5 1 6 1 9.5s3 6 7 6c4 0 7-2.6 7-6.5H8v3h4c-.5 2-2.5 3.5-4.5 3.5C5.5 15.5 3.5 13.5 3.5 11c0-.7.1-1.4.5-2z';
  static const close       = 'M18 6L6 18 M6 6l12 12';
  static const sync_       = 'M21 2v6h-6 M3 12a9 9 0 0 1 15-6.7L21 8 M3 22v-6h6 M21 12A9 9 0 0 1 6 18.7L3 16';
  static const settings    = 'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z';
}
