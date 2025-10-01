import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:time_spy/core/shared/presentation/widgets/shared_app_bar.dart';
import 'package:time_spy/core/shared/presentation/widgets/usage_permission_dialog.dart';
import 'package:time_spy/core/utils/formatters.dart';
import 'package:time_spy/features/activity/presentation/widgets/activity_section.dart';

import '../cubit/activity_cubit.dart';
import '../widgets/activity_search_bar.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage>
    with WidgetsBindingObserver {
  late final ActivityCubit cubit;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cubit = context.read<ActivityCubit>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      cubit.requestPermissionFlow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.08),
      appBar: const SharedAppBar(),
      body: BlocConsumer<ActivityCubit, ActivityState>(
        listener: (context, state) async {
          if (state.permissionRequired && !state.dialogShown) {
            cubit.markDialogAsShown();
            final result = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (_) => const UsagePermissionDialog(),
            );
            if (result == true) {
              await cubit.openUsageSettings();
              await cubit.requestPermissionFlow();
            } else {
              cubit.onPermissionDialogCancelled();
            }
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return Center(
              child: Lottie.asset(
                'assets/lottie/spy.json',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
            );
          }

          if (state.showPermissionButton && !state.dialogShown) {
            return Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.lock_open_rounded, color: Colors.black),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                ),
                onPressed: () async {
                  await cubit.openUsageSettings();
                  await cubit.requestPermissionFlow();
                },
              ),
            );
          }

          if (state.error != null) {
            return Center(
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final now = DateTime.now();
          final activeThreshold =
              now.subtract(Duration(days: state.daysFilter));

          final visibleApps = cubit.filteredApps;

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
              await cubit.refresh();
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                ActivitySearchBar(
                  controller: searchController,
                  onChanged: (value) {
                    cubit.updateSearch(value);
                  },
                  onClear: () {
                    searchController.clear();
                    cubit.updateSearch('');
                  },
                  query: state.searchQuery,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter by last activity (days): ${state.daysFilter}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Slider(
                        value: state.daysFilter.toDouble(),
                        min: 1,
                        max: 14,
                        divisions: 13,
                        label: '${state.daysFilter} days',
                        activeColor: const Color(0xFF4D9DE0),
                        inactiveColor: Colors.white24,
                        onChanged: (double value) {
                          cubit.updateFilter(value.round()).then((_) {
                            cubit.refresh();
                          });
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
        },
      ),
    );
  }
}
