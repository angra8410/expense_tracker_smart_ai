import '../models/transaction.dart';
import '../services/web_storage_service.dart';

class SearchService {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 20;

  /// Performs intelligent search across transactions
  static List<Transaction> searchTransactions(
    List<Transaction> transactions,
    String query, {
    bool fuzzySearch = true,
    double threshold = 0.6,
  }) {
    if (query.isEmpty) return transactions;

    final lowerQuery = query.toLowerCase();
    final queryWords = lowerQuery.split(' ').where((w) => w.isNotEmpty).toList();

    return transactions.where((transaction) {
      // Exact matches get highest priority
      if (_exactMatch(transaction, lowerQuery)) return true;

      // Fuzzy matching for partial matches
      if (fuzzySearch) {
        final score = _calculateRelevanceScore(transaction, queryWords);
        return score >= threshold;
      }

      return false;
    }).toList();
  }

  /// Calculates relevance score for fuzzy matching
  static double _calculateRelevanceScore(Transaction transaction, List<String> queryWords) {
    double score = 0.0;
    final description = transaction.description.toLowerCase();
    final category = transaction.categoryId.toLowerCase();
    final amount = transaction.amount.toString();

    for (final word in queryWords) {
      // Description matches (highest weight)
      if (description.contains(word)) {
        score += 0.4;
        if (description.startsWith(word)) score += 0.2; // Bonus for prefix match
      }

      // Category matches (medium weight)
      if (category.contains(word)) {
        score += 0.3;
        if (category == word) score += 0.2; // Bonus for exact category match
      }

      // Amount matches (lower weight)
      if (amount.contains(word)) {
        score += 0.1;
      }

      // Date matches (if query contains date-like patterns)
      if (_isDateQuery(word) && _matchesDate(transaction.date, word)) {
        score += 0.2;
      }
    }

    return score / queryWords.length; // Normalize by number of query words
  }

  /// Checks for exact matches
  static bool _exactMatch(Transaction transaction, String query) {
    final description = transaction.description.toLowerCase();
    final category = transaction.categoryId.toLowerCase();
    final amount = transaction.amount.toString();

    return description == query ||
           category == query ||
           amount == query ||
           description.contains(query) ||
           category.contains(query);
  }

  /// Checks if a word looks like a date query
  static bool _isDateQuery(String word) {
    // Check for patterns like: 2024, jan, january, 01, etc.
    final datePatterns = [
      RegExp(r'^\d{4}$'), // Year
      RegExp(r'^\d{1,2}$'), // Month/day
      RegExp(r'^(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)'),
      RegExp(r'^\d{1,2}[-/]\d{1,2}'), // MM/DD or MM-DD
    ];

    return datePatterns.any((pattern) => pattern.hasMatch(word));
  }

  /// Checks if transaction date matches date query
  static bool _matchesDate(DateTime date, String query) {
    final dateStr = date.toString().toLowerCase();
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    // Month names
    const monthNames = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    const monthAbbr = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
    ];

