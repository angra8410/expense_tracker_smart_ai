import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class OptimizedWebStorageService {
  static SharedPreferences? _prefs;
  static const String _transactionsKey = 'transactions_list';
  
  // In-memory cache
  static List<Transaction>? _transactionCache;
  static bool _cacheLoaded = false;
  
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadTransactionsToCache();
  }
  
  /// Load transactions into memory cache once
  static Future<void> _loadTransactionsToCache() async {
    if (_cacheLoaded) return;
    
    try {
      final transactionsJson = _prefs?.getString(_transactionsKey);
      if (transactionsJson != null) {
        final List<dynamic> transactionsList = json.decode(transactionsJson);
        _transactionCache = transactionsList
            .map((json) => Transaction.fromJson(json))
            .toList();
      } else {
        _transactionCache = [];
      }
      _cacheLoaded = true;
    } catch (e) {
      print('Error loading transactions to cache: $e');
      _transactionCache = [];
      _cacheLoaded = true;
    }
  }
  
  /// Get transactions from cache (much faster)
  static Future<List<Transaction>> getTransactionsFast() async {
    await _loadTransactionsToCache();
    return List<Transaction>.from(_transactionCache ?? []);
  }
  
  /// Add single transaction with optimized caching
  static Future<void> addTransactionFast(Transaction transaction) async {
    await _loadTransactionsToCache();
    
    // Add to cache immediately
    _transactionCache!.add(transaction);
    
    // Save to persistent storage asynchronously
    _saveTransactionsAsync();
  }
  
  /// Async save to avoid blocking UI
  static void _saveTransactionsAsync() {
    Future.microtask(() async {
      try {
        final transactionsJson = json.encode(
          _transactionCache!.map((t) => t.toJson()).toList()
        );
        await _prefs?.setString(_transactionsKey, transactionsJson);
      } catch (e) {
        print('Error saving transactions: $e');
      }
    });
  }
  
  /// Force cache refresh
  static void refreshCache() {
    _cacheLoaded = false;
    _transactionCache = null;
  }
}