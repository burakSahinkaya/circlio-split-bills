class AppConstants {
  AppConstants._();

  static const String appName = 'SplitCircle';
  static const String defaultCurrency = 'AUD';
  static const String currencySymbol = '\$';

  // Group types
  static const Map<String, String> groupTypeEmojis = {
    'trip': '🧳',
    'house': '🏠',
    'couple': '💑',
    'friends': '👥',
    'family': '👨‍👩‍👧‍👦',
    'work': '💼',
    'other': '📌',
  };

  static const Map<String, String> groupTypeLabels = {
    'trip': 'Trip',
    'house': 'House',
    'couple': 'Couple',
    'friends': 'Friends',
    'family': 'Family',
    'work': 'Work',
    'other': 'Other',
  };
}
