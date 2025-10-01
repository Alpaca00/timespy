import 'dart:async';

import 'package:app_usage/app_usage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/platform/usage_permission.dart';
import '../../../../core/shared/data/models/app_info_ext.dart';

part 'activity_state.dart';

class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit() : super(ActivityState.initial());

  static const MethodChannel _channel = MethodChannel('time_spy/usage_events');
  Timer? _refreshTimer;

  Future<void> init() async {
    emit(state.copyWith(isLoading: true));

    final prefs = await SharedPreferences.getInstance();
    final savedFilter = prefs.getInt('days_filter') ?? 7;

    final granted = await UsagePermission.isUsagePermissionGranted();
    if (!granted) {
      emit(state.copyWith(
        isLoading: false,
        permissionRequired: true,
        daysFilter: savedFilter,
      ));
      return;
    }

    final apps = await _loadApps();
    emit(state.copyWith(
      isLoading: false,
      apps: apps,
      daysFilter: savedFilter,
    ));

    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refresh();
    });
  }

  Future<void> refresh() async {
    final granted = await UsagePermission.isUsagePermissionGranted();
    if (!granted) return;
    final apps = await _loadApps();
    emit(state.copyWith(apps: apps));
  }

  Future<void> updateSearch(String query) {
    emit(state.copyWith(searchQuery: query));
    return Future.value();
  }

  Future<void> updateFilter(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('days_filter', value);
    emit(state.copyWith(daysFilter: value));
  }

  Future<void> requestPermissionFlow() async {
    final granted = await UsagePermission.isUsagePermissionGranted();
    if (granted) {
      final apps = await _loadApps();
      emit(state.copyWith(
        apps: apps,
        permissionRequired: false,
        showPermissionButton: false,
        dialogShown: false,
      ));
    } else {
      emit(state.copyWith(showPermissionButton: true));
    }
  }

  void markDialogAsShown() {
    emit(state.copyWith(dialogShown: true));
  }

  void onPermissionDialogCancelled() {
    emit(state.copyWith(
      showPermissionButton: true,
      permissionRequired: false,
      dialogShown: false,
    ));
  }

  Future<void> openUsageSettings() async {
    await UsagePermission.openUsageSettings();
  }

  List<AppInfoExt> get filteredApps {
    final query = state.searchQuery.toLowerCase();
    return query.isEmpty
        ? state.apps
        : state.apps
            .where((a) => a.appName.toLowerCase().contains(query))
            .toList();
  }

  Future<List<AppInfoExt>> _loadApps() async {
    try {
      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 14));
      final sinceMillis = start.millisecondsSinceEpoch;

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

      return combined;
    } catch (e) {
      emit(state.copyWith(error: 'Failed to load usage stats'));
      return [];
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

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}
