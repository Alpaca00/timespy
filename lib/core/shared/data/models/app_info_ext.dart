import 'dart:typed_data';

class AppInfoExt {
  final String packageName;
  final String appName;
  final Duration usage;
  final DateTime? lastForeground;
  final String category;
  final int launchCount;
  final Uint8List? icon;

  const AppInfoExt({
    required this.packageName,
    required this.appName,
    required this.usage,
    this.lastForeground,
    required this.category,
    required this.launchCount,
    this.icon,
  });
}
