import 'package:flutter/services.dart';

class UsageEventsFetcher {
  static const _channel = MethodChannel('time_spy/usage_events');

  static Future<Map<String, int>> getRecentApps(int sinceMillis) async {
    final res = await _channel.invokeMethod('getRecentForegroundApps', {
      'since': sinceMillis,
    });

    final map = <String, int>{};

    if (res is Map) {
      res.forEach((key, value) {
        if (value is int) {
          map[key] = value;
        } else if (value is double) {
          map[key] = value.toInt();
        } else if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) map[key] = parsed;
        }
      });
    }

    return map;
  }
}
