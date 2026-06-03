import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Keys ──────────────────────────────────────────────────────────────────────
const _kThemeKey = 'skinova_theme_mode';
const _kLocaleKey = 'skinova_locale';

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Holds the active ThemeMode and Locale, persists them via SharedPreferences,
/// and notifies listeners so the root MaterialApp rebuilds instantly.
class AppSettingsNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  bool get isArabic => _locale.languageCode == 'ar';

  // ── Load persisted prefs on startup ───────────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final themeStr = prefs.getString(_kThemeKey) ?? 'system';
    _themeMode = _modeFromString(themeStr);

    final localeStr = prefs.getString(_kLocaleKey) ?? 'en';
    _locale = Locale(localeStr);

    notifyListeners();
  }

  // ── Setters ───────────────────────────────────────────────────────────────
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, _modeToString(mode));
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static ThemeMode _modeFromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _modeToString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}

// ── InheritedNotifier scope ───────────────────────────────────────────────────

/// Exposes [AppSettingsNotifier] to the entire widget tree.
/// Any widget that calls [AppSettings.of] will rebuild automatically
/// when the notifier fires.
class AppSettings extends InheritedNotifier<AppSettingsNotifier> {
  const AppSettings({
    super.key,
    required super.notifier,
    required super.child,
  });

  /// Returns the notifier. Calling this creates a rebuild dependency.
  static AppSettingsNotifier of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSettings>();
    assert(scope != null,
        'No AppSettings found in context. Wrap your app with AppSettings(...).');
    return scope!.notifier!;
  }

  /// Returns the notifier without creating a rebuild dependency.
  static AppSettingsNotifier read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppSettings>();
    assert(scope != null,
        'No AppSettings found in context. Wrap your app with AppSettings(...).');
    return scope!.notifier!;
  }
}
