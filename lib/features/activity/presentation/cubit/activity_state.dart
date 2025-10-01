part of 'activity_cubit.dart';

class ActivityState {
  final List<AppInfoExt> apps;
  final bool isLoading;
  final bool permissionRequired;
  final bool showPermissionButton;
  final String searchQuery;
  final int daysFilter;
  final bool dialogShown;
  final String? error;

  ActivityState({
    required this.apps,
    this.isLoading = false,
    this.permissionRequired = false,
    this.showPermissionButton = false,
    this.searchQuery = '',
    this.daysFilter = 14,
    this.dialogShown = false,
    this.error,
  });

  ActivityState copyWith({
    List<AppInfoExt>? apps,
    bool? isLoading,
    bool? permissionRequired,
    bool? showPermissionButton,
    String? searchQuery,
    int? daysFilter,
    bool? dialogShown,
    String? error,
  }) {
    return ActivityState(
      apps: apps ?? this.apps,
      isLoading: isLoading ?? this.isLoading,
      permissionRequired: permissionRequired ?? this.permissionRequired,
      showPermissionButton: showPermissionButton ?? this.showPermissionButton,
      searchQuery: searchQuery ?? this.searchQuery,
      daysFilter: daysFilter ?? this.daysFilter,
      dialogShown: dialogShown ?? this.dialogShown,
      error: error,
    );
  }

  factory ActivityState.initial() => ActivityState(
        apps: [],
        dialogShown: false,
      );
}
