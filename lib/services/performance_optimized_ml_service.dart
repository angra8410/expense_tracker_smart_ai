import 'dart:async';
import '../models/transaction.dart';
import '../services/web_storage_service.dart';
import '../services/enhanced_ml_service.dart';

class PerformanceOptimizedMLService {
  // Batch processing queue
  static final List<Transaction> _pendingTransactions = [];
  static Timer? _batchTimer;
  static bool _isProcessing = false;
  
  // Cache for frequently accessed data
  static List<Transaction>? _cachedTransactions;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  
  /// Optimized transaction learning with batching
  static Future<void> learnFromTransactionOptimized(Transaction transaction) async {
    // Add to batch queue instead of processing immediately
    _pendingTransactions.add(transaction);
    
    // Start or reset batch timer
    _batchTimer?.cancel();
    _batchTimer = Timer(const Duration(seconds: 2), () {
      _processBatchedTransactions();
    });
  }
  
  /// Process multiple transactions in batch to reduce overhead
  static Future<void> _processBatchedTransactions() async {
    if (_isProcessing || _pendingTransactions.isEmpty) return;
    
    _isProcessing = true;
    try {
      final transactionsToProcess = List<Transaction>.from(_pendingTransactions);
      _pendingTransactions.clear();
      
      // Process all transactions in one go
      for (final transaction in transactionsToProcess) {
        await EnhancedMLService.learnFromUserTransaction(transaction);
      }
    } finally {
      _isProcessing = false;
    }
  }
  
  /// Cached transaction loading to reduce storage calls
  static Future<List<Transaction>> getCachedTransactions() async {
    final now = DateTime.now();
    
    // Return cached data if still valid
    if (_cachedTransactions != null && 
        _cacheTimestamp != null && 
        now.difference(_cacheTimestamp!).compareTo(_cacheValidDuration) < 0) {
      return _cachedTransactions!;
    }
    
    // Load fresh data and cache it
    _cachedTransactions = await WebStorageService.getTransactions();
    _cacheTimestamp = now;
    
    return _cachedTransactions!;
  }
  
  /// Invalidate cache when transactions are modified
  static void invalidateCache() {
    _cachedTransactions = null;
    _cacheTimestamp = null;
  }
  
  /// Lightweight transaction addition without heavy ML processing
  static Future<void> addTransactionFast(Transaction transaction) async {
    try {
      // Add transaction to storage immediately
      await WebStorageService.addTransaction(transaction);
      
      // Invalidate cache
      invalidateCache();
      
      // Queue ML processing for later (non-blocking)
      learnFromTransactionOptimized(transaction);
      
    } catch (e) {
      print('Error in fast transaction addition: $e');
      rethrow;
    }
  }
  
  /// Background ML analysis (run periodically, not on every transaction)
  static Future<void> runBackgroundAnalysis() async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    try {
      // Process any pending transactions first
      await _processBatchedTransactions();
      
      // Run periodic analysis only if needed
      await EnhancedMLService.getAnomalyAlerts();
      await EnhancedMLService.getCashflowForecast();
      await EnhancedMLService.getPersonalizedAdvice();
    } finally {
      _isProcessing = false;
    }
  }
}