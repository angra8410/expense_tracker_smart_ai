import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/recurring_transaction.dart';
import 'budget_notification_service.dart';

class WebStorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw Exception('WebStorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Basic storage methods
  static Future<void> setString(String key, String value) async {
    await _instance.setString(key, value);
  }

  static String? getString(String key) {
    return _instance.getString(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await _instance.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _instance.getBool(key);
  }

  static Future<void> setInt(String key, int value) async {
    await _instance.setInt(key, value);
  }

  static int? getInt(String key) {
    return _instance.getInt(key);
  }

  static Future<void> setDouble(String key, double value) async {
    await _instance.setDouble(key, value);
  }

  static double? getDouble(String key) {
    return _instance.getDouble(key);
  }

  static Future<void> remove(String key) async {
    await _instance.remove(key);
  }

  static Future<void> clear() async {
    await _instance.clear();
  }

  // JSON encoding/decoding helpers
  static String jsonEncode(dynamic object) {
    return json.encode(object);
  }

  static dynamic jsonDecode(String source) {
    return json.decode(source);
  }

  // Generic data methods
  static Future<void> saveData(String key, Map<String, dynamic> data) async {
    await setString(key, jsonEncode(data));
  }

  static Map<String, dynamic>? getData(String key) {
    final jsonString = getString(key);
    if (jsonString != null) {
      try {
        return Map<String, dynamic>.from(jsonDecode(jsonString));
      } catch (e) {
        print('Error parsing JSON for key $key: $e');
        return null;
      }
    }
    return null;
  }

  // List and Map methods for ML service
  static Future<void> saveList(String key, List<Map<String, dynamic>> data) async {
    await setString(key, jsonEncode(data));
  }

  static Future<List<Map<String, dynamic>>> getList(String key) async {
    final jsonString = getString(key);
    if (jsonString != null) {
      try {
        final decoded = jsonDecode(jsonString);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      } catch (e) {
        print('Error parsing list for key $key: $e');
      }
    }
    return [];
  }

  static Future<void> saveMap(String key, Map<String, dynamic> data) async {
    await setString(key, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getMap(String key) async {
    final jsonString = getString(key);
    if (jsonString != null) {
      try {
        final decoded = jsonDecode(jsonString);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (e) {
        print('Error parsing map for key $key: $e');
      }
    }
    return null;
  }

  // Category methods
  static Future<List<Category>> getCategories() async {
    final jsonString = getString('categories');
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((json) => Category.fromJson(json)).toList();
      } catch (e) {
        print('Error loading categories: $e');
        return [];
      }
    }
    return [];
  }

  static Future<void> saveCategories(List<Category> categories) async {
    try {
      final jsonList = categories.map((category) => category.toJson()).toList();
      await setString('categories', jsonEncode(jsonList));
    } catch (e) {
      print('Error saving categories: $e');
      throw Exception('Failed to save categories: $e');
    }
  }

  static Future<void> addCategory(Category category) async {
    try {
      final categories = await getCategories();
      categories.add(category);
      await saveCategories(categories);
    } catch (e) {
      print('Error adding category: $e');
      throw Exception('Failed to add category: $e');
    }
  }

  // Transaction methods
  static Future<List<Transaction>> getTransactions({bool includeTestData = true}) async {
    final jsonString = getString('transactions');
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final allTransactions = jsonList.map((json) => Transaction.fromJson(json)).toList();
        
        if (!includeTestData) {
          // Filter out test transactions (those with IDs starting with 'debug_' or 'test_')
          return allTransactions.where((tx) => 
            !tx.id.startsWith('debug_') && 
            !tx.id.startsWith('test_') &&
            !tx.description.toLowerCase().contains('debug') &&
            !tx.description.toLowerCase().contains('test')
          ).toList();
        }
        
        return allTransactions;
      } catch (e) {
        print('Error loading transactions: $e');
        return [];
      }
    }
    return [];
  }

  static Future<void> saveTransactions(List<Transaction> transactions) async {
    try {
      final jsonList = transactions.map((transaction) => transaction.toJson()).toList();
      await setString('transactions', jsonEncode(jsonList));
      
      // Notify budget service that transactions have changed
      BudgetNotificationService.notifyBudgetUpdate();
      print('💰 Transactions saved and budget listeners notified');
    } catch (e) {
      print('Error saving transactions: $e');
      throw Exception('Failed to save transactions: $e');
    }
  }

  static Future<void> addTransaction(Transaction transaction) async {
    try {
      final transactions = await getTransactions();
      transactions.add(transaction);
      await saveTransactions(transactions); // This will trigger budget notification
    } catch (e) {
      print('Error adding transaction: $e');
      throw Exception('Failed to add transaction: $e');
    }
  }

  static Future<void> addTransactions(List<Transaction> newTransactions) async {
    try {
      final transactions = await getTransactions();
      transactions.addAll(newTransactions);
      await saveTransactions(transactions); // This will trigger budget notification
    } catch (e) {
      print('Error adding transactions: $e');
      throw Exception('Failed to add transactions: $e');
    }
  }

  static Future<void> updateTransaction(Transaction updatedTransaction) async {
    try {
      final transactions = await getTransactions();
      final index = transactions.indexWhere((t) => t.id == updatedTransaction.id);
      if (index != -1) {
        transactions[index] = updatedTransaction;
        await saveTransactions(transactions); // This will trigger budget notification
      }
    } catch (e) {
      print('Error updating transaction: $e');
      throw Exception('Failed to update transaction: $e');
    }
  }

  static Future<void> deleteTransaction(String transactionId) async {
    try {
      final transactions = await getTransactions();
      transactions.removeWhere((t) => t.id == transactionId);
      await saveTransactions(transactions); // This will trigger budget notification
    } catch (e) {
      print('Error deleting transaction: $e');
      throw Exception('Failed to delete transaction: $e');
    }
  }

  // Helper method to notify budget updates (avoiding circular import)
  static void _notifyBudgetUpdate() {
    try {
      // Use dynamic import to avoid circular dependency
      final budgetServiceType = _getBudgetServiceType();
      if (budgetServiceType != null) {
        budgetServiceType.call('notifyBudgetUpdate');
      }
    } catch (e) {
      print('Could not notify budget update: $e');
    }
  }

  static Function? _getBudgetServiceType() {
    try {
      // This is a workaround to avoid circular imports
      // We'll implement this differently
      return null;
    } catch (e) {
      return null;
    }
  }

  // Recurring Transaction methods
  static Future<List<RecurringTransaction>> getRecurringTransactions() async {
    final jsonString = getString('recurring_transactions');
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((json) => RecurringTransaction.fromJson(json)).toList();
      } catch (e) {
        print('Error loading recurring transactions: $e');
        return [];
      }
    }
    return [];
  }

  static Future<void> saveRecurringTransactions(List<RecurringTransaction> recurringTransactions) async {
    try {
      final jsonList = recurringTransactions.map((rt) => rt.toJson()).toList();
      await setString('recurring_transactions', jsonEncode(jsonList));
    } catch (e) {
      print('Error saving recurring transactions: $e');
      throw Exception('Failed to save recurring transactions: $e');
    }
  }

  static Future<void> addRecurringTransaction(RecurringTransaction recurringTransaction) async {
    try {
      final recurringTransactions = await getRecurringTransactions();
      recurringTransactions.add(recurringTransaction);
      await saveRecurringTransactions(recurringTransactions);
    } catch (e) {
      print('Error adding recurring transaction: $e');
      throw Exception('Failed to add recurring transaction: $e');
    }
  }

  static Future<void> updateRecurringTransaction(RecurringTransaction updatedRecurringTransaction) async {
    try {
      final recurringTransactions = await getRecurringTransactions();
      final index = recurringTransactions.indexWhere((rt) => rt.id == updatedRecurringTransaction.id);
      if (index != -1) {
        recurringTransactions[index] = updatedRecurringTransaction;
        await saveRecurringTransactions(recurringTransactions);
      } else {
        throw Exception('Recurring transaction not found');
      }
    } catch (e) {
      print('Error updating recurring transaction: $e');
      throw Exception('Failed to update recurring transaction: $e');
    }
  }

  static Future<void> deleteRecurringTransaction(String recurringTransactionId) async {
    try {
      final recurringTransactions = await getRecurringTransactions();
      recurringTransactions.removeWhere((rt) => rt.id == recurringTransactionId);
      await saveRecurringTransactions(recurringTransactions);
    } catch (e) {
      print('Error deleting recurring transaction: $e');
      throw Exception('Failed to delete recurring transaction: $e');
    }
  }

  // Backup and restore methods
  static Future<Map<String, dynamic>> exportAllData() async {
    try {
      final transactions = await getTransactions();
      final categories = await getCategories();
      final recurringTransactions = await getRecurringTransactions();

      return {
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'recurring_transactions': recurringTransactions.map((rt) => rt.toJson()).toList(),
        'export_date': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
    } catch (e) {
      print('Error exporting data: $e');
      throw Exception('Failed to export data: $e');
    }
  }

  static Future<void> importAllData(Map<String, dynamic> data) async {
    try {
      // Import transactions
      if (data['transactions'] != null) {
        final List<dynamic> transactionsList = data['transactions'];
        final transactions = transactionsList.map((json) => Transaction.fromJson(json)).toList();
        await saveTransactions(transactions);
      }

      // Import categories
      if (data['categories'] != null) {
        final List<dynamic> categoriesList = data['categories'];
        final categories = categoriesList.map((json) => Category.fromJson(json)).toList();
        await saveCategories(categories);
      }

      // Import recurring transactions
      if (data['recurring_transactions'] != null) {
        final List<dynamic> recurringTransactionsList = data['recurring_transactions'];
        final recurringTransactions = recurringTransactionsList.map((json) => RecurringTransaction.fromJson(json)).toList();
        await saveRecurringTransactions(recurringTransactions);
      }
    } catch (e) {
      print('Error importing data: $e');
      throw Exception('Failed to import data: $e');
    }
  }

  // Utility methods
  static Future<void> clearAllData() async {
    try {
      await remove('transactions');
      await remove('categories');
      await remove('recurring_transactions');
      // Clear any other app-specific data
      await remove('user_preferences');
      await remove('ml_data');
      await remove('analytics_data');
    } catch (e) {
      print('Error clearing all data: $e');
      throw Exception('Failed to clear all data: $e');
    }
  }

  static Future<bool> hasData() async {
    try {
      final transactions = await getTransactions();
      final categories = await getCategories();
      return transactions.isNotEmpty || categories.isNotEmpty;
    } catch (e) {
      print('Error checking for data: $e');
      return false;
    }
  }

  // Get category by ID
  static Future<Category?> getCategoryById(String categoryId) async {
    try {
      final categories = await getCategories();
      return categories.firstWhere(
        (category) => category.id == categoryId,
        orElse: () => throw StateError('Category not found'),
      );
    } catch (e) {
      print('Error getting category by ID: $e');
      return null;
    }
  }

  // Get transaction by ID
  static Future<Transaction?> getTransactionById(String transactionId) async {
    try {
      final transactions = await getTransactions();
      return transactions.firstWhere(
        (transaction) => transaction.id == transactionId,
        orElse: () => throw StateError('Transaction not found'),
      );
    } catch (e) {
      print('Error getting transaction by ID: $e');
      return null;
    }
  }

  // Add missing recurring transaction methods
  static Future<List<RecurringTransaction>> getActiveRecurringTransactions() async {
    try {
      final allRecurring = await getRecurringTransactions();
      return allRecurring.where((rt) => rt.isActive).toList();
    } catch (e) {
      print('Error getting active recurring transactions: $e');
      return [];
    }
  }

  static Future<RecurringTransaction?> getRecurringTransactionById(String recurringTransactionId) async {
    try {
      final recurringTransactions = await getRecurringTransactions();
      return recurringTransactions.firstWhere(
        (rt) => rt.id == recurringTransactionId,
        orElse: () => throw StateError('Recurring transaction not found'),
      );
    } catch (e) {
      print('Error getting recurring transaction by ID: $e');
      return null;
    }
  }
}