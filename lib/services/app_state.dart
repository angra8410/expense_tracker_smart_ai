import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/category.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();
  
  // Core data
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<Category> _categories = [];
  
  // Loading states
  bool _isLoadingTransactions = false;
  bool _isLoadingBudgets = false;
  bool _isLoadingCategories = false;
  
  // Getters
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<Budget> get budgets => List.unmodifiable(_budgets);
  List<Category> get categories => List.unmodifiable(_categories);
  
  bool get isLoadingTransactions => _isLoadingTransactions;
  bool get isLoadingBudgets => _isLoadingBudgets;
  bool get isLoadingCategories => _isLoadingCategories;
  
  bool get isLoading => _isLoadingTransactions || _isLoadingBudgets || _isLoadingCategories;
  
  // Update methods
  void updateTransactions(List<Transaction> transactions) {
    _transactions = transactions;
    notifyListeners();
  }
  
  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    notifyListeners();
  }
  
  void updateTransaction(Transaction transaction) {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      notifyListeners();
    }
  }
  
  void removeTransaction(String transactionId) {
    _transactions.removeWhere((t) => t.id == transactionId);
    notifyListeners();
  }
  
  void updateBudgets(List<Budget> budgets) {
    _budgets = budgets;
    notifyListeners();
  }
  
  void updateCategories(List<Category> categories) {
    _categories = categories;
    notifyListeners();
  }
  
  // Loading state management
  void setLoadingTransactions(bool loading) {
    _isLoadingTransactions = loading;
    notifyListeners();
  }
  
  void setLoadingBudgets(bool loading) {
    _isLoadingBudgets = loading;
    notifyListeners();
  }
  
  void setLoadingCategories(bool loading) {
    _isLoadingCategories = loading;
    notifyListeners();
  }
  
  // Computed properties
  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
      
  double get totalExpenses => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
      
  double get balance => totalIncome - totalExpenses;
  
  // Filter methods
  List<Transaction> getTransactionsByPeriod(String period) {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (period) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }
    
    return _transactions.where((t) => 
      t.date.isAfter(startDate) || t.date.isAtSameMomentAs(startDate)
    ).toList();
  }
  
  List<Transaction> getTransactionsByCategory(String categoryId) {
    return _transactions.where((t) => t.categoryId == categoryId).toList();
  }
}