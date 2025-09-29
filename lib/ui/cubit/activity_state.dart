part of 'activity_cubit.dart';

@immutable
abstract class ActivityState {}

class ActivityInitial extends ActivityState {}

class ActivityLoading extends ActivityState {}

class ActivityLoaded extends ActivityState {
  final List<AppInfoExt> apps;

  ActivityLoaded({required this.apps});
}

class ActivityPermissionRequired extends ActivityState {}

class ActivityError extends ActivityState {
  final String message;

  ActivityError(this.message);
}
