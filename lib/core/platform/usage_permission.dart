import 'package:flutter/services.dart';

class UsagePermission {
  static const MethodChannel _channel =
      MethodChannel('usage_permission_channel');

  static Future<bool> isUsagePermissionGranted() async {
    final granted =
        await _channel.invokeMethod<bool>('isUsagePermissionGranted');
    return granted ?? false;
  }

  static Future<void> openUsageSettings() async {
    await _channel.invokeMethod('openUsageSettings');
  }
}
