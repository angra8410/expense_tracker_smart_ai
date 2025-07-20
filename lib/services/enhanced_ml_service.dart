import 'dart:async';
import 'dart:math';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/ml_models.dart';
import '../models/ml_prediction_models.dart';
import 'ml_engine.dart';
import 'smart_ml_service.dart';
import 'web_storage_service.dart';

class CategoryPredictionResult {
  final String categoryId;
  final double confidence;

  CategoryPredictionResult({
    required this.categoryId,
    required this.confidence,
  });
}

class EnhancedMLService {
  static Timer? _mlTimer;
  static DateTime? _lastMLAnalysis;

  // Storage keys
  static const String _anomalyAlertsKey = 'anomaly_alerts';
  static const String _cashflowForecastKey = 'cashflow_forecast';
  static const String _personalizedAdviceKey = 'personalized_advice';
  static const String _userPatternsKey = 'user_patterns';
  static const String _anomalyThresholdsKey = 'anomaly_thresholds';
  static const String _predictionAccuracyKey = 'prediction_accuracy';

  static Future<void> initialize() async {
    _startPeriodicMLAnalysis();
  }

  static void dispose() {
    _mlTimer?.cancel();
  }

  /// Smart Category Prediction for new transactions
  static Future<String> predictCategoryForTransaction(
    String description,
    double amount,
  ) async {
    return await MLEngine.predictCategory(description, amount);
  }

  static Future<CategoryPredictionResult> predictCategoryWithConfidence(
    String description,
    double amount,
  ) async {
    try {
      final categoryId = await MLEngine.predictCategory(description, amount);
      
      // Calculate confidence based on pattern matching
      final patterns = await _loadUserPatterns();
      final tokens = description.toLowerCase().split(' ');
      
      double confidence = 0.5; // Base confidence
      
      final matchingPattern = patterns.firstWhere(
        (p) => p.categoryId == categoryId,
        orElse: () => UserPattern(
          categoryId: categoryId,
          keywords: [],
          averageAmount: 0.0,
          transactionCount: 0,
          confidence: 0.0,
        ),
      );
      
      if (matchingPattern.transactionCount > 0) {
        // Text similarity boost
        final commonKeywords = tokens.where((token) => 
            matchingPattern.keywords.contains(token)).length;
        confidence += (commonKeywords / tokens.length) * 0.3;
        
        // Amount similarity boost
        final amountDiff = (amount - matchingPattern.averageAmount).abs();
        final amountSimilarity = 1.0 - (amountDiff / (matchingPattern.averageAmount + amount));
        confidence += amountSimilarity * 0.2;
        
        // Pattern confidence boost
        confidence += matchingPattern.confidence * 0.1;
      }
      
      return CategoryPredictionResult(
        categoryId: categoryId,
        confidence: min(1.0, confidence),
      );
    } catch (e) {
      print('Error predicting category with confidence: $e');
      return CategoryPredictionResult(
        categoryId: 'general',
        confidence: 0.1,
      );
    }
  }

  /// Get smart description suggestions
  static Future<List<String>> getDescriptionSuggestions(
    String categoryId,
    double amount,
  ) async {
    try {
      final transactions = await WebStorageService.getTransactions();
      final categoryTransactions = transactions
          .where((t) => t.categoryId == categoryId)
          .toList();
      
      if (categoryTransactions.isEmpty) return [];
      
      // Get most common descriptions for this category
      final descriptionFrequency = <String, int>{};
      for (var transaction in categoryTransactions) {
        final description = transaction.description.toLowerCase().trim();
        if (description.isNotEmpty) {
          descriptionFrequency[description] = 
              (descriptionFrequency[description] ?? 0) + 1;
        }
      }
      
      // Sort by frequency and return top suggestions
      final sortedDescriptions = descriptionFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return sortedDescriptions
          .take(5)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      print('Error getting description suggestions: $e');
      return [];
    }
  }

