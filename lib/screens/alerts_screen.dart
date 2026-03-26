import 'package:flutter/material.dart';
import '../theme.dart';

class AlertItem {
  final String type;
  final String title;
  final String body;
  final String id;
  AlertItem({required this.type, required this.title, required this.body, String? id}) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
  
  Map<String, dynamic> toJson() => {'type': type, 'title': title, 'body': body, 'id': id};
  factory AlertItem.fromJson(Map<String, dynamic> json) => AlertItem(type: json['type'], title: json['title'], body: json['body'], id: json['id']);

  String get timeAgo {
    final ms = int.tryParse(id) ?? 0;
    if (ms == 0) return '';
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class AlertsScreen extends StatelessWidget {
  final String deviceId;
  final List<AlertItem> liveAlerts;
  final bool isWeb;

  const AlertsScreen({super.key, required this.deviceId, this.liveAlerts = const [], this.isWeb = false});

  static const _typeColors = {
    'warning': AppColors.warning,
    'safe': AppColors.success,
    'info': AppColors.accent,
    'danger': AppColors.danger,
  };
  static const _typeBg = {
    'warning': Color(0x14FFB300),
    'safe': Color(0x144CAF50),
    'info': Color(0x144FC3F7),
    'danger': Color(0x14F44336),
  };

  @override
  Widget build(BuildContext context) {
    final allAlerts = liveAlerts.toList();

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 10, 
        right: isWeb ? 20 : 10, 
        bottom: isWeb ? 40 : 130, 
        top: 10
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWeb ? 800 : double.infinity),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Alerts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: Colors.white)),
          const SizedBox(height: 4),
          Text(deviceId.isEmpty ? 'No Device' : deviceId, style: const TextStyle(fontSize: 12, color: AppColors.textLabel, fontFamily: 'monospace')),
          const SizedBox(height: 22),

          if (allAlerts.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: Opacity(opacity: 0.5, child: Text('No alerts recorded yet.', style: TextStyle(color: AppColors.textSub, fontSize: 14)))),
            )
          else
            ...List.generate(allAlerts.length, (i) {
              final a = allAlerts[i];
              final c = _typeColors[a.type] ?? AppColors.accent;
              final bg = _typeBg[a.type] ?? const Color(0x144FC3F7);
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Timeline dot + line
                SizedBox(width: 24, child: Column(children: [
                  const SizedBox(height: 5),
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(5))),
                  if (i < allAlerts.length - 1)
                    Container(width: 1, height: 30, margin: const EdgeInsets.only(top: 4), color: Colors.white.withValues(alpha: 0.05)),
                ])),
                const SizedBox(width: 8),
                // Card
                Expanded(child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: EdgeInsets.all(isWeb ? 16 : 12),
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border.all(color: c.withValues(alpha: 0.16)),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(a.title.isNotEmpty ? a.title : a.type, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                      Text(a.timeAgo, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ]),
                    const SizedBox(height: 4),
                    Text(a.body, style: const TextStyle(fontSize: 13, color: Color(0xFFB0BAD0), height: 1.5)),
                  ]),
                )),
              ]);
            }),
        ]),
      ),
    );
  }
}
