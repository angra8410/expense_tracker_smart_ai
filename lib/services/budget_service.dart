import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import 'web_storage_service.dart';
import 'category_service.dart';

class BudgetService {
  static const String _budgetsKey = 'budgets';
  
  // Add callback mechanism for budget updates
  static final List<VoidCallback> _budgetUpdateCallbacks = [];
  
  /// Register a callback to be called when budgets need to be refreshed
  static void addBudgetUpdateListener(VoidCallback callback) {
    _budgetUpdateCallbacks.add(callback);
  }
  
  /// Remove a callback
  static void removeBudgetUpdateListener(VoidCallback callback) {
    _budgetUpdateCallbacks.remove(callback);
  }
  
  /// Notify all listeners that budgets should be refreshed
  static void notifyBudgetUpdate() {
    print('🔄 Notifying ${_budgetUpdateCallbacks.length} budget listeners to refresh');
    for (final callback in _budgetUpdateCallbacks) {
      try {
        callback();
      } catch (e) {
        print('❌ Error calling budget update callback: $e');
      }
    }
  }

  /// Create a budget from a smart recommendation
  static Future<Budget> createSmartBudget(BudgetRecommendation recommendation) async {
    final budget = Budget(
      id: 'budget_${DateTime.now().millisecondsSinceEpoch}',
      name: '${recommendation.categoryId} Budget',
      amount: recommendation.suggestedAmount,
      categoryId: recommendation.categoryId,
      period: BudgetPeriod.monthly,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      isActive: true,
      rolloverEnabled: false,
    );

    await _saveBudget(budget);
    notifyBudgetUpdate(); // Notify listeners
    return budget;
  }

  /// Get all active budgets
  static Future<List<Budget>> getActiveBudgets() async {
    try {
      final budgetsJson = await WebStorageService.getString(_budgetsKey);
      if (budgetsJson == null) return [];

      final List<dynamic> budgetsList = json.decode(budgetsJson);
      return budgetsList
          .map((json) => Budget.fromJson(json))
          .where((budget) => budget.isActive && budget.endDate.isAfter(DateTime.now()))
          .toList();
    } catch (e) {
      print('Error loading budgets: $e');
      return [];
    }
  }

