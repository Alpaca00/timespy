import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:flutter/services.dart';
import 'package:time_spy/core/platform/usage_permission.dart';

import 'ui/widgets/glass_card_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Spy',
      theme: ThemeData.light(),
      home: const AppUsagePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppUsagePage extends StatefulWidget {
  const AppUsagePage({super.key});

  @override
  State<AppUsagePage> createState() => _AppUsagePageState();
}

class _AppUsagePageState extends State<AppUsagePage> {
  List<_AppInfoExt> _usageStatsExt = [];
  Timer? _refreshTimer;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const MethodChannel _channel = MethodChannel('time_spy/usage_events');

  @override
  void initState() {
    super.initState();
    _fetchUsageStats();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _fetchUsageStats());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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

  Future<bool> _showUsagePermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white.withOpacity(0.05),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.privacy_tip_rounded, size: 56, color: Colors.cyanAccent.withOpacity(0.85)),
                const SizedBox(height: 20),
                const Text(
                  'Usage Permission Required',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: Colors.white,
                    fontFamily: 'Saira',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                const Text(
                  "TimeSpy needs access to your device's usage stats to show how long and how often apps are used.\n\nThis permission is used locally and never leaves your device.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontFamily: 'Saira',
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop(true);
                        },
                        icon: const Icon(Icons.open_in_new, color: Colors.black),
                        label: const Text(
                          'Open Settings',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == true) {
      await UsagePermission.openUsageSettings();
      return true;
    }

    return false;
  }

  Future<void> _fetchUsageStats() async {
    // Check permission
    if (!await UsagePermission.isUsagePermissionGranted()) {
      final confirmed = await _showUsagePermissionDialog(context);
      if (confirmed) {
        // Wait a moment before rechecking
        await Future.delayed(const Duration(seconds: 2));
        if (!await UsagePermission.isUsagePermissionGranted()) {
          return; // Still no permission
        }
      } else {
        return; // User dismissed the dialog
      }
    }

    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 2));
    final sinceMillis = start.millisecondsSinceEpoch;

    final usageList = await AppUsage().getAppUsage(start, end);
    final recentMap = await _getRecentApps(sinceMillis);

    List<_AppInfoExt> combined = [];

    for (var info in usageList) {
      final lastFgMillis = recentMap[info.packageName];
      final lastFg = lastFgMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(lastFgMillis)
          : null;
      final category = await _getAppCategory(info.packageName);
      final launchCount = await _getLaunchCount(info.packageName);
      final icon = await _getAppIcon(info.packageName);

      combined.add(_AppInfoExt(
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

        combined.add(_AppInfoExt(
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

    setState(() => _usageStatsExt = combined);
  }


  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} '
        '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);

    final hoursText = h == 1 ? '1 hr' : '$h hrs';
    final minutesText = m == 1 ? '1 min' : '$m mins';

    if (h > 0 && m > 0) {
      return '$hoursText $minutesText';
    } else if (h > 0) {
      return hoursText;
    } else {
      return minutesText;
    }
  }


  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                fontFamily: 'RobotoMono',
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final activeThreshold = now.subtract(const Duration(hours: 12));

    List<_AppInfoExt> visibleApps;

    if (_searchQuery.isNotEmpty) {
      visibleApps = _usageStatsExt
          .where((app) => app.appName.toLowerCase().contains(_searchQuery))
          .toList();
    } else {
      visibleApps = _usageStatsExt;
    }

    final activeApps = visibleApps
        .where((app) =>
            app.lastForeground != null &&
            app.lastForeground!.isAfter(activeThreshold))
        .toList();

    final inactiveApps = visibleApps
        .where((app) =>
            app.lastForeground == null ||
            app.lastForeground!.isBefore(activeThreshold))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.08),
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.2),
        elevation: 0,
        centerTitle: true,
        title: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF74F2CE), Color(0xFF4D9DE0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'TimeSpy',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontFamily: 'Saira',
              letterSpacing: 1.5,
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            backgroundBlendMode: BlendMode.overlay,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      body: _usageStatsExt.isEmpty
          ? const Center(
              child: Text(
                'No data or permission not granted',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Saira',
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchUsageStats,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search apps...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFF4D9DE0)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Colors.white54),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                  if (activeApps.isNotEmpty) ...[
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        'Active Apps',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Saira',
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    ...activeApps.map(
                      (app) => GlassCard(
                        isActive: true,
                        child: ListTile(
                          leading: app.icon != null
                              ? Image.memory(app.icon!, width: 40, height: 40)
                              : const Icon(Icons.phone_android,
                                  color: Colors.white),
                          title: Text(
                            app.appName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow('Usage', _formatDuration(app.usage)),
                              _infoRow(
                                  'Last used',
                                  app.lastForeground != null
                                      ? _formatDateTime(app.lastForeground!)
                                      : '—'),
                              _infoRow('Category', app.category),
                              _infoRow('Launches', app.launchCount.toString()),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      ),
                    ),
                  ],
                  if (inactiveApps.isNotEmpty) ...[
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        'Inactive Apps',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          fontFamily: 'Saira',
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    ...inactiveApps.map(
                      (app) => GlassCard(
                        isActive: false,
                        child: ListTile(
                          leading: app.icon != null
                              ? Image.memory(app.icon!, width: 40, height: 40)
                              : const Icon(Icons.phone_android,
                                  color: Colors.grey),
                          title: Text(
                            app.appName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white70),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow('Usage', _formatDuration(app.usage)),
                              _infoRow(
                                  'Last used',
                                  app.lastForeground != null
                                      ? _formatDateTime(app.lastForeground!)
                                      : '—'),
                              _infoRow('Category', app.category),
                              _infoRow('Launches', app.launchCount.toString()),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _AppInfoExt {
  final String packageName;
  final String appName;
  final Duration usage;
  final DateTime? lastForeground;
  final String category;
  final int launchCount;
  final Uint8List? icon;

  _AppInfoExt({
    required this.packageName,
    required this.appName,
    required this.usage,
    this.lastForeground,
    required this.category,
    required this.launchCount,
    this.icon,
  });
}
