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

class UsageEventsFetcher {
  static const _channel = MethodChannel('time_spy/usage_events');

  static Future<Map<String, int>> getRecentApps(int sinceMillis) async {
    final res = await _channel.invokeMethod('getRecentForegroundApps', {
      'since': sinceMillis,
    });
    final map = <String, int>{};
    if (res is Map) {
      res.forEach((key, value) {
        if (value is int)
          map[key] = value;
        else if (value is double)
          map[key] = value.toInt();
        else if (value is String) {
          final v = int.tryParse(value);
          if (v != null) map[key] = v;
        }
      });
    }
    return map;
  }
}
