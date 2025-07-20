import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../widgets/alert_center.dart';

class TransactionsService {
  static const String _storageKey = 'transactions';
  static const String _localStorageKey = 'expense_tracker_transactions';
  static BuildContext? _context; // For showing alerts
  
  /// Set the context for showing alerts
  static void setContext(BuildContext context) {
    _context = context;
  }

  /// Add a new transaction
  static Future<void> addTransaction(Transaction tx) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Force reload to ensure we have the latest data
      await prefs.reload();
      
      final transactions = await getTransactions();
      transactions.add(tx);
      final encoded = jsonEncode(transactions.map((t) => t.toJson()).toList());
      
      // Save to SharedPreferences
      await prefs.setString(_storageKey, encoded);
      
      // Backup to localStorage
      try {
        html.window.localStorage[_localStorageKey] = encoded;
        print('✅ Transaction saved to both SharedPreferences and localStorage');
        
        // Show success alert (but only occasionally to avoid too many alerts)
        if (_context != null && DateTime.now().second % 5 == 0) {
          AlertCenter.showSuccess(_context!, 'Transaction saved successfully');
        }
      } catch (e) {
        print('❌ Error backing up transaction to localStorage in TransactionsService: $e');
      }
    } catch (e) {
      print('❌ Error adding transaction in TransactionsService: $e');
      
      // Show error alert
      if (_context != null) {
        AlertCenter.showError(_context!, 'Error saving transaction, attempting backup');
      }
      
      // Attempt direct localStorage backup as last resort
      try {
        final transactions = await getTransactions();
        transactions.add(tx);
        final encoded = jsonEncode(transactions.map((t) => t.toJson()).toList());
        html.window.localStorage[_localStorageKey] = encoded;
        print('✅ Transaction backed up to localStorage as fallback in TransactionsService');
        
        // Show success alert for backup
        if (_context != null) {
          AlertCenter.showWarning(_context!, 'Transaction saved to backup storage');
        }
      } catch (innerError) {
        print('❌ Critical error: Failed to backup transaction to localStorage in TransactionsService: $innerError');
        
        // Show critical error alert
        if (_context != null) {
          AlertCenter.showError(_context!, 'Critical error: Could not save transaction');
        }
      }
    }
  }

  /// Get all transactions
  static Future<List<Transaction>> getTransactions({bool includeTestData = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Force reload to ensure we have the latest data from storage
      await prefs.reload();
      
      String? encoded = prefs.getString(_storageKey);
      
      // If SharedPreferences is empty, try to restore from localStorage
      if (encoded == null) {
        try {
          encoded = html.window.localStorage[_localStorageKey];
          if (encoded != null) {
            // Save back to SharedPreferences for future use
            await prefs.setString(_storageKey, encoded);
            print('✅ Restored transactions from localStorage in TransactionsService');
            
            // Show info alert
            if (_context != null) {
              AlertCenter.showInfo(_context!, 'Restored transactions from backup storage');
            }
          }
        } catch (e) {
          print('❌ Error restoring transactions from localStorage in TransactionsService: $e');
        }
      }
      
      // If still null after restoration attempt, return empty list
      if (encoded == null) return [];
      
      final List<dynamic> decoded = jsonDecode(encoded);
      final transactions = decoded.map((e) => Transaction.fromJson(e)).toList();
      
      // Filter out test transactions if requested
      if (!includeTestData) {
        return transactions.where((tx) => !tx.id.startsWith('test')).toList();
      }
      
      return transactions;
    } catch (e) {
      print('❌ Error getting transactions in TransactionsService: $e');
      
      // Show error alert
      if (_context != null) {
        AlertCenter.showError(_context!, 'Error retrieving transactions, trying backup');
      }
      
      // Try to get from localStorage as last resort
      try {
        final localStorageData = html.window.localStorage[_localStorageKey];
        if (localStorageData != null) {
          final List<dynamic> decoded = jsonDecode(localStorageData);
          final transactions = decoded.map((e) => Transaction.fromJson(e)).toList();
          
          // Show success alert for backup retrieval
          if (_context != null) {
            AlertCenter.showWarning(_context!, 'Retrieved transactions from backup storage');
          }
          
          // Filter out test transactions if requested
          if (!includeTestData) {
            return transactions.where((tx) => !tx.id.startsWith('test')).toList();
          }
          
          return transactions;
        }
      } catch (innerError) {
        print('❌ Critical error: Failed to get transactions from localStorage in TransactionsService: $innerError');
        
        // Show critical error alert
        if (_context != null) {
          AlertCenter.showError(_context!, 'Critical error: Could not retrieve transactions');
        }
      }
      
      return [];
    }
  }

  /// Save transactions
  static Future<void> saveTransactions(List<Transaction> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Force reload to ensure we have the latest data
      await prefs.reload();
      
      final encoded = jsonEncode(transactions.map((t) => t.toJson()).toList());
      
      // Save to SharedPreferences
      await prefs.setString(_storageKey, encoded);
      
      // Backup to localStorage
      try {
        html.window.localStorage[_localStorageKey] = encoded;
        print('✅ Transactions saved to both SharedPreferences and localStorage');
        
        // Show success alert (but only occasionally to avoid too many alerts)
        if (_context != null && DateTime.now().second % 5 == 0) {
          AlertCenter.showSuccess(_context!, 'Transactions saved successfully');
        }
      } catch (e) {
        print('❌ Error backing up transactions to localStorage in TransactionsService: $e');
      }
    } catch (e) {
      print('❌ Error saving transactions in TransactionsService: $e');
      
      // Show error alert
      if (_context != null) {
        AlertCenter.showError(_context!, 'Error saving transactions, attempting backup');
      }
      
      // Attempt direct localStorage backup as last resort
      try {
        final encoded = jsonEncode(transactions.map((t) => t.toJson()).toList());
        html.window.localStorage[_localStorageKey] = encoded;
        print('✅ Transactions backed up to localStorage as fallback in TransactionsService');
        
        // Show success alert for backup
        if (_context != null) {
          AlertCenter.showWarning(_context!, 'Transactions saved to backup storage');
        }
      } catch (innerError) {
        print('❌ Critical error: Failed to backup transactions to localStorage in TransactionsService: $innerError');
        
        // Show critical error alert
        if (_context != null) {
          AlertCenter.showError(_context!, 'Critical error: Could not save transactions');
        }
      }
    }
  }

  /// Clear all transactions
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      
      // Also clear from localStorage
      try {
        html.window.localStorage.remove(_localStorageKey);
        print('✅ Transactions cleared from both SharedPreferences and localStorage');
        
        // Show success alert
        if (_context != null) {
          AlertCenter.showSuccess(_context!, 'All transactions cleared successfully');
        }
      } catch (e) {
        print('❌ Error clearing transactions from localStorage in TransactionsService: $e');
      }
    } catch (e) {
      print('❌ Error clearing transactions in TransactionsService: $e');
      
      // Show error alert
      if (_context != null) {
        AlertCenter.showError(_context!, 'Error clearing transactions');
      }
    }
  }
}