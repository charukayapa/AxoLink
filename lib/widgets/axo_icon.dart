import 'package:flutter/material.dart';

/// Custom icon widget that renders SVG path data like the React Native version.
/// Uses CustomPainter with simple stroke-based rendering.
class AxoIcon extends StatelessWidget {
  final String data;
  final double size;
  final Color color;
  final double strokeWidth;

  const AxoIcon({
    super.key,
    required this.data,
    this.size = 24,
    this.color = const Color(0xFFF0F4FF),
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    // Since Flutter doesn't natively parse SVG path strings in CustomPaint,
    // we use Material Icons as a practical approach for the Flutter version.
    // Map icon path strings to matching Material icons.
    return Icon(_mapToMaterialIcon(data), size: size, color: color);
  }

  static IconData _mapToMaterialIcon(String pathData) {
    if (pathData.contains('22s8-4 8-10V5')) return Icons.shield_outlined;
    if (pathData.contains('12.55a11')) return Icons.wifi;
    if (pathData.contains('4 8V4a2')) return Icons.devices;
    if (pathData.contains('1 12s4-8 11-8') && !pathData.contains('22 22')) return Icons.visibility_outlined;
    if (pathData.contains('17.94 17.94')) return Icons.visibility_off_outlined;
    if (pathData.contains('9 21H5a2 2')) return Icons.logout;
    if (pathData.contains('22 12h-4l-3 9')) return Icons.show_chart;
    if (pathData.contains('12 22a7 7')) return Icons.water_drop_outlined;
    if (pathData.contains('18 8A6 6')) return Icons.notifications_outlined;
    if (pathData.contains('9 18l6-6')) return Icons.chevron_right;
    if (pathData.contains('12 2v20 M2 12h20')) return Icons.ac_unit;
    if (pathData.contains('8.5 14.5A2.5')) return Icons.local_fire_department_outlined;
    if (pathData.contains('14 14.76V3.5')) return Icons.thermostat_outlined;
    if (pathData.contains('3 9l9-7')) return Icons.home_outlined;
    if (pathData.contains('4 9c.7-1')) return Icons.g_mobiledata;
    if (pathData.contains('18 6L6 18')) return Icons.close;
    if (pathData.contains('21 2v6h-6')) return Icons.sync;
    if (pathData.contains('12 15a3 3')) return Icons.settings;
    return Icons.circle;
  }
}
