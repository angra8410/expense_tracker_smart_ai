import 'dart:math';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/financial_intelligence.dart';

class FinancialIntelligenceEngine {
  static const double _anomalyThreshold = 2.0; // Standard deviations
  static const int _minTransactionsForAnalysis = 10;
  static const int _trendAnalysisDays = 30;

  /// Analyzes spending patterns and generates intelligent insights
  static Future<List<FinancialInsight>> analyzeSpendingPatterns(
    List<Transaction> transactions,
    List<Category> categories,
  ) async {
    if (transactions.length < _minTransactionsForAnalysis) {
      return [
        FinancialInsight(
          type: InsightType.recommendation,
          title: 'Need More Data',
          description: 'Add more transactions to get personalized insights',
          confidence: 1.0,
          actionable: true,
          category: 'general',
        ),
      ];
    }

    List<FinancialInsight> insights = [];

    // Spending pattern analysis
    insights.addAll(await _analyzeSpendingTrends(transactions));
    
    // Anomaly detection
    insights.addAll(await _detectAnomalies(transactions));
    
    // Category optimization
    insights.addAll(await _analyzeCategoryOptimization(transactions, categories));
    
    // Recurring transaction detection
    insights.addAll(await _detectRecurringTransactions(transactions));
    
    // Budget recommendations
    insights.addAll(await _generateBudgetRecommendations(transactions));
    
    // Savings opportunities
    insights.addAll(await _identifySavingsOpportunities(transactions));

    return insights..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  /// Predicts future spending based on historical data
  static Future<Map<String, double>> predictFutureSpending(
    List<Transaction> transactions,
    int daysAhead,
  ) async {
    if (transactions.isEmpty) return {};

    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    if (expenses.length < 7) return {};

    // Group by category and calculate daily averages
    Map<String, List<double>> categoryDailySpending = {};
    
    for (var transaction in expenses) {
      final category = transaction.categoryId;
      categoryDailySpending.putIfAbsent(category, () => []);
      categoryDailySpending[category]!.add(transaction.amount);
    }

    Map<String, double> predictions = {};
    
    for (var entry in categoryDailySpending.entries) {
      final amounts = entry.value;
      final average = amounts.reduce((a, b) => a + b) / amounts.length;
      final trend = _calculateTrend(amounts);
      
      // Simple linear prediction with trend adjustment
      predictions[entry.key] = (average + (trend * daysAhead)) * daysAhead;
    }

    return predictions;
  }

  /// Calculates financial health score (0-100)
  static double calculateFinancialHealthScore(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0.0;

    double score = 50.0; // Base score
    
    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));
    final recentTransactions = transactions
        .where((t) => t.date.isAfter(lastMonth))
        .toList();

    if (recentTransactions.isEmpty) return score;

    final income = recentTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final expenses = recentTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Income vs Expenses ratio (30 points)
    if (income > 0) {
      final ratio = expenses / income;
      if (ratio < 0.5) score += 30;
      else if (ratio < 0.7) score += 20;
      else if (ratio < 0.9) score += 10;
      else if (ratio > 1.2) score -= 20;
    }

    // Savings rate (25 points)
    final savingsRate = income > 0 ? (income - expenses) / income : 0;
    if (savingsRate > 0.2) score += 25;
    else if (savingsRate > 0.1) score += 15;
    else if (savingsRate > 0.05) score += 5;
    else if (savingsRate < 0) score -= 15;

    // Transaction consistency (20 points)
    final transactionDays = recentTransactions
        .map((t) => t.date.day)
        .toSet()
        .length;
    if (transactionDays > 15) score += 20;
    else if (transactionDays > 10) score += 10;

    // Category diversification (15 points)
    final categories = recentTransactions
        .map((t) => t.categoryId)
        .toSet()
        .length;
    if (categories > 5) score += 15;
    else if (categories > 3) score += 10;
    else if (categories > 1) score += 5;

