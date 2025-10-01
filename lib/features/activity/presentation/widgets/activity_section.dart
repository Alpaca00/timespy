import 'package:flutter/material.dart';
import 'package:time_spy/core/shared/data/models/app_info_ext.dart';
import 'package:time_spy/features/activity/presentation/widgets/activity_list_tile.dart';

class ActivitySection extends StatelessWidget {
  final String title;
  final List<AppInfoExt> apps;
  final bool isActive;
  final String Function(Duration) formatDuration;
  final String Function(DateTime) formatDateTime;

  const ActivitySection({
    super.key,
    required this.title,
    required this.apps,
    required this.isActive,
    required this.formatDuration,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.white70,
              fontFamily: 'Saira',
              letterSpacing: 1.1,
            ),
          ),
        ),
        ...apps.map((app) => ActivityTile(
              app: app,
              isActive: isActive,
              formatDuration: formatDuration,
              formatDateTime: formatDateTime,
            )),
      ],
    );
  }
}
