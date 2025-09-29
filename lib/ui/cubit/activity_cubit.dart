import 'dart:async';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:app_usage/app_usage.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:time_spy/core/platform/usage_permission.dart';
import 'package:time_spy/models/app_info_ext.dart';

part 'activity_state.dart';

class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit() : super(ActivityInitial());

  static const MethodChannel _channel = MethodChannel('time_spy/usage_events');
  Timer? _refreshTimer;

  void init() {
    fetchInitialStats();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => refreshInBackground(),
    );
  }

  void dispose() {
    _refreshTimer?.cancel();
  }

  Future<void> fetchInitialStats() async {
    emit(ActivityLoading());

    final permissionGranted = await UsagePermission.isUsagePermissionGranted();
    if (!permissionGranted) {
      emit(ActivityPermissionRequired());
      return;
    }

    await _loadAndEmit();
  }

  Future<void> refreshInBackground() async {
    final permissionGranted = await UsagePermission.isUsagePermissionGranted();
    if (!permissionGranted) return;

    if (state is! ActivityLoaded) return;

    await _loadAndEmit();
  }

  Future<void> _loadAndEmit() async {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 14));
    final sinceMillis = start.millisecondsSinceEpoch;

    try {
      final usageList = await AppUsage().getAppUsage(start, end);
      final recentMap = await _getRecentApps(sinceMillis);

      List<AppInfoExt> combined = [];

      for (var info in usageList) {
        final lastFgMillis = recentMap[info.packageName];
        final lastFg = lastFgMillis != null
            ? DateTime.fromMillisecondsSinceEpoch(lastFgMillis)
            : null;
        final category = await _getAppCategory(info.packageName);
        final launchCount = await _getLaunchCount(info.packageName);
        final icon = await _getAppIcon(info.packageName);

        combined.add(AppInfoExt(
          packageName: info.packageName,
          appName: info.appName,
          usage: info.usage,
          lastForeground: lastFg,
          category: category,
          launchCount: launchCount,
          icon: icon,
        ));
      }

      for (var entry in recentMap.entries) {
        if (!combined.any((e) => e.packageName == entry.key)) {
          final category = await _getAppCategory(entry.key);
          final launchCount = await _getLaunchCount(entry.key);
          final icon = await _getAppIcon(entry.key);

          combined.add(AppInfoExt(
            packageName: entry.key,
            appName: entry.key,
            usage: Duration.zero,
            lastForeground: DateTime.fromMillisecondsSinceEpoch(entry.value),
            category: category,
            launchCount: launchCount,
            icon: icon,
          ));
        }
      }

      combined.sort((a, b) {
        final ta = a.lastForeground?.millisecondsSinceEpoch ?? 0;
        final tb = b.lastForeground?.millisecondsSinceEpoch ?? 0;
        return tb.compareTo(ta);
      });

      emit(ActivityLoaded(apps: combined));
    } catch (e) {
      emit(ActivityError('Failed to load usage stats'));
    }
  }

  Future<Map<String, int>> _getRecentApps(int sinceMillis) async {
    final res = await _channel
        .invokeMethod('getRecentForegroundApps', {'since': sinceMillis});
    return Map<String, int>.from(res);
  }

  Future<String> _getAppCategory(String packageName) async {
    try {
      final category = await _channel
          .invokeMethod<String>('getAppCategory', {'packageName': packageName});
      return category ?? 'Other';
    } catch (_) {
      return 'Other';
    }
  }

  Future<int> _getLaunchCount(String packageName) async {
    try {
      final count = await _channel
          .invokeMethod<int>('getLaunchCount', {'packageName': packageName});
      return count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<Uint8List?> _getAppIcon(String packageName) async {
    try {
      final iconBytes = await _channel
          .invokeMethod<Uint8List>('getAppIcon', {'packageName': packageName});
      return iconBytes;
    } catch (_) {
      return null;
    }
  }
}
