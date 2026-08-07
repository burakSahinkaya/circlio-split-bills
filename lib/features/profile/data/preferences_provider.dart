import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for SharedPreferences instance. Must be overridden in main() or properly initialized.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class UserPreferences {
  final String currency;
  final bool notificationsEnabled;
  final ThemeMode themeMode;
  final String? languageCode;

  const UserPreferences({
    this.currency = 'AUD',
    this.notificationsEnabled = true,
    this.themeMode = ThemeMode.dark,
    this.languageCode,
  });

  UserPreferences copyWith({
    String? currency,
    bool? notificationsEnabled,
    ThemeMode? themeMode,
    String? languageCode,
  }) {
    return UserPreferences(
      currency: currency ?? this.currency,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

class PreferencesNotifier extends Notifier<UserPreferences> {
  late SharedPreferences _prefs;

  @override
  UserPreferences build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    
    final currency = _prefs.getString('currency') ?? 'AUD';
    final notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? true;
    
    final themeModeString = _prefs.getString('themeMode');
    ThemeMode themeMode = ThemeMode.dark; // Default
    if (themeModeString == 'light') themeMode = ThemeMode.light;
    if (themeModeString == 'system') themeMode = ThemeMode.system;

    final languageCode = _prefs.getString('languageCode');

    return UserPreferences(
      currency: currency,
      notificationsEnabled: notificationsEnabled,
      themeMode: themeMode,
      languageCode: languageCode,
    );
  }

  Future<void> updateCurrency(String newCurrency) async {
    await _prefs.setString('currency', newCurrency);
    state = state.copyWith(currency: newCurrency);
  }

  Future<void> toggleNotifications(bool enabled) async {
    await _prefs.setBool('notificationsEnabled', enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }

  Future<void> updateThemeMode(ThemeMode newMode) async {
    String modeString = 'dark';
    if (newMode == ThemeMode.light) modeString = 'light';
    if (newMode == ThemeMode.system) modeString = 'system';
    
    await _prefs.setString('themeMode', modeString);
    state = state.copyWith(themeMode: newMode);
  }

  Future<void> updateLanguage(String? languageCode) async {
    if (languageCode == null) {
      await _prefs.remove('languageCode');
    } else {
      await _prefs.setString('languageCode', languageCode);
    }
    // We recreate UserPreferences passing null to retain current values except languageCode,
    // wait, copyWith needs to be able to set a variable to null explicitly.
    // Instead of dealing with copyWith null issues, we'll just reconstruct the state completely or modify copyWith.
    // Better way:
    state = UserPreferences(
      currency: state.currency,
      notificationsEnabled: state.notificationsEnabled,
      themeMode: state.themeMode,
      languageCode: languageCode,
    );
  }
}

final preferencesProvider = NotifierProvider<PreferencesNotifier, UserPreferences>(() {
  return PreferencesNotifier();
});
