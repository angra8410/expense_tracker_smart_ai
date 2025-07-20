import 'dart:async';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/financial_intelligence.dart';
import 'financial_intelligence_engine.dart';
import 'web_storage_service.dart';

class IntelligenceService {
  static const String _insightsKey = 'financial_insights';
  static const String _metricsKey = 'financial_metrics';
  static const String _predictionsKey = 'spending_predictions';
  
  static Timer? _analysisTimer;
  static DateTime? _lastAnalysis;
  
  /// Initialize the intelligence service with periodic analysis
  static void initialize() {
    _startPeriodicAnalysis();
  }

  /// Dispose of resources
  static void dispose() {
    _analysisTimer?.cancel();
  }

  /// Get the latest financial insights
  static Future<List<FinancialInsight>> getLatestInsights() async {
    await _ensureRecentAnalysis();
    return await _loadInsights();
  }

  /// Get financial health metrics
  static Future<FinancialHealthMetrics?> getFinancialHealth() async {
    await _ensureRecentAnalysis();
    return await _loadMetrics();
  }

  /// Get spending predictions
  static Future<List<SpendingPrediction>> getSpendingPredictions() async {
    await _ensureRecentAnalysis();
    return await _loadPredictions();
  }

  /// Force a new analysis
  static Future<void> runAnalysis() async {
    try {
      final transactions = await WebStorageService.getTransactions();
      final categories = await WebStorageService.getCategories();

      // Generate insights
      final insights = await FinancialIntelligenceEngine.analyzeSpendingPatterns(
        transactions,
        categories,
      );

      // Calculate health metrics
      final healthScore = FinancialIntelligenceEngine.calculateFinancialHealthScore(transactions);
      final metrics = await _calculateDetailedMetrics(transactions, healthScore);

      // Generate predictions
      final predictions = await _generatePredictions(transactions);

      // Save results
      await _saveInsights(insights);
      await _saveMetrics(metrics);
      await _savePredictions(predictions);

      _lastAnalysis = DateTime.now();
    } catch (e) {
      print('Error running financial analysis: $e');
    }
  }

  /// Get insights for a specific category
  static Future<List<FinancialInsight>> getCategoryInsights(String categoryId) async {
    final allInsights = await getLatestInsights();
    return allInsights.where((insight) => insight.category == categoryId).toList();
  }

  /// Get actionable insights only
  static Future<List<FinancialInsight>> getActionableInsights() async {
    final allInsights = await getLatestInsights();
    return allInsights.where((insight) => insight.actionable).toList();
  }

  /// Mark an insight as acted upon
  static Future<void> markInsightActedUpon(String insightTitle) async {
    // Implementation for tracking user actions on insights
    // This could be used for learning user preferences
  }

