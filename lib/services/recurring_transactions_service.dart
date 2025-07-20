import 'dart:async';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import 'web_storage_service.dart';
import 'package:uuid/uuid.dart';

class RecurringTransactionsService {
  static Timer? _executionTimer;
  static bool _isInitialized = false;
  
  /// Initialize the recurring transactions service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🔄 Initializing Recurring Transactions Service...');
    
    // Execute any pending recurring transactions immediately
    await executeRecurringTransactions();
    
    // Setup periodic execution every hour
    _setupPeriodicExecution();
    
    _isInitialized = true;
    print('✅ Recurring Transactions Service initialized');
  }
  
  /// Setup periodic execution of recurring transactions
  static void _setupPeriodicExecution() {
    // Cancel existing timer if any
    _executionTimer?.cancel();
    
    // Execute every hour
    _executionTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      await executeRecurringTransactions();
    });
    
    print('⏰ Periodic execution setup - checking every hour');
  }
  
  /// Execute all pending recurring transactions
  static Future<List<Transaction>> executeRecurringTransactions() async {
    try {
      final recurringTransactions = await WebStorageService.getActiveRecurringTransactions();
      final executedTransactions = <Transaction>[];
      
      print('🔍 Checking ${recurringTransactions.length} active recurring transactions...');
      
      for (final recurringTransaction in recurringTransactions) {
        if (recurringTransaction.shouldExecuteToday()) {
          final transaction = await _executeRecurringTransaction(recurringTransaction);
          if (transaction != null) {
            executedTransactions.add(transaction);
          }
        }
      }
      
      if (executedTransactions.isNotEmpty) {
        print('✅ Executed ${executedTransactions.length} recurring transactions');
      } else {
        print('ℹ️ No recurring transactions due for execution');
      }
      
      return executedTransactions;
    } catch (e) {
      print('❌ Error executing recurring transactions: $e');
      return [];
    }
  }
  
  /// Execute a single recurring transaction
  static Future<Transaction?> _executeRecurringTransaction(RecurringTransaction recurringTransaction) async {
    try {
      // Create a new transaction from the recurring transaction
      final transaction = Transaction(
        id: const Uuid().v4(),
        amount: recurringTransaction.amount,
        description: '${recurringTransaction.description} (Auto)',
        categoryId: recurringTransaction.categoryId,
        date: DateTime.now(),
        type: recurringTransaction.type == 'income' ? TransactionType.income : TransactionType.expense,
        accountId: recurringTransaction.accountId,
        createdAt: DateTime.now(),
      );
      
      // Add the transaction
      await WebStorageService.addTransaction(transaction);
      
      // Update the recurring transaction's last executed date
      final updatedRecurringTransaction = recurringTransaction.copyWith(
        lastExecuted: DateTime.now(),
      );
      
      await WebStorageService.updateRecurringTransaction(updatedRecurringTransaction);
      
      print('💰 Executed recurring transaction: ${recurringTransaction.description}');
      return transaction;
    } catch (e) {
      print('❌ Error executing recurring transaction ${recurringTransaction.id}: $e');
      return null;
    }
  }
  
  /// Get upcoming recurring transactions (next 30 days)
  static Future<List<Map<String, dynamic>>> getUpcomingRecurringTransactions({int days = 30}) async {
    try {
      final recurringTransactions = await WebStorageService.getActiveRecurringTransactions();
      final upcoming = <Map<String, dynamic>>[];
      final now = DateTime.now();
      final endDate = now.add(Duration(days: days));
      
      for (final recurringTransaction in recurringTransactions) {
        final nextExecution = recurringTransaction.getNextExecutionDate();
        if (nextExecution != null && 
            nextExecution.isAfter(now) && 
            nextExecution.isBefore(endDate)) {
          upcoming.add({
            'recurringTransaction': recurringTransaction,
            'nextExecutionDate': nextExecution,
            'daysUntilExecution': nextExecution.difference(now).inDays,
          });
        }
      }
      
      // Sort by next execution date
      upcoming.sort((a, b) => 
        (a['nextExecutionDate'] as DateTime).compareTo(b['nextExecutionDate'] as DateTime)
      );
      
      return upcoming;
    } catch (e) {
      print('❌ Error getting upcoming recurring transactions: $e');
      return [];
    }
  }
  
  /// Get recurring transactions summary
  static Future<Map<String, dynamic>> getRecurringTransactionsSummary() async {
    try {
      final allRecurring = await WebStorageService.getRecurringTransactions();
      final activeRecurring = allRecurring.where((rt) => rt.isActive).toList();
      final inactiveRecurring = allRecurring.where((rt) => !rt.isActive).toList();
      
      // Calculate monthly impact
      double monthlyIncome = 0;
      double monthlyExpenses = 0;
      
      for (final rt in activeRecurring) {
        double monthlyAmount = 0;
        
        switch (rt.frequency) {
          case RecurrenceFrequency.daily:
            monthlyAmount = rt.amount * 30;
            break;
          case RecurrenceFrequency.weekly:
            monthlyAmount = rt.amount * 4.33; // Average weeks per month
            break;
          case RecurrenceFrequency.monthly:
            monthlyAmount = rt.amount;
            break;
          case RecurrenceFrequency.yearly:
            monthlyAmount = rt.amount / 12;
            break;
        }
        
        if (rt.type == 'income') {
          monthlyIncome += monthlyAmount;
        } else {
          monthlyExpenses += monthlyAmount;
        }
      }
      
      return {
        'totalRecurringTransactions': allRecurring.length,
        'activeRecurringTransactions': activeRecurring.length,
        'inactiveRecurringTransactions': inactiveRecurring.length,
        'estimatedMonthlyIncome': monthlyIncome,
        'estimatedMonthlyExpenses': monthlyExpenses,
        'estimatedMonthlyNet': monthlyIncome - monthlyExpenses,
      };
    } catch (e) {
      print('❌ Error getting recurring transactions summary: $e');
      return {};
    }
  }
  
  /// Manually trigger execution of a specific recurring transaction
  static Future<Transaction?> executeRecurringTransactionById(String recurringTransactionId) async {
    try {
      final recurringTransaction = await WebStorageService.getRecurringTransactionById(recurringTransactionId);
      if (recurringTransaction == null) {
        throw Exception('Recurring transaction not found: $recurringTransactionId');
      }
      
      return await _executeRecurringTransaction(recurringTransaction);
    } catch (e) {
      print('❌ Error manually executing recurring transaction: $e');
      rethrow;
    }
  }
  
  /// Pause a recurring transaction
  static Future<void> pauseRecurringTransaction(String recurringTransactionId) async {
    try {
      final recurringTransaction = await WebStorageService.getRecurringTransactionById(recurringTransactionId);
      if (recurringTransaction == null) {
        throw Exception('Recurring transaction not found: $recurringTransactionId');
      }
      
      final updatedRecurringTransaction = recurringTransaction.copyWith(isActive: false);
      await WebStorageService.updateRecurringTransaction(updatedRecurringTransaction);
      
      print('⏸️ Paused recurring transaction: ${recurringTransaction.description}');
    } catch (e) {
      print('❌ Error pausing recurring transaction: $e');
      rethrow;
    }
  }
  
  /// Resume a recurring transaction
  static Future<void> resumeRecurringTransaction(String recurringTransactionId) async {
    try {
      final recurringTransaction = await WebStorageService.getRecurringTransactionById(recurringTransactionId);
      if (recurringTransaction == null) {
        throw Exception('Recurring transaction not found: $recurringTransactionId');
      }
      
      final updatedRecurringTransaction = recurringTransaction.copyWith(isActive: true);
      await WebStorageService.updateRecurringTransaction(updatedRecurringTransaction);
      
      print('▶️ Resumed recurring transaction: ${recurringTransaction.description}');
    } catch (e) {
      print('❌ Error resuming recurring transaction: $e');
      rethrow;
    }
  }
  
  /// Dispose the service and cancel timers
  static void dispose() {
    _executionTimer?.cancel();
    _executionTimer = null;
    _isInitialized = false;
    print('🛑 Recurring Transactions Service disposed');
  }
}