    // Emergency fund indicator (10 points)
    final avgMonthlyExpenses = expenses;
    final currentBalance = income - expenses;
    if (currentBalance > avgMonthlyExpenses * 3) score += 10;
    else if (currentBalance > avgMonthlyExpenses) score += 5;

    return score.clamp(0.0, 100.0);
  }

  // Private helper methods
  static Future<List<FinancialInsight>> _analyzeSpendingTrends(
    List<Transaction> transactions,
  ) async {
    List<FinancialInsight> insights = [];
    
    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));
    final previousMonth = now.subtract(const Duration(days: 60));
    
    final currentMonthExpenses = transactions
        .where((t) => t.type == TransactionType.expense && t.date.isAfter(lastMonth))
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final previousMonthExpenses = transactions
        .where((t) => t.type == TransactionType.expense && 
                     t.date.isAfter(previousMonth) && 
                     t.date.isBefore(lastMonth))
        .fold(0.0, (sum, t) => sum + t.amount);

    if (previousMonthExpenses > 0) {
      final changePercent = ((currentMonthExpenses - previousMonthExpenses) / previousMonthExpenses) * 100;
      
      if (changePercent > 20) {
        insights.add(FinancialInsight(
          type: InsightType.warning,
          title: 'Spending Increase Alert',
          description: 'Your spending increased by ${changePercent.toStringAsFixed(1)}% this month',
          confidence: 0.9,
          actionable: true,
          category: 'spending',
        ));
      } else if (changePercent < -15) {
        insights.add(FinancialInsight(
          type: InsightType.achievement,
          title: 'Great Savings!',
          description: 'You reduced spending by ${(-changePercent).toStringAsFixed(1)}% this month',
          confidence: 0.9,
          actionable: false,
          category: 'savings',
        ));
      }
    }

    return insights;
  }

  static Future<List<FinancialInsight>> _detectAnomalies(
    List<Transaction> transactions,
  ) async {
    List<FinancialInsight> insights = [];
    
    // Group by category for anomaly detection
    Map<String, List<double>> categoryAmounts = {};
    for (var transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        categoryAmounts.putIfAbsent(transaction.categoryId, () => []);
        categoryAmounts[transaction.categoryId]!.add(transaction.amount);
      }
    }

    for (var entry in categoryAmounts.entries) {
      final amounts = entry.value;
      if (amounts.length < 5) continue;

      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final variance = amounts.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / amounts.length;
      final stdDev = sqrt(variance);

      final recentAmount = amounts.last;
      if ((recentAmount - mean).abs() > stdDev * _anomalyThreshold) {
        insights.add(FinancialInsight(
          type: InsightType.anomaly,
          title: 'Unusual Spending Detected',
          description: 'Recent ${entry.key} expense of \$${recentAmount.toStringAsFixed(2)} is unusual for you',
          confidence: 0.8,
          actionable: true,
          category: entry.key,
        ));
      }
    }

    return insights;
  }

  static Future<List<FinancialInsight>> _analyzeCategoryOptimization(
    List<Transaction> transactions,
    List<Category> categories,
  ) async {
    List<FinancialInsight> insights = [];
    
    // Calculate spending by category
    Map<String, double> categorySpending = {};
    for (var transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        categorySpending[transaction.categoryId] = 
            (categorySpending[transaction.categoryId] ?? 0) + transaction.amount;
      }
    }

    final totalSpending = categorySpending.values.fold(0.0, (a, b) => a + b);
    
    // Find categories with high spending percentage
    for (var entry in categorySpending.entries) {
      final percentage = (entry.value / totalSpending) * 100;
      
      if (percentage > 30) {
        insights.add(FinancialInsight(
          type: InsightType.recommendation,
          title: 'High Category Spending',
          description: '${entry.key} represents ${percentage.toStringAsFixed(1)}% of your spending. Consider reviewing this category.',
          confidence: 0.7,
          actionable: true,
          category: entry.key,
        ));
      }
    }

    return insights;
  }

  static Future<List<FinancialInsight>> _detectRecurringTransactions(
    List<Transaction> transactions,
  ) async {
    List<FinancialInsight> insights = [];
    
    // Group by amount and description to find recurring patterns
    Map<String, List<Transaction>> potentialRecurring = {};
    
    for (var transaction in transactions) {
      final key = '${transaction.amount}_${transaction.description}';
      potentialRecurring.putIfAbsent(key, () => []);
      potentialRecurring[key]!.add(transaction);
    }

    for (var entry in potentialRecurring.entries) {
      final transactions = entry.value;
      if (transactions.length >= 3) {
        // Check if they occur at regular intervals
        transactions.sort((a, b) => a.date.compareTo(b.date));
        
        final intervals = <int>[];
        for (int i = 1; i < transactions.length; i++) {
          intervals.add(transactions[i].date.difference(transactions[i-1].date).inDays);
        }
        
        final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
        final isRegular = intervals.every((interval) => (interval - avgInterval).abs() <= 3);
        
        if (isRegular) {
          insights.add(FinancialInsight(
            type: InsightType.pattern,
            title: 'Recurring Transaction Detected',
            description: '${transactions.first.description} appears to be a recurring ${transactions.first.type.name} every ${avgInterval.round()} days',
            confidence: 0.8,
            actionable: true,
            category: transactions.first.categoryId,
          ));
        }
      }
    }

    return insights;
  }

  static Future<List<FinancialInsight>> _generateBudgetRecommendations(
    List<Transaction> transactions,
  ) async {
    List<FinancialInsight> insights = [];
    
    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));
    
    final monthlyIncome = transactions
        .where((t) => t.type == TransactionType.income && t.date.isAfter(lastMonth))
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final monthlyExpenses = transactions
        .where((t) => t.type == TransactionType.expense && t.date.isAfter(lastMonth))
        .fold(0.0, (sum, t) => sum + t.amount);

    if (monthlyIncome > 0) {
      // 50/30/20 rule recommendations
      final needs = monthlyIncome * 0.5;
      final wants = monthlyIncome * 0.3;
      final savings = monthlyIncome * 0.2;
      
      if (monthlyExpenses > needs + wants) {
        insights.add(FinancialInsight(
          type: InsightType.recommendation,
          title: 'Budget Optimization',
          description: 'Consider the 50/30/20 rule: 50% needs (\$${needs.toStringAsFixed(2)}), 30% wants (\$${wants.toStringAsFixed(2)}), 20% savings (\$${savings.toStringAsFixed(2)})',
          confidence: 0.7,
          actionable: true,
          category: 'budget',
        ));
      }
    }

    return insights;
  }

  static Future<List<FinancialInsight>> _identifySavingsOpportunities(
    List<Transaction> transactions,
  ) async {
    List<FinancialInsight> insights = [];
    
    // Analyze subscription-like patterns
    final subscriptionKeywords = ['subscription', 'monthly', 'netflix', 'spotify', 'gym', 'membership'];
    
    final potentialSubscriptions = transactions
        .where((t) => t.type == TransactionType.expense)
        .where((t) => subscriptionKeywords.any((keyword) => 
            t.description.toLowerCase().contains(keyword)))
        .toList();

    if (potentialSubscriptions.isNotEmpty) {
      final totalSubscriptionCost = potentialSubscriptions
          .fold(0.0, (sum, t) => sum + t.amount);
      
      insights.add(FinancialInsight(
        type: InsightType.opportunity,
        title: 'Subscription Review',
        description: 'You have \$${totalSubscriptionCost.toStringAsFixed(2)} in potential subscriptions. Review if all are still needed.',
        confidence: 0.6,
        actionable: true,
        category: 'subscriptions',
      ));
    }

    return insights;
  }

  static double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0.0;
    
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    int n = values.length;
    
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumXX += i * i;
    }
    
    return (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
  }
}