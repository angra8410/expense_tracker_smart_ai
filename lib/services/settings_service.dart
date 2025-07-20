import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _languageKey = 'app_language';
  static const String _currencyKey = 'app_currency';
  static const String _themeKey = 'app_theme';

  // Language settings
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'es'; // Default to Spanish for Colombia
  }

  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    print('💬 Language set to: $languageCode');
  }

  // Currency settings
  static Future<String> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? 'COP'; // Default to Colombian Peso
  }

  static Future<void> setCurrency(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currencyCode);
    print('💰 Currency set to: $currencyCode');
  }

  // Theme settings
  static Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'light';
  }

  static Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
    print('🌙 Theme set to: $theme');
  }

  // Currency formatting
  static String formatCurrency(double amount, String currencyCode) {
    switch (currencyCode) {
      case 'COP':
        return '\$${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )} COP';
      case 'USD':
        return '\$${amount.toStringAsFixed(2)} USD';
      default:
        return '\$${amount.toStringAsFixed(2)}';
    }
  }

  // Currency symbols
  static String getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'COP':
        return '\$ COP';
      case 'USD':
        return '\$ USD';
      default:
        return '\$';
    }
  }

  // Currency names
  static String getCurrencyName(String currencyCode) {
    switch (currencyCode) {
      case 'COP':
        return 'Peso Colombiano';
      case 'USD':
        return 'US Dollar';
      default:
        return currencyCode;
    }
  }
}