  // Private methods
  static void _startPeriodicAnalysis() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(const Duration(hours: 6), (timer) {
      runAnalysis();
    });
  }

  static Future<void> _ensureRecentAnalysis() async {
    if (_lastAnalysis == null || 
        DateTime.now().difference(_lastAnalysis!).inHours > 24) {
      await runAnalysis();
    }
  }

  static Future<List<FinancialInsight>> _loadInsights() async {
    try {
      final data = await WebStorageService.getData(_insightsKey);
      if (data == null) return [];
      
      final List<dynamic> jsonList = data;
      return jsonList.map((json) => FinancialInsight.fromJson(json)).toList();
    } catch (e) {
      print('Error loading insights: $e');
      return [];
    }
  }

  static Future<void> _saveInsights(List<FinancialInsight> insights) async {
    try {
      final jsonList = insights.map((insight) => insight.toJson()).toList();
      await WebStorageService.saveData(_insightsKey, jsonList);
    } catch (e) {
      print('Error saving insights: $e');
    }
  }

  static Future<FinancialHealthMetrics?> _loadMetrics() async {
    try {
      final data = await WebStorageService.getData(_metricsKey);
      if (data == null) return null;
      
      return FinancialHealthMetrics.fromJson(data);
    } catch (e) {
      print('Error loading metrics: $e');
      return null;
    }
  }

  static Future<void> _saveMetrics(FinancialHealthMetrics metrics) async {
    try {
      await WebStorageService.saveData(_metricsKey, metrics.toJson());
    } catch (e) {
      print('Error saving metrics: $e');
    }
  }

  static Future<List<SpendingPrediction>> _loadPredictions() async {
    try {
      final data = await WebStorageService.getData(_predictionsKey);
      if (data == null) return [];
      
      final List<dynamic> jsonList = data;
      return jsonList.map((json) => SpendingPrediction.fromJson(json)).toList();
    } catch (e) {
      print('Error loading predictions: $e');
      return [];
    }
  }

  static Future<void> _savePredictions(List<SpendingPrediction> predictions) async {
    try {
      final jsonList = predictions.map((prediction) => prediction.toJson()).toList();
      await WebStorageService.saveData(_predictionsKey, jsonList);
    } catch (e) {
      print('Error saving predictions: $e');
    }
  }

  static Future<FinancialHealthMetrics> _calculateDetailedMetrics(
    List<Transaction> transactions,
    double overallScore,
  ) async {
    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));
    
    final recentTransactions = transactions
        .where((t) => t.date.isAfter(lastMonth))
        .toList();

    final income = recentTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final expenses = recentTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final savingsRate = income > 0 ? (income - expenses) / income : 0.0;
    final debtToIncomeRatio = 0.0; // Would need debt tracking
    
    // Calculate expense variability
    final dailyExpenses = <double>[];
    for (int i = 0; i < 30; i++) {
      final day = lastMonth.add(Duration(days: i));
      final dayExpenses = recentTransactions
          .where((t) => t.type == TransactionType.expense && 
                       t.date.day == day.day && 
                       t.date.month == day.month)
          .fold(0.0, (sum, t) => sum + t.amount);
      dailyExpenses.add(dayExpenses);
    }
    
    final avgDailyExpense = dailyExpenses.isNotEmpty 
        ? dailyExpenses.reduce((a, b) => a + b) / dailyExpenses.length 
        : 0.0;
    
    final variance = dailyExpenses.isNotEmpty
        ? dailyExpenses.map((x) => (x - avgDailyExpense) * (x - avgDailyExpense))
            .reduce((a, b) => a + b) / dailyExpenses.length
        : 0.0;
    
    final expenseVariability = avgDailyExpense > 0 ? variance / avgDailyExpense : 0.0;

    // Transaction consistency (days with transactions)
    final transactionDays = recentTransactions
        .map((t) => '${t.date.year}-${t.date.month}-${t.date.day}')
        .toSet()
        .length;

    // Category scores
    final categoryScores = <String, double>{};
    final categorySpending = <String, double>{};
    
    for (var transaction in recentTransactions) {
      if (transaction.type == TransactionType.expense) {
        categorySpending[transaction.categoryId] = 
            (categorySpending[transaction.categoryId] ?? 0) + transaction.amount;
      }
    }
    
    final totalSpending = categorySpending.values.fold(0.0, (a, b) => a + b);
    for (var entry in categorySpending.entries) {
      final percentage = totalSpending > 0 ? entry.value / totalSpending : 0.0;
      // Score based on reasonable spending percentages
      if (percentage < 0.4) {
        categoryScores[entry.key] = 100.0;
      } else if (percentage < 0.6) {
        categoryScores[entry.key] = 70.0;
      } else {
        categoryScores[entry.key] = 40.0;
      }
    }

    return FinancialHealthMetrics(
      overallScore: overallScore,
      savingsRate: savingsRate,
      debtToIncomeRatio: debtToIncomeRatio,
      expenseVariability: expenseVariability,
      transactionConsistency: transactionDays,
      categoryScores: categoryScores,
    );
  }

  static Future<List<SpendingPrediction>> _generatePredictions(
    List<Transaction> transactions,
  ) async {
    final predictions = <SpendingPrediction>[];
    
    // Predict spending for next 7, 14, and 30 days
    final predictionPeriods = [7, 14, 30];
    
    for (final days in predictionPeriods) {
      final categoryPredictions = await FinancialIntelligenceEngine
          .predictFutureSpending(transactions, days);
      
      for (var entry in categoryPredictions.entries) {
        predictions.add(SpendingPrediction(
          categoryId: entry.key,
          predictedAmount: entry.value,
          confidence: 0.7, // Base confidence
          forDate: DateTime.now().add(Duration(days: days)),
          methodology: 'Linear trend analysis with ${transactions.length} historical transactions',
        ));
      }
    }
    
    return predictions;
  }
}