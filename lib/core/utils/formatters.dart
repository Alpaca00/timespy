String formatDateTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} '
      '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}';
}

String formatDuration(Duration duration) {
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
