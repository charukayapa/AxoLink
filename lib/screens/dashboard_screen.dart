import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/device_data.dart';

import '../widgets/dual_chart.dart';

class DashboardScreen extends StatelessWidget {
  final String deviceId;
  final DeviceData? sysData;
  final List<double> intH;
  final List<double> extH;
  final bool isWeb;
  final bool isLoading;

  const DashboardScreen({super.key, required this.deviceId, this.sysData, required this.intH, required this.extH, this.isWeb = false, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 16),
            Text('Connecting to device…', style: TextStyle(color: AppColors.textSub, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    if (sysData == null) {
      return SingleChildScrollView(
        padding: EdgeInsets.only(left: 24, right: 24, top: 40, bottom: isWeb ? 40 : 130),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.danger),
                ),
                const SizedBox(height: 24),
                const Text('Device Offline', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 12),
                const Text(
                  'We are unable to receive real-time data from this device. Please check the following:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSub, height: 1.5),
                ),
                const SizedBox(height: 32),
                
                // Card 1: Wi-Fi Issue
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
                    ]
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.wifi_find_rounded, color: AppColors.accent, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Wi-Fi Disconnected', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textMain)),
                            SizedBox(height: 6),
                            Text('Device not connected to the internet. Check device wifi connection.', style: TextStyle(fontSize: 13, color: AppColors.textSub, height: 1.4)),
                            SizedBox(height: 12),
                            Text('Tip: Use the mobile app Settings > Wi-Fi Captive Portal to reconnect.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent, height: 1.4)),
                          ]
                        ),
                      )
                    ]
                  )
                ),
                const SizedBox(height: 16),
                
                // Card 2: Power Issue
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
                    ]
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.battery_alert_rounded, color: AppColors.warning, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Or device Turned Off', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textMain)),
                            SizedBox(height: 6),
                            Text('The device might be powered down or out of battery.', style: TextStyle(fontSize: 13, color: AppColors.textSub, height: 1.4)),
                            SizedBox(height: 12),
                            Text('Tip: Check the physical power switch and battery level on the device.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning, height: 1.4)),
                          ]
                        ),
                      )
                    ]
                  )
                ),
                const SizedBox(height: 32),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text('Device ID: $deviceId', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final d = sysData!;
    final ai = getStatus(d.aiStatus);
    final tColor = d.internalTemp < 2 ? AppColors.accent : d.internalTemp > 8 ? AppColors.danger : AppColors.success;

    final ccColor = d.climateControl == 'Cooling' ? AppColors.accent
      : d.climateControl == 'Heating' ? const Color(0xFFFF6B35) : const Color(0xFF8B95B0);

    final screenWidth = MediaQuery.of(context).size.width;
    final contentPadding = isWeb ? 40.0 : 44.0; 
    final cardPadding = 48.0; 
    final availableWidth = screenWidth - contentPadding - cardPadding;

    final chartWidth = isWeb ? 560.0 : availableWidth;
    final chartHeight = isWeb ? 140.0 : 100.0;
    // Use a slightly smaller width to ensure 2 columns fit with spacing on all mobile screens
    final rowSpacing = isWeb ? 16.0 : 10.0;
    final w = isWeb ? 220.0 : (screenWidth - contentPadding - rowSpacing - 2) / 2;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 10,
        right: isWeb ? 20 : 10,
        bottom: isWeb ? 40 : 130,
        top: 10
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWeb ? 1100 : double.infinity),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Hero Temperature Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(children: [
              // Glow Effect (Matches Image 2 semi-circle style)
              Positioned(
                right: isWeb ? -40 : -50, 
                top: isWeb ? -40 : -55, 
                child: Container(
                  width: isWeb ? 200 : 170, 
                  height: isWeb ? 200 : 170,
                  decoration: BoxDecoration(
                    color: const Color(0x1A0055FF), // Slightly darker blue for depth
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(color: const Color(0x150064FF), blurRadius: 40, spreadRadius: 10),
                    ],
                  ),
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('INTERNAL TEMPERATURE', style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.internalTemp.toStringAsFixed(1), style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: tColor, letterSpacing: -1, height: 1.1)),
                  Padding(padding: const EdgeInsets.only(top: 6, left: 4), child: Text('°C', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.accent))),
                ]),
                const SizedBox(height: 4),
                Text('Safe zone: 2°C – 8°C  •  ${d.isSafe ? '✅ Within range' : '⚠️ Out of range'}', style: TextStyle(fontSize: 12, color: const Color(0xFF3D5070))),
                const SizedBox(height: 18),

                // Legend
                Row(children: [
                  _legend(AppColors.accent, 'Internal'),
                  const SizedBox(width: 4),
                  _legend(AppColors.warning, 'External'),
                  const SizedBox(width: 4),
                  _legendSafe(),
                ]),
                const SizedBox(height: 16),

                Center(child: DualChart(intH: intH, extH: extH, width: chartWidth, height: chartHeight)),
              ]),
            ]),
          ),

          // Alert Banners
          if (d.isOvercooling) _alertBanner('🧊', 'Overcooling Alert', 'Internal compartment is getting overcooled.', AppColors.infoBg, AppColors.infoBorder, AppColors.accent),
          if (d.isOverheating) _alertBanner('🔥', 'Overheating Alert', 'Internal compartment is getting overheated.', AppColors.dangerBg, AppColors.dangerBorder, AppColors.danger),
          if (d.isExternalHot) _alertBanner('☀️', 'High External Heat', 'High external heat detected. Please change the device location.', AppColors.warningBg, AppColors.warningBorder, AppColors.warning),

          // Metric Grid - use fixed-height cards in a 2-column layout
          const SizedBox(height: 16),
          _buildMetricGrid(d, ai, ccColor, w, rowSpacing),

          // Bottom strip
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('DEVICE ID', style: TextStyle(fontSize: 10, color: AppColors.textLabel, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(deviceId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFC0C8E0), fontFamily: 'monospace')),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('UPDATES', style: TextStyle(fontSize: 10, color: AppColors.textLabel, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(width: 7, height: 7, decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(3.5))),
                  const SizedBox(width: 6),
                  const Text('Live', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.success)),
                ]),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  /// Builds a responsive metric grid. Desktop stretches 4 items horizontally, mobile uses a 2x2 grid.
  Widget _buildMetricGrid(DeviceData d, AiStatusStyle ai, Color ccColor, double w, double spacing) {
    if (isWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 850) {
            // Desktop: Stretch 4 columns evenly across available width
            return IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(child: _metricCardFlex('🌡 EXTERNAL TEMP', d.externalTemp.toStringAsFixed(1), '°C', d.isExternalHot ? AppColors.warning : AppColors.textMain, d.isExternalHot ? '⚠ Above 25°C' : 'Normal range', d.isExternalHot ? AppColors.warning : AppColors.textLabel)),
                  SizedBox(width: spacing),
                  Expanded(child: _metricCardFlexHumidity('💧 HUMIDITY', d.internalHumidity.toStringAsFixed(1), '%', AppColors.humidity, d.internalHumidity > 80 ? '⚠ High humidity' : 'Normal', d.internalHumidity > 80 ? AppColors.warning : AppColors.textLabel)),
                  SizedBox(width: spacing),
                  Expanded(child: _metricCardClimate(d, ccColor, null)),
                  SizedBox(width: spacing),
                  Expanded(child: _metricCardAI(d, ai, null)),
                ],
              ),
            );
          } else {
            // Smaller web screens: Use 2x2 grid
            return Column(children: [
              IntrinsicHeight(
                child: Row(children: [
                  Expanded(child: _metricCardFlex('🌡 EXTERNAL TEMP', d.externalTemp.toStringAsFixed(1), '°C', d.isExternalHot ? AppColors.warning : AppColors.textMain, d.isExternalHot ? '⚠ Above 25°C' : 'Normal range', d.isExternalHot ? AppColors.warning : AppColors.textLabel)),
                  SizedBox(width: spacing),
                  Expanded(child: _metricCardFlexHumidity('💧 HUMIDITY', d.internalHumidity.toStringAsFixed(1), '%', AppColors.humidity, d.internalHumidity > 80 ? '⚠ High humidity' : 'Normal', d.internalHumidity > 80 ? AppColors.warning : AppColors.textLabel)),
                ]),
              ),
              SizedBox(height: spacing),
              IntrinsicHeight(
                child: Row(children: [
                  Expanded(child: _metricCardClimate(d, ccColor, null)),
                  SizedBox(width: spacing),
                  Expanded(child: _metricCardAI(d, ai, null)),
                ]),
              ),
            ]);
          }
        },
      );
    }

    // Mobile: use rows with Expanded for guaranteed 2-column fit
    return Column(children: [
      IntrinsicHeight(
        child: Row(children: [
          Expanded(child: _metricCardFlex('🌡 EXTERNAL TEMP', d.externalTemp.toStringAsFixed(1), '°C', d.isExternalHot ? AppColors.warning : AppColors.textMain, d.isExternalHot ? '⚠ Above 25°C' : 'Normal range', d.isExternalHot ? AppColors.warning : AppColors.textLabel)),
          SizedBox(width: spacing),
          Expanded(child: _metricCardFlexHumidity('💧 HUMIDITY', d.internalHumidity.toStringAsFixed(1), '%', AppColors.humidity, d.internalHumidity > 80 ? '⚠ High humidity' : 'Normal', d.internalHumidity > 80 ? AppColors.warning : AppColors.textLabel)),
        ]),
      ),
      const SizedBox(height: 10),
      IntrinsicHeight(
        child: Row(children: [
          Expanded(child: _metricCardClimate(d, ccColor, null)),
          SizedBox(width: spacing),
          Expanded(child: _metricCardAI(d, ai, null)),
        ]),
      ),
    ]);
  }

  Widget _legend(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(children: [
        Container(width: 14, height: 2, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _legendSafe() {
    return Row(children: [
      Container(
        width: 14, height: 9,
        decoration: BoxDecoration(
          color: const Color(0x144CAF50),
          border: Border.all(color: const Color(0x404CAF50)),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      const Text('Safe zone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0x994CAF50))),
    ]);
  }

  Widget _alertBanner(String emoji, String title, String body, Color bg, Color border, Color titleColor) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(15)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: titleColor)),
          const SizedBox(height: 2),
          Text(body, style: const TextStyle(fontSize: 12, color: Color(0xFF8090A8), height: 1.5)),
        ])),
      ]),
    );
  }

  /// Flex metric card - uses parent Expanded for width
  Widget _metricCardFlex(String label, String value, String unit, Color valueColor, String sub, Color subColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLabel, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        const SizedBox(height: 12),
        RichText(text: TextSpan(children: [
          TextSpan(text: value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: valueColor, letterSpacing: -0.5)),
          TextSpan(text: unit, style: const TextStyle(fontSize: 14, color: AppColors.textSub, fontWeight: FontWeight.w600)),
        ])),
        const SizedBox(height: 6),
        Text(sub, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: subColor)),
      ]),
    );
  }

  /// Flex humidity card (mobile) - identical structure for IntrinsicHeight matching
  Widget _metricCardFlexHumidity(String label, String value, String unit, Color valueColor, String sub, Color subColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLabel, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        const SizedBox(height: 12),
        RichText(text: TextSpan(children: [
          TextSpan(text: value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: valueColor, letterSpacing: -0.5)),
          TextSpan(text: unit, style: const TextStyle(fontSize: 14, color: AppColors.textSub, fontWeight: FontWeight.w600)),
        ])),
        const SizedBox(height: 6),
        Text(sub, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: subColor)),
      ]),
    );
  }

  Widget _metricCardClimate(DeviceData d, Color ccColor, double? w) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: ccColor.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('⚙️ CLIMATE CONTROL', style: TextStyle(fontSize: 10, color: AppColors.textLabel, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        const SizedBox(height: 12),
        Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: ccColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(d.climateControl == 'Cooling' ? Icons.ac_unit : d.climateControl == 'Heating' ? Icons.local_fire_department_outlined : Icons.wifi, size: 18, color: ccColor),
          ),
          const SizedBox(width: 10),
          Text(d.climateControl.isEmpty ? 'Idle' : d.climateControl, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ccColor)),
        ]),
        const SizedBox(height: 6),
        const Text('Relay status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textLabel)),
      ]),
    );
    if (w != null) return SizedBox(width: w, child: card);
    return card;
  }

  Widget _metricCardAI(DeviceData d, AiStatusStyle ai, double? w) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: ai.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🤖 DEVICE STATUS', style: TextStyle(fontSize: 10, color: AppColors.textLabel, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        const SizedBox(height: 12),
        Text(d.aiStatus.isEmpty ? 'Idle' : d.aiStatus, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ai.color)),
        const SizedBox(height: 6),
        // Compact: Scatter & Trans on one line
        Text('S: ${d.scattering.toStringAsFixed(4)}  •  T: ${d.transmission.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textLabel)),
      ]),
    );
    if (w != null) return SizedBox(width: w, child: card);
    return card;
  }
}