  /// Get a specific budget by ID
  static Future<Budget?> getBudgetById(String id) async {
    final budgets = await getActiveBudgets();
    try {
      return budgets.firstWhere((budget) => budget.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Update an existing budget
  static Future<void> updateBudget(Budget budget) async {
    await _saveBudget(budget);
  }

  /// Delete a budget
  static Future<void> deleteBudget(String budgetId) async {
    final budgets = await getActiveBudgets();
    budgets.removeWhere((budget) => budget.id == budgetId);
    await _saveBudgets(budgets);
  }

  /// Calculate budget progress with rollover support
  static Future<BudgetProgress> getBudgetProgress(Budget budget) async {
    try {
      final transactions = await WebStorageService.getTransactions(includeTestData: false);
      
      final budgetTransactions = transactions.where((transaction) {
        final categoryMatch = transaction.categoryId == budget.categoryId;
        final typeMatch = transaction.type == TransactionType.expense;
        final dateAfterStart = transaction.date.isAfter(budget.startDate) || transaction.date.isAtSameMomentAs(budget.startDate);
        final dateBeforeEnd = transaction.date.isBefore(budget.endDate) || transaction.date.isAtSameMomentAs(budget.endDate);
        
        return categoryMatch && typeMatch && dateAfterStart && dateBeforeEnd;
      }).toList();

      final totalSpent = budgetTransactions.fold(0.0, (sum, transaction) => sum + transaction.amount);
      
      final remainingAmount = budget.totalBudgetAmount - totalSpent;
      final progressPercentage = budget.totalBudgetAmount > 0 ? (totalSpent / budget.totalBudgetAmount) * 100 : 0.0;

      BudgetStatus status;
      if (progressPercentage <= 75) {
        status = BudgetStatus.onTrack;
      } else if (progressPercentage <= 100) {
        status = BudgetStatus.warning;
      } else {
        status = BudgetStatus.exceeded;
      }

      // Calculate daily spending for the period
      final dailySpending = <DailySpending>[];
      final daysDifference = budget.endDate.difference(budget.startDate).inDays;
      
      for (int i = 0; i <= daysDifference; i++) {
        final day = budget.startDate.add(Duration(days: i));
        final dayTransactions = budgetTransactions.where((t) => 
          t.date.year == day.year && 
          t.date.month == day.month && 
          t.date.day == day.day
        ).toList();
        
        final dayAmount = dayTransactions.fold(0.0, (sum, t) => sum + t.amount);
        dailySpending.add(DailySpending(
          date: day, 
          amount: dayAmount,
          transactionCount: dayTransactions.length,
        ));
      }

      // Add a simple debug print to track refresh issues
      print('💰 Budget "${budget.name}": ${budgetTransactions.length} transactions, total spent: $totalSpent');

      return BudgetProgress(
        budget: budget,
        spent: totalSpent,
        remaining: remainingAmount,
        percentage: progressPercentage,
        status: status,
        dailySpending: dailySpending,
      );
    } catch (e) {
      print('❌ Error calculating budget progress: $e');
      return BudgetProgress(
        budget: budget,
        spent: 0.0,
        remaining: budget.totalBudgetAmount,
        percentage: 0.0,
        status: BudgetStatus.onTrack,
        dailySpending: [],
      );
    }
  }

  /// Get smart budget recommendations
  static Future<List<BudgetRecommendation>> getBudgetRecommendations() async {
    try {
      final transactions = await WebStorageService.getTransactions(includeTestData: false);
      final categories = await CategoryService.getCategories();
      
      if (transactions.isEmpty || categories.isEmpty) {
        return [];
      }

      final recommendations = <BudgetRecommendation>[];
      final now = DateTime.now();
      final lastMonth = now.subtract(const Duration(days: 30));
      
      final recentTransactions = transactions.where((t) => 
        t.date.isAfter(lastMonth) && t.type == TransactionType.expense
      ).toList();

      // Group spending by category
      final categorySpending = <String, double>{};
      for (final transaction in recentTransactions) {
        categorySpending[transaction.categoryId] = 
          (categorySpending[transaction.categoryId] ?? 0) + transaction.amount;
      }

      // Generate recommendations for top spending categories
      final sortedCategories = categorySpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in sortedCategories.take(5)) {
        final category = categories.firstWhere(
          (c) => c.id == entry.key,
          orElse: () => Category(
            id: entry.key, 
            name: 'Unknown', 
            iconCodePoint: Icons.help_outline.codePoint,
            colorValue: Colors.grey.value,
          ),
        );

        final avgMonthlySpending = entry.value;
        final suggestedBudget = avgMonthlySpending * 1.1; // 10% buffer

        recommendations.add(BudgetRecommendation(
          id: 'rec_${DateTime.now().millisecondsSinceEpoch}_${entry.key}',
          title: 'Budget for ${category.name}',
          description: 'Suggested budget based on recent spending patterns',
          categoryId: entry.key,
          suggestedAmount: suggestedBudget,
          suggestedPeriod: BudgetPeriod.monthly,
          reasoning: 'Based on your average monthly spending of \$${avgMonthlySpending.toStringAsFixed(2)} in ${category.name}',
          confidence: 0.8,
        ));
      }

      return recommendations;
    } catch (e) {
      print('Error generating budget recommendations: $e');
      return [];
    }
  }

  /// Handle budget rollovers for expired budgets
  static Future<void> handleBudgetRollovers() async {
    try {
      final allBudgets = await _getAllBudgets(); // Get all budgets including expired ones
      final now = DateTime.now();
      final updatedBudgets = <Budget>[];
      
      for (final budget in allBudgets) {
        if (budget.isActive && budget.endDate.isBefore(now)) {
          // Budget has expired, handle rollover
          if (budget.rolloverEnabled) {
            // Calculate remaining amount from previous period
            final progress = await getBudgetProgress(budget);
            final remainingAmount = progress.remaining > 0 ? progress.remaining : 0.0;
            
            // Create new budget for next period with rollover
            final newBudget = budget.copyWith(
              id: 'budget_${DateTime.now().millisecondsSinceEpoch}',
              startDate: budget.endDate,
              endDate: _calculateEndDate(budget.endDate, budget.period),
              rolloverAmount: remainingAmount,
            );
            
            // Deactivate old budget
            final expiredBudget = budget.copyWith(isActive: false);
            updatedBudgets.add(expiredBudget);
            updatedBudgets.add(newBudget);
            
            print('🔄 Budget rolled over: ${budget.name} with ${remainingAmount.toStringAsFixed(2)} remaining');
          } else {
            // Just create new budget without rollover
            final newBudget = budget.copyWith(
              id: 'budget_${DateTime.now().millisecondsSinceEpoch}',
              startDate: budget.endDate,
              endDate: _calculateEndDate(budget.endDate, budget.period),
              rolloverAmount: 0.0,
            );
            
            // Deactivate old budget
            final expiredBudget = budget.copyWith(isActive: false);
            updatedBudgets.add(expiredBudget);
            updatedBudgets.add(newBudget);
            
            print('📅 Budget renewed: ${budget.name} without rollover');
          }
        } else {
          // Budget is still active or already inactive
          updatedBudgets.add(budget);
        }
      }
      
      await _saveBudgets(updatedBudgets);
    } catch (e) {
      print('Error handling budget rollovers: $e');
    }
  }

  /// Get all budgets (including expired ones) for rollover processing
  static Future<List<Budget>> _getAllBudgets() async {
    try {
      final budgetsJson = await WebStorageService.getString(_budgetsKey);
      if (budgetsJson == null) return [];

      final List<dynamic> budgetsList = json.decode(budgetsJson);
      return budgetsList.map((json) => Budget.fromJson(json)).toList();
    } catch (e) {
      print('Error loading all budgets: $e');
      return [];
    }
  }

  // Private helper methods
  static DateTime _calculateEndDate(DateTime startDate, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return startDate.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case BudgetPeriod.yearly:
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
    }
  }

  static Future<void> _saveBudget(Budget budget) async {
    final budgets = await getActiveBudgets();
    final existingIndex = budgets.indexWhere((b) => b.id == budget.id);
    
    if (existingIndex >= 0) {
      budgets[existingIndex] = budget;
    } else {
      budgets.add(budget);
    }
    
    await _saveBudgets(budgets);
  }

  static Future<void> _saveBudgets(List<Budget> budgets) async {
    final budgetsJson = json.encode(budgets.map((b) => b.toJson()).toList());
    await WebStorageService.setString(_budgetsKey, budgetsJson);
  }
}