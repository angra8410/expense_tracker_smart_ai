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
  static const CommonTags = _CommonTags();

  /// Validates that a hero tag is unique within the current widget tree
  static bool isTagUnique(String tag) {
    return !_tagCache.containsValue(tag);
  }

  /// Registers a hero tag to prevent conflicts
  static void registerTag(String context, String tag) {
    _tagCache[context] = tag;
  }
}

/// Common hero tags for different UI elements
class _CommonTags {
  const _CommonTags();
  
  // FloatingActionButton tags
  String get addTransactionFab => 'add_transaction_fab';
  String get editTransactionFab => 'edit_transaction_fab';
  String get budgetFab => 'budget_fab';
  String get recurringFab => 'recurring_fab';
  String get homeSearchFab => 'home_search_fab';
  String get importFab => 'import_fab';
  String get exportFab => 'export_fab';
  String get settingsFab => 'settings_fab';
  
  // Dialog and modal tags
  String get addTransactionDialog => 'add_transaction_dialog';
  String get editTransactionDialog => 'edit_transaction_dialog';
  String get budgetDialog => 'budget_dialog';
  String get categoryDialog => 'category_dialog';
  
  // Navigation and transition tags
  String get homeToAnalytics => 'home_to_analytics';
  String get homeToSettings => 'home_to_settings';
  String get homeToImport => 'home_to_import';
}