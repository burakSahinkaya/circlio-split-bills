import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_AU',
    symbol: '\$',
    decimalDigits: 2,
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }

  static String formatCompact(double amount) {
    if (amount.abs() >= 1000) {
      return NumberFormat.compactCurrency(
        locale: 'en_AU',
        symbol: '\$',
      ).format(amount);
    }
    return format(amount);
  }

  static String formatSigned(double amount) {
    final formatted = format(amount.abs());
    if (amount > 0) return '+$formatted';
    if (amount < 0) return '-$formatted';
    return formatted;
  }
}
