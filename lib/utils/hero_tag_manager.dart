/// Utility class to manage unique hero tags and prevent conflicts
class HeroTagManager {
  static int _counter = 0;
  static final Map<String, String> _tagCache = {};

  /// Generates a unique hero tag for the given context
  static String generateUniqueTag(String context) {
    final tag = '${context}_${_counter++}_${DateTime.now().millisecondsSinceEpoch}';
    _tagCache[context] = tag;
    return tag;
  }

  /// Gets a cached tag for the context or generates a new one
  static String getOrCreateTag(String context) {
    return _tagCache[context] ?? generateUniqueTag(context);
  }

  /// Clears all cached tags (useful for testing)
  static void clearCache() {
    _tagCache.clear();
    _counter = 0;
  }

  /// Common hero tags for different UI elements
  static class CommonTags {
    static const String addTransactionFab = 'add_transaction_fab';
    static const String editTransactionFab = 'edit_transaction_fab';
    static const String importFab = 'import_fab';
    static const String exportFab = 'export_fab';
    static const String settingsFab = 'settings_fab';
  }
}