import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'l10n_extension.dart';

class DateFormatter {
  DateFormatter._();

  static String formatDate(DateTime date, [BuildContext? context]) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    final locale = context != null ? Localizations.localeOf(context).toString() : null;

    if (dateOnly == today) return context?.l10n.todayCapitalized ?? 'Today';
    if (dateOnly == yesterday) return context?.l10n.yesterdayCapitalized ?? 'Yesterday';
    if (now.difference(date).inDays < 7) return DateFormat('EEEE', locale).format(date);
    if (date.year == now.year) return DateFormat('MMM d', locale).format(date);
    return DateFormat('MMM d, y', locale).format(date);
  }

  static String formatFull(DateTime date) {
    return DateFormat('MMMM d, y').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }
}
