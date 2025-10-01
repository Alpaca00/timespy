import 'package:flutter/material.dart';
import 'package:time_spy/core/shared/data/models/app_info_ext.dart';
import 'package:time_spy/core/shared/presentation/widgets/glass_card_widget.dart';
import 'package:time_spy/core/shared/presentation/widgets/info_row_widget.dart';

class ActivityTile extends StatelessWidget {
  final AppInfoExt app;
  final bool isActive;
  final String Function(Duration) formatDuration;
  final String Function(DateTime) formatDateTime;

  const ActivityTile({
    super.key,
    required this.app,
    required this.isActive,
    required this.formatDuration,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      isActive: isActive,
      child: ListTile(
        leading: app.icon != null
            ? Image.memory(app.icon!, width: 40, height: 40)
            : Icon(Icons.phone_android,
                color: isActive ? Colors.white : Colors.grey),
        title: Text(
          app.appName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.white70,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoRowWidget(label: 'Usage', value: formatDuration(app.usage)),
            InfoRowWidget(
              label: 'Last used',
              value: app.lastForeground != null
                  ? formatDateTime(app.lastForeground!)
                  : '—',
            ),
            InfoRowWidget(label: 'Category', value: app.category),
            InfoRowWidget(label: 'Launches', value: app.launchCount.toString()),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