  /// Get smart amount suggestions
  static Future<List<double>> getSuggestedAmounts(
    String categoryId,
    String description,
  ) async {
    try {
      final transactions = await WebStorageService.getTransactions();
      final categoryTransactions = transactions
          .where((t) => t.categoryId == categoryId)
          .toList();
      
      if (categoryTransactions.isEmpty) return [];
      
      // Filter by similar descriptions if provided
      List<Transaction> relevantTransactions = categoryTransactions;
      if (description.isNotEmpty) {
        final descriptionTokens = description.toLowerCase().split(' ');
        relevantTransactions = categoryTransactions.where((t) {
          final transactionTokens = t.description.toLowerCase().split(' ');
          final commonTokens = descriptionTokens.where((token) => 
              transactionTokens.contains(token)).length;
          return commonTokens > 0;
        }).toList();
        
        // Fall back to all category transactions if no matches
        if (relevantTransactions.isEmpty) {
          relevantTransactions = categoryTransactions;
        }
      }
      
      final amounts = relevantTransactions.map((t) => t.amount).toList();
      amounts.sort();
      
      // Return common amounts (mode, median, recent average)
      final suggestions = <double>{};
      
      // Add median
      if (amounts.isNotEmpty) {
        final median = amounts[amounts.length ~/ 2];
        suggestions.add(median);
      }
      
      // Add recent average (last 10 transactions)
      final recentTransactions = relevantTransactions
          .take(10)
          .map((t) => t.amount)
          .toList();
      
      if (recentTransactions.isNotEmpty) {
        final recentAverage = recentTransactions.reduce((a, b) => a + b) / recentTransactions.length;
        suggestions.add(recentAverage);
      }
      
      return suggestions.toList()..sort();
    } catch (e) {
      print('Error getting amount suggestions: $e');
      return [];
    }
  }

  /// Detect amount anomaly
  static Future<bool> detectAmountAnomaly(
    String categoryId,
    double amount,
  ) async {
    try {
      final transactions = await WebStorageService.getTransactions();
      final categoryTransactions = transactions
          .where((t) => t.categoryId == categoryId)
          .toList();
      
      if (categoryTransactions.length < 3) return false;
      
      final amounts = categoryTransactions.map((t) => t.amount).toList();
      final average = amounts.reduce((a, b) => a + b) / amounts.length;
      final variance = amounts.map((a) => pow(a - average, 2)).reduce((a, b) => a + b) / amounts.length;
      final standardDeviation = sqrt(variance);
      
      // Consider anomaly if amount is more than 2 standard deviations from mean
      return (amount - average).abs() > (2 * standardDeviation);
    } catch (e) {
      print('Error detecting amount anomaly: $e');
      return false;
    }
  }

  /// Learn from user transaction
  static Future<void> learnFromUserTransaction(Transaction transaction) async {
    try {
      await MLEngine.learnFromTransaction(transaction);
      await _updateUserPatterns(transaction);
    } catch (e) {
      print('Error learning from user transaction: $e');
    }
  }

  /// Get anomaly alerts
  static Future<List<AnomalyAlert>> getAnomalyAlerts() async {
    try {
      await _ensureRecentAnalysis();
      return await _loadAnomalyAlerts();
    } catch (e) {
      print('Error getting anomaly alerts: $e');
      return [];
    }
  }

  /// Get cashflow forecast
  static Future<List<CashflowForecast>> getCashflowForecast() async {
    try {
      await _ensureRecentAnalysis();
      return await _loadCashflowForecast();
    } catch (e) {
      print('Error getting cashflow forecast: $e');
      return [];
    }
  }

  /// Get personalized advice
  static Future<List<PersonalizedAdvice>> getPersonalizedAdvice() async {
    try {
      await _ensureRecentAnalysis();
      return await _loadPersonalizedAdvice();
    } catch (e) {
      print('Error getting personalized advice: $e');
      return [];
    }
  }

