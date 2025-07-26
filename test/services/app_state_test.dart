import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker_smart_ai/models/transaction.dart';
import 'package:expense_tracker_smart_ai/services/app_state.dart';

void main() {
  group('AppState Tests', () {
    late AppState appState;
    
    setUp(() {
      appState = AppState();
    });
    
    test('should add transaction correctly', () {
      // Arrange
      final transaction = Transaction(
        id: 'test_1',
        description: 'Test Transaction',
        amount: 100.0,
        categoryId: 'food',
        date: DateTime.now(),
        type: TransactionType.expense,
        accountId: 'default',
        createdAt: DateTime.now(),
      );
      
      // Act
      appState.addTransaction(transaction);
      
      // Assert
      expect(appState.transactions.length, 1);
      expect(appState.transactions.first.id, 'test_1');
      expect(appState.totalExpenses, 100.0);
    });
    
    test('should calculate balance correctly', () {
      // Arrange
      final income = Transaction(
        id: 'income_1',
        description: 'Salary',
        amount: 1000.0,
        categoryId: 'salary',
        date: DateTime.now(),
        type: TransactionType.income,
        accountId: 'default',
        createdAt: DateTime.now(),
      );
      
      final expense = Transaction(
        id: 'expense_1',
        description: 'Groceries',
        amount: 200.0,
        categoryId: 'food',
        date: DateTime.now(),
        type: TransactionType.expense,
        accountId: 'default',
        createdAt: DateTime.now(),
      );
      
      // Act
      appState.addTransaction(income);
      appState.addTransaction(expense);
      
      // Assert
      expect(appState.totalIncome, 1000.0);
      expect(appState.totalExpenses, 200.0);
      expect(appState.balance, 800.0);
    });
    
    test('should filter transactions by period correctly', () {
      // Arrange
      final now = DateTime.now();
      final thisMonth = Transaction(
        id: 'this_month',
        description: 'This Month',
        amount: 100.0,
        categoryId: 'food',
        date: DateTime(now.year, now.month, 15),
        type: TransactionType.expense,
        accountId: 'default',
        createdAt: now,
      );
      
      final lastMonth = Transaction(
        id: 'last_month',
        description: 'Last Month',
        amount: 100.0,
        categoryId: 'food',
        date: DateTime(now.year, now.month - 1, 15),
        type: TransactionType.expense,
        accountId: 'default',
        createdAt: now,
      );
      
      appState.addTransaction(thisMonth);
      appState.addTransaction(lastMonth);
      
      // Act
      final monthlyTransactions = appState.getTransactionsByPeriod('month');
      
      // Assert
      expect(monthlyTransactions.length, 1);
      expect(monthlyTransactions.first.id, 'this_month');
    });
  });
}