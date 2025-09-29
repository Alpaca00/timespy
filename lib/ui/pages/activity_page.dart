import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_spy/core/platform/usage_permission.dart';
import 'package:time_spy/core/utils/formatters.dart';
import 'package:time_spy/ui/widgets/activity_section.dart';
import 'package:time_spy/ui/widgets/activity_search_bar.dart';
import 'package:time_spy/ui/widgets/activity_bar.dart';

import '../cubit/activity_cubit.dart';
import '../widgets/usage_permission_dialog.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _dialogShown = false;
  bool _showPermissionButton = false;
  late ActivityCubit _activityCubit;

  int _daysFilter = 7;

  @override
  void initState() {
    super.initState();
    _loadDaysFilter();
    WidgetsBinding.instance.addObserver(this);
    _activityCubit = context.read<ActivityCubit>();
    _activityCubit.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activityCubit.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndRefresh();
    }
  }

  Future<void> _loadDaysFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getInt('days_filter') ?? 7;
    setState(() {
      _daysFilter = savedValue;
    });
  }

  Future<void> _saveDaysFilter(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('days_filter', value);
  }

  Future<void> _checkPermissionAndRefresh() async {
    final granted = await UsagePermission.isUsagePermissionGranted();
    if (granted) {
      _activityCubit.fetchInitialStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.08),
      appBar: const ActivityAppBar(),
      body: BlocBuilder<ActivityCubit, ActivityState>(
        builder: (context, state) {
          if (state is ActivityLoading) {
            return Center(
                child: Lottie.asset(
              'assets/lottie/spy.json',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ));
          }

          if (state is ActivityPermissionRequired) {
            if (!_dialogShown) {
              _dialogShown = true;

              WidgetsBinding.instance.addPostFrameCallback((_) async {
                final result = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const UsagePermissionDialog(),
                );

                if (result == true) {
                  await UsagePermission.openUsageSettings();

                  final granted =
                      await UsagePermission.isUsagePermissionGranted();
                  if (granted) {
                    context.read<ActivityCubit>().fetchInitialStats();
                    setState(() {
                      _showPermissionButton = false;
                    });
                  } else {
                    setState(() {
                      _showPermissionButton = true;
                    });
                  }
                } else {
                  setState(() {
                    _showPermissionButton = true;
                  });
                }
              });
            }
            if (_showPermissionButton) {
              return Center(
                child: ElevatedButton.icon(
                  icon:
                      const Icon(Icons.lock_open_rounded, color: Colors.black),
                  label: const Text(
                    'Grant Usage Permission',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4D9DE0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 6,
                  ),
                  onPressed: () async {
                    await UsagePermission.openUsageSettings();

                    final granted =
                        await UsagePermission.isUsagePermissionGranted();
                    if (granted) {
                      context.read<ActivityCubit>().fetchInitialStats();
                      setState(() {
                        _showPermissionButton = false;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Permission not granted. Please enable it to proceed.',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  },
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          }

          if (state is ActivityLoaded) {
            final now = DateTime.now();
            final activeThreshold = now.subtract(Duration(days: _daysFilter));

            final usageStatsExt = state.apps;

            final visibleApps = _searchQuery.isNotEmpty
                ? usageStatsExt
                    .where((app) => app.appName
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList()
                : usageStatsExt;

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

            return RefreshIndicator(
              backgroundColor: Colors.transparent,
              color: const Color(0xFF4D9DE0),
              onRefresh: () async {
                context.read<ActivityCubit>().init();
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  ActivitySearchBar(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                    onClear: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    query: _searchQuery,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter by last activity (days): $_daysFilter',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Slider(
                          value: _daysFilter.toDouble(),
                          min: 1,
                          max: 14,
                          divisions: 13,
                          label: '$_daysFilter days',
                          activeColor: const Color(0xFF4D9DE0),
                          inactiveColor: Colors.white24,
                          onChanged: (double value) {
                            setState(() {
                              _daysFilter = value.round();
                            });
                            _saveDaysFilter(_daysFilter);
                          },
                        ),
                      ],
                    ),
                  ),
                  if (activeApps.isNotEmpty)
                    ActivitySection(
                      title: 'High Activity',
                      apps: activeApps,
                      isActive: true,
                      formatDuration: formatDuration,
                      formatDateTime: formatDateTime,
                    ),
                  if (inactiveApps.isNotEmpty)
                    ActivitySection(
                      title: 'Low Activity',
                      apps: inactiveApps,
                      isActive: false,
                      formatDuration: formatDuration,
                      formatDateTime: formatDateTime,
                    ),
                ],
              ),
            );
          }

          if (state is ActivityError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