  /// Get spending insights
  static Future<Map<String, dynamic>> getSpendingInsights() async {
    try {
      final transactions = await WebStorageService.getTransactions();
      if (transactions.isEmpty) return {};

      final now = DateTime.now();
      final thisMonth = transactions.where((t) => 
        t.date.year == now.year && t.date.month == now.month).toList();
      
      final lastMonth = transactions.where((t) {
        final lastMonthDate = DateTime(now.year, now.month - 1);
        return t.date.year == lastMonthDate.year && t.date.month == lastMonthDate.month;
      }).toList();

      final thisMonthTotal = thisMonth.fold(0.0, (sum, t) => sum + t.amount);
      final lastMonthTotal = lastMonth.fold(0.0, (sum, t) => sum + t.amount);
      
      final changePercent = lastMonthTotal > 0 
          ? ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100
          : 0.0;

      return {
        'this_month_total': thisMonthTotal,
        'last_month_total': lastMonthTotal,
        'change_percent': changePercent,
        'transaction_count': thisMonth.length,
        'average_transaction': thisMonth.isNotEmpty ? thisMonthTotal / thisMonth.length : 0.0,
      };
    } catch (e) {
      print('Error getting spending insights: $e');
      return {};
    }
  }

  /// Get category insights
  static Future<Map<String, dynamic>> getCategoryInsights(String categoryId) async {
    try {
      final transactions = await WebStorageService.getTransactions();
      final categoryTransactions = transactions
          .where((t) => t.categoryId == categoryId)
          .toList();
      
      if (categoryTransactions.isEmpty) return {};

      final amounts = categoryTransactions.map((t) => t.amount).toList();
      amounts.sort();
      
      final total = amounts.reduce((a, b) => a + b);
      final average = total / amounts.length;
      final median = amounts[amounts.length ~/ 2];
      
      // Calculate trend (last 30 days vs previous 30 days)
      final now = DateTime.now();
      final last30Days = categoryTransactions.where((t) => 
        now.difference(t.date).inDays <= 30).toList();
      final previous30Days = categoryTransactions.where((t) {
        final daysDiff = now.difference(t.date).inDays;
        return daysDiff > 30 && daysDiff <= 60;
      }).toList();
      
      final last30Total = last30Days.fold(0.0, (sum, t) => sum + t.amount);
      final previous30Total = previous30Days.fold(0.0, (sum, t) => sum + t.amount);
      
      final trend = previous30Total > 0 
          ? ((last30Total - previous30Total) / previous30Total) * 100
          : 0.0;

      return {
        'total_spent': total,
        'average_amount': average,
        'median_amount': median,
        'transaction_count': categoryTransactions.length,
        'trend_percent': trend,
        'last_30_days_total': last30Total,
        'min_amount': amounts.first,
        'max_amount': amounts.last,
      };
    } catch (e) {
      print('Error getting category insights: $e');
      return {};
    }
  }

  /// Auto-categorize transaction
  static Future<String> autoCategorizTransaction(
    String description,
    double amount,
  ) async {
    try {
      return await MLEngine.predictCategory(description, amount);
    } catch (e) {
      print('Error auto-categorizing transaction: $e');
      return 'general';
    }
  }

  // Private helper methods
  static void _startPeriodicMLAnalysis() {
    _mlTimer = Timer.periodic(const Duration(hours: 6), (timer) {
      _performPeriodicAnalysis();
    });
  }

  static Future<void> _ensureRecentAnalysis() async {
    if (_lastMLAnalysis == null || 
        DateTime.now().difference(_lastMLAnalysis!).inHours > 6) {
      await _performPeriodicAnalysis();
    }
  }

  static Future<void> _performPeriodicAnalysis() async {
    try {
      final transactions = await WebStorageService.getTransactions();
      if (transactions.length < 10) return; // Need minimum data
      
      // Run anomaly detection
      final anomalies = await MLEngine.detectAnomalies(transactions);
      await _saveAnomalyAlerts(anomalies);
      
      // Generate cashflow forecast
      final forecast = await MLEngine.generateCashflowForecast(transactions);
      await _saveCashflowForecast([forecast]);
      
      // Generate personalized advice
      final advice = await MLEngine.generatePersonalizedAdvice(transactions);
      await _savePersonalizedAdvice(advice);
      
      _lastMLAnalysis = DateTime.now();
    } catch (e) {
      print('Error performing periodic ML analysis: $e');
    }
  }

