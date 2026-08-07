import 'package:flutter/material.dart';

class CurrencyUtils {
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'CHF': 'CHF',
    'CNY': '¥',
    'INR': '₹',
    'TRY': '₺',
  };

  static const Map<String, String> currencyNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'AUD': 'Australian Dollar',
    'CAD': 'Canadian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Chinese Yuan',
    'INR': 'Indian Rupee',
    'TRY': 'Turkish Lira',
  };

  static String getSymbol(String currencyCode) {
    return currencySymbols[currencyCode] ?? '\$';
  }

  static String getName(String currencyCode) {
    return currencyNames[currencyCode] ?? 'US Dollar';
  }

  static String formatAmount(double amount, String currencyCode) {
    final symbol = getSymbol(currencyCode);
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  static String formatAmountWithCurrency(double amount, String currencyCode) {
    final symbol = getSymbol(currencyCode);
    return '$symbol${amount.toStringAsFixed(2)} ${currencyCode.toUpperCase()}';
  }

  static List<String> getAvailableCurrencies() {
    return currencySymbols.keys.toList()..sort();
  }
}
