import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';

/// Dual-line chart showing internal and external temperature history
class DualChart extends StatelessWidget {
  final List<double> intH;
  final List<double> extH;
  final double width;
  final double height;

  const DualChart({super.key, required this.intH, required this.extH, this.width = 320, this.height = 100});

  @override
  Widget build(BuildContext context) {
    final allVals = [...intH, ...extH];
    if (allVals.length < 2) return const SizedBox.shrink();

    final mn = allVals.reduce((a, b) => a < b ? a : b) - 1.5;
    final mx = allVals.reduce((a, b) => a > b ? a : b) + 1.5;

    return SizedBox(
      width: width,
      height: height,
      child: LineChart(LineChartData(
        minY: mn,
        maxY: mx,
        clipData: const FlClipData.all(),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            HorizontalRangeAnnotation(
              y1: 2, 
              y2: 8, 
              color: const Color(0x144CAF50), // rgba(76,175,80,0.08)
            ),
          ],
        ),
        lineBarsData: [
          // External temp line
          LineChartBarData(
            spots: extH.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.warning,
            barWidth: 1.8,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => idx == extH.length - 1
                ? FlDotCirclePainter(radius: 3.5, color: AppColors.warning, strokeWidth: 2, strokeColor: AppColors.bg)
                : FlDotCirclePainter(radius: 0, color: Colors.transparent),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [AppColors.warning.withOpacity(0.18), AppColors.warning.withOpacity(0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Internal temp line
          LineChartBarData(
            spots: intH.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.accent,
            barWidth: 2.2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => idx == intH.length - 1
                ? FlDotCirclePainter(radius: 4, color: AppColors.accent, strokeWidth: 2, strokeColor: AppColors.bg)
                : FlDotCirclePainter(radius: 0, color: Colors.transparent),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [AppColors.accent.withOpacity(0.3), AppColors.accent.withOpacity(0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      )),
    );
  }
}