  static Future<List<AnomalyAlert>> _loadAnomalyAlerts() async {
    try {
      final data = await WebStorageService.getList(_anomalyAlertsKey);
      return data.map((item) => AnomalyAlert.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> _saveAnomalyAlerts(List<AnomalyAlert> alerts) async {
    try {
      final data = alerts.map((alert) => alert.toJson()).toList();
      await WebStorageService.saveList(_anomalyAlertsKey, data);
    } catch (e) {
      print('Error saving anomaly alerts: $e');
    }
  }

  static Future<List<CashflowForecast>> _loadCashflowForecast() async {
    try {
      final data = await WebStorageService.getList(_cashflowForecastKey);
      return data.map((item) => CashflowForecast.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> _saveCashflowForecast(List<CashflowForecast> forecast) async {
    try {
      final data = forecast.map((item) => item.toJson()).toList();
      await WebStorageService.saveList(_cashflowForecastKey, data);
    } catch (e) {
      print('Error saving cashflow forecast: $e');
    }
  }

  static Future<List<PersonalizedAdvice>> _loadPersonalizedAdvice() async {
    try {
      final data = await WebStorageService.getList(_personalizedAdviceKey);
      return data.map((item) => PersonalizedAdvice.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> _savePersonalizedAdvice(List<PersonalizedAdvice> advice) async {
    try {
      final data = advice.map((item) => item.toJson()).toList();
      await WebStorageService.saveList(_personalizedAdviceKey, data);
    } catch (e) {
      print('Error saving personalized advice: $e');
    }
  }

  static Future<List<UserPattern>> _loadUserPatterns() async {
    try {
      final data = await WebStorageService.getList(_userPatternsKey);
      return data.map((item) => UserPattern.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, double>> _loadAnomalyThresholds() async {
    try {
      final data = await WebStorageService.getMap(_anomalyThresholdsKey);
      return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      return {};
    }
  }

  static Future<void> _updateUserPatterns(Transaction transaction) async {
    try {
      final patterns = await _loadUserPatterns();
      final existingPattern = patterns.firstWhere(
        (p) => p.categoryId == transaction.categoryId,
        orElse: () => UserPattern(
          categoryId: transaction.categoryId,
          keywords: [],
          averageAmount: 0.0,
          transactionCount: 0,
          confidence: 0.0,
        ),
      );

      // Update pattern with new transaction data
      final keywords = transaction.description.toLowerCase().split(' ');
      final updatedKeywords = Set<String>.from(existingPattern.keywords)..addAll(keywords);
      
      final newCount = existingPattern.transactionCount + 1;
      final newAverage = ((existingPattern.averageAmount * existingPattern.transactionCount) + transaction.amount) / newCount;
      
      final updatedPattern = UserPattern(
        categoryId: transaction.categoryId,
        keywords: updatedKeywords.toList(),
        averageAmount: newAverage,
        transactionCount: newCount,
        confidence: min(1.0, newCount / 10.0), // Confidence increases with more data
      );

      // Update patterns list
      final updatedPatterns = patterns.where((p) => p.categoryId != transaction.categoryId).toList();
      updatedPatterns.add(updatedPattern);
      
      // Save updated patterns
      final data = updatedPatterns.map((p) => p.toJson()).toList();
      await WebStorageService.saveList(_userPatternsKey, data);
    } catch (e) {
      print('Error updating user patterns: $e');
    }
  }

  static Future<double> _getCategoryPredictionAccuracy() async {
    try {
      final data = await WebStorageService.getMap(_predictionAccuracyKey);
      return (data['accuracy'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Track prediction accuracy for ML improvement
  static Future<void> trackPredictionAccuracy(
    String predictedCategoryId,
    String actualCategoryId,
  ) async {
    try {
      final data = await WebStorageService.getMap(_predictionAccuracyKey);
      final totalPredictions = (data['total'] as int?) ?? 0;
      final correctPredictions = (data['correct'] as int?) ?? 0;
      
      final newTotal = totalPredictions + 1;
      final newCorrect = correctPredictions + (predictedCategoryId == actualCategoryId ? 1 : 0);
      final newAccuracy = newCorrect / newTotal;
      
      await WebStorageService.saveMap(_predictionAccuracyKey, {
        'total': newTotal,
        'correct': newCorrect,
        'accuracy': newAccuracy,
      });
    } catch (e) {
      print('Error tracking prediction accuracy: $e');
    }
  }
}