    return dateStr.contains(query) ||
           year == query ||
           month == query ||
           day == query ||
           monthNames[date.month - 1].startsWith(query) ||
           monthAbbr[date.month - 1] == query;
  }

  /// Generates search suggestions based on transaction data
  static List<String> generateSearchSuggestions(
    List<Transaction> transactions,
    String currentQuery,
  ) {
    final suggestions = <String>{};
    final lowerQuery = currentQuery.toLowerCase();

    // Add category suggestions
    for (final transaction in transactions) {
      final category = transaction.categoryId;
      if (category.toLowerCase().contains(lowerQuery)) {
        suggestions.add(category);
      }
    }

    // Add description word suggestions
    for (final transaction in transactions) {
      final words = transaction.description.split(' ');
      for (final word in words) {
        if (word.length > 2 && word.toLowerCase().contains(lowerQuery)) {
          suggestions.add(word);
        }
      }
    }

    // Add amount range suggestions
    if (lowerQuery.isEmpty || RegExp(r'^\d').hasMatch(lowerQuery)) {
      final amounts = transactions.map((t) => t.amount).toSet().toList()..sort();
      final roundedAmounts = amounts.map((a) => (a / 10).round() * 10).toSet();
      
      for (final amount in roundedAmounts.take(5)) {
        if (amount.toString().startsWith(lowerQuery)) {
          suggestions.add('\$${amount.toStringAsFixed(0)}');
        }
      }
    }

    // Add date suggestions
    if (lowerQuery.isEmpty || _isDateQuery(lowerQuery)) {
      final years = transactions.map((t) => t.date.year).toSet().toList()..sort();
      for (final year in years.take(3)) {
        if (year.toString().contains(lowerQuery)) {
          suggestions.add(year.toString());
        }
      }

      const months = ['January', 'February', 'March', 'April', 'May', 'June',
                     'July', 'August', 'September', 'October', 'November', 'December'];
      for (final month in months) {
        if (month.toLowerCase().contains(lowerQuery)) {
          suggestions.add(month);
        }
      }
    }

    return suggestions.take(8).toList();
  }

  /// Saves search query to history
  static Future<void> saveSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final history = await getSearchHistory();
      history.remove(query); // Remove if already exists
      history.insert(0, query); // Add to beginning

      // Keep only the most recent items
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      await WebStorageService.setItem(_searchHistoryKey, history);
    } catch (e) {
      print('Error saving search query: $e');
    }
  }

  /// Gets search history
  static Future<List<String>> getSearchHistory() async {
    try {
      final data = await WebStorageService.getItem(_searchHistoryKey);
      if (data is List) {
        return data.cast<String>();
      }
    } catch (e) {
      print('Error getting search history: $e');
    }
    return [];
  }

  /// Clears search history
  static Future<void> clearSearchHistory() async {
    try {
      await WebStorageService.remove(_searchHistoryKey);
    } catch (e) {
      print('Error clearing search history: $e');
    }
  }

  /// Analyzes search patterns and provides insights
  static Map<String, dynamic> analyzeSearchPatterns(List<String> searchHistory) {
    final patterns = <String, int>{};
    final categories = <String, int>{};
    final amounts = <String, int>{};

    for (final query in searchHistory) {
      final lowerQuery = query.toLowerCase();
      
      // Count search patterns
      if (lowerQuery.contains('\$')) {
        amounts[query] = (amounts[query] ?? 0) + 1;
      } else if (_isDateQuery(lowerQuery)) {
        patterns['date_searches'] = (patterns['date_searches'] ?? 0) + 1;
      } else {
        categories[query] = (categories[query] ?? 0) + 1;
      }
    }

    return {
      'total_searches': searchHistory.length,
      'most_searched_categories': categories.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      'most_searched_amounts': amounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      'search_patterns': patterns,
    };
  }

  /// Provides smart search suggestions based on context
  static List<String> getSmartSuggestions(
    List<Transaction> transactions,
    DateTime? selectedDate,
    String? selectedCategory,
  ) {
    final suggestions = <String>[];

    // Recent categories
    final recentCategories = transactions
        .where((t) => DateTime.now().difference(t.date).inDays <= 30)
        .map((t) => t.categoryId)
        .toSet()
        .take(5);
    suggestions.addAll(recentCategories);

    // Common amounts
    final commonAmounts = <double, int>{};
    for (final transaction in transactions) {
      final roundedAmount = (transaction.amount / 5).round() * 5;
      commonAmounts[roundedAmount] = (commonAmounts[roundedAmount] ?? 0) + 1;
    }
    
    final topAmounts = commonAmounts.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in topAmounts.take(3)) {
      suggestions.add('\$${entry.key.toStringAsFixed(0)}');
    }

    // Date-based suggestions
    if (selectedDate != null) {
      suggestions.add('This month');
      suggestions.add('Last month');
      suggestions.add('This year');
    }

    // Category-based suggestions
    if (selectedCategory != null) {
      final categoryTransactions = transactions
          .where((t) => t.categoryId == selectedCategory)
          .toList();
      
      final avgAmount = categoryTransactions.isNotEmpty
          ? categoryTransactions.map((t) => t.amount).reduce((a, b) => a + b) / categoryTransactions.length
          : 0.0;
      
      if (avgAmount > 0) {
        suggestions.add('Above \$${avgAmount.toStringAsFixed(0)}');
        suggestions.add('Below \$${avgAmount.toStringAsFixed(0)}');
      }
    }

    return suggestions.take(8).toList();
  }

  /// Exports search results to various formats
  static String exportSearchResults(
    List<Transaction> transactions,
    String format, {
    String? searchQuery,
  }) {
    switch (format.toLowerCase()) {
      case 'csv':
        return _exportToCsv(transactions, searchQuery);
      case 'json':
        return _exportToJson(transactions, searchQuery);
      case 'text':
        return _exportToText(transactions, searchQuery);
      default:
        throw ArgumentError('Unsupported export format: $format');
    }
  }

  static String _exportToCsv(List<Transaction> transactions, String? searchQuery) {
    final buffer = StringBuffer();
    
    // Header
    if (searchQuery != null) {
      buffer.writeln('# Search Results for: "$searchQuery"');
      buffer.writeln('# Generated on: ${DateTime.now()}');
      buffer.writeln('#');
    }
    
    buffer.writeln('Date,Description,Category,Type,Amount');
    
    // Data
    for (final transaction in transactions) {
      buffer.writeln(
        '${transaction.date.toString().split(' ')[0]},'
        '"${transaction.description}",'
        '${transaction.categoryId},'
        '${transaction.type == TransactionType.income ? 'Income' : 'Expense'},'
        '${transaction.amount}'
      );
    }
    
    return buffer.toString();
  }

  static String _exportToJson(List<Transaction> transactions, String? searchQuery) {
    final data = {
      'search_query': searchQuery,
      'generated_at': DateTime.now().toIso8601String(),
      'total_results': transactions.length,
      'transactions': transactions.map((t) => {
        'id': t.id,
        'date': t.date.toIso8601String(),
        'description': t.description,
        'category': t.categoryId,
        'type': t.type == TransactionType.income ? 'income' : 'expense',
        'amount': t.amount,
      }).toList(),
    };
    
    return data.toString(); // In a real app, use json.encode()
  }

  static String _exportToText(List<Transaction> transactions, String? searchQuery) {
    final buffer = StringBuffer();
    
    if (searchQuery != null) {
      buffer.writeln('Search Results for: "$searchQuery"');
      buffer.writeln('Generated on: ${DateTime.now()}');
      buffer.writeln('Total results: ${transactions.length}');
      buffer.writeln('${'=' * 50}');
      buffer.writeln();
    }
    
    for (final transaction in transactions) {
      buffer.writeln('Date: ${transaction.date.toString().split(' ')[0]}');
      buffer.writeln('Description: ${transaction.description}');
      buffer.writeln('Category: ${transaction.categoryId}');
      buffer.writeln('Type: ${transaction.type == TransactionType.income ? 'Income' : 'Expense'}');
      buffer.writeln('Amount: \$${transaction.amount.toStringAsFixed(2)}');
      buffer.writeln('-' * 30);
    }
    
    return buffer.toString();
  }
}