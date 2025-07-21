import 'dart:math';
import '../models/transaction.dart';
import '../models/ml_models.dart';
import '../services/web_storage_service.dart';
import '../services/ml_engine.dart';

class EnhancedMLService {
  static const String _anomalyAlertsKey = 'anomaly_alerts';
  static const String _cashflowForecastKey = 'cashflow_forecast';
  static const String _personalizedAdviceKey = 'personalized_advice';
  static const String _userPatternsKey = 'user_patterns';
  static const String _anomalyThresholdsKey = 'anomaly_thresholds';
  static const String _predictionAccuracyKey = 'prediction_accuracy';

  // Auto-categorization with ML
  static Future<String> autoCategorizeTransaction(String description, double amount) async {
    try {
      return await MLEngine.predictCategory(description, amount);
    } catch (e) {
      print('Error in auto-categorization: $e');
      return 'other';
    }
  }

  // Periodic ML analysis
  static Future<void> performPeriodicAnalysis() async {
    try {
      final transactions = await WebStorageService.getTransactions();
      
      if (transactions.isEmpty) return;

      // Anomaly detection
      final anomalies = await MLEngine.detectAnomalies(transactions);
      await _saveAnomalyAlerts(anomalies);

      // Cashflow forecasting
      final forecast = await MLEngine.generateCashflowForecast(transactions);
      await _saveCashflowForecast(forecast);

      // Personalized advice
      final advice = await MLEngine.generatePersonalizedAdvice(transactions);
      await _savePersonalizedAdvice(advice);

    } catch (e) {
      print('Error in periodic ML analysis: $e');
    }
  }

  // Learn from user transaction
  static Future<void> learnFromUserTransaction(Transaction transaction) async {
    try {
      await MLEngine.learnFromTransaction(transaction);
    } catch (e) {
      print('Error learning from transaction: $e');
    }
  }

  // Check if transaction is anomalous
  static Future<bool> isAnomalousTransaction(Transaction transaction) async {
    try {
      final transactions = await WebStorageService.getTransactions();
      final categoryTransactions = transactions.where((t) => t.categoryId == transaction.categoryId).toList();
      
      if (categoryTransactions.length < 3) return false;
      
      final amounts = categoryTransactions.map((t) => t.amount).toList();
      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final variance = amounts.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / amounts.length;
      final stdDev = sqrt(variance);
      
      final zScore = (transaction.amount - mean) / stdDev;
      return zScore.abs() > 2.0;
    } catch (e) {
      print('Error checking anomalous transaction: $e');
      return false;
    }
  }

  // Get category prediction confidence
  static Future<double> getCategoryPredictionConfidence(String description, String predictedCategory) async {
    try {
      // Simple confidence calculation based on keyword matching
      final descriptionLower = description.toLowerCase();
      final categoryKeywords = {
        'food': ['restaurant', 'food', 'grocery', 'cafe', 'pizza', 'burger', 'coffee'],
        'transport': ['gas', 'fuel', 'uber', 'taxi', 'bus', 'train', 'parking'],
        'shopping': ['store', 'shop', 'mall', 'amazon', 'purchase', 'buy'],
        'entertainment': ['movie', 'cinema', 'game', 'music', 'concert', 'theater'],
        'utilities': ['electric', 'water', 'gas', 'internet', 'phone', 'utility'],
        'healthcare': ['doctor', 'hospital', 'pharmacy', 'medical', 'health'],
      };

      final keywords = categoryKeywords[predictedCategory] ?? [];
      int matches = 0;
      for (var keyword in keywords) {
        if (descriptionLower.contains(keyword)) matches++;
      }
      
      return matches > 0 ? min(1.0, matches / 3.0) : 0.1;
    } catch (e) {
      print('Error getting prediction confidence: $e');
      return 0.1;
    }
  }

  // Generate transaction insights
  static Future<List<String>> generateTransactionInsights(Transaction transaction) async {
    try {
      final insights = <String>[];
      final transactions = await WebStorageService.getTransactions();
      
      // Compare with similar transactions
      final similarTransactions = transactions.where((t) => 
        t.categoryId == transaction.categoryId && 
        t.id != transaction.id
      ).toList();

      if (similarTransactions.isNotEmpty) {
        final avgAmount = similarTransactions.map((t) => t.amount).reduce((a, b) => a + b) / similarTransactions.length;
        
        if (transaction.amount > avgAmount * 1.5) {
          insights.add('This transaction is significantly higher than your usual ${transaction.categoryId} spending');
        } else if (transaction.amount < avgAmount * 0.5) {
          insights.add('This is a relatively small ${transaction.categoryId} expense for you');
        }
      }

      // Time-based insights
      final hour = transaction.date.hour;
      if (hour < 6) {
        insights.add('Late night transaction - consider if this was necessary');
      } else if (hour > 22) {
        insights.add('Evening transaction - review your spending patterns');
      }

      return insights;
    } catch (e) {
      print('Error generating transaction insights: $e');
      return [];
    }
  }

  // Predict next period spending
  static Future<Map<String, double>> predictNextPeriodSpending() async {
    try {
      final transactions = await WebStorageService.getTransactions();
      final now = DateTime.now();
      final lastMonth = transactions.where((t) => 
        now.difference(t.date).inDays <= 30 && 
        t.type == TransactionType.expense
      ).toList();

      final categorySpending = <String, double>{};
      for (var transaction in lastMonth) {
        categorySpending[transaction.categoryId] = 
            (categorySpending[transaction.categoryId] ?? 0) + transaction.amount;
      }

      // Simple prediction: assume similar spending pattern
      return categorySpending.map((key, value) => MapEntry(key, value * 1.05)); // 5% increase
    } catch (e) {
      print('Error predicting next period spending: $e');
      return {};
    }
  }

  // Generate budget recommendations
  static Future<Map<String, double>> generateBudgetRecommendations() async {
    try {
      final transactions = await WebStorageService.getTransactions();
      final now = DateTime.now();
      final lastThreeMonths = transactions.where((t) => 
        now.difference(t.date).inDays <= 90 && 
        t.type == TransactionType.expense
      ).toList();

      final categorySpending = <String, double>{};
      for (var transaction in lastThreeMonths) {
        categorySpending[transaction.categoryId] = 
            (categorySpending[transaction.categoryId] ?? 0) + transaction.amount;
      }

      // Recommend 10% reduction in highest spending categories
      return categorySpending.map((key, value) => 
        MapEntry(key, (value / 3) * 0.9) // Monthly average with 10% reduction
      );
    } catch (e) {
      print('Error generating budget recommendations: $e');
      return {};
    }
  }

  // Calculate financial health score
  static Future<double> calculateFinancialHealthScore() async {
    try {
      final transactions = await WebStorageService.getTransactions();
      final now = DateTime.now();
      final lastMonth = transactions.where((t) => 
        now.difference(t.date).inDays <= 30
      ).toList();

      final income = lastMonth.where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);
      final expenses = lastMonth.where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);

      if (income <= 0) return 0.0;

      final savingsRate = (income - expenses) / income;
      return (savingsRate * 100).clamp(0.0, 100.0);
    } catch (e) {
      print('Error calculating financial health score: $e');
      return 0.0;
    }
  }

  // Generate category insights
  static Future<Map<String, dynamic>> generateCategoryInsights() async {
    try {
      final transactions = await WebStorageService.getTransactions();
      final now = DateTime.now();
      final lastMonth = transactions.where((t) => 
        now.difference(t.date).inDays <= 30 && 
        t.type == TransactionType.expense
      ).toList();

      final categoryData = <String, Map<String, dynamic>>{};
      
      for (var transaction in lastMonth) {
        if (!categoryData.containsKey(transaction.categoryId)) {
          categoryData[transaction.categoryId] = {
            'total': 0.0,
            'count': 0,
            'average': 0.0,
          };
        }
        
        categoryData[transaction.categoryId]!['total'] = 
            (categoryData[transaction.categoryId]!['total'] as double) + transaction.amount;
        categoryData[transaction.categoryId]!['count'] = 
            (categoryData[transaction.categoryId]!['count'] as int) + 1;
      }

      // Calculate averages
      for (var entry in categoryData.entries) {
        final total = entry.value['total'] as double;
        final count = entry.value['count'] as int;
        entry.value['average'] = count > 0 ? total / count : 0.0;
      }

      return categoryData;
    } catch (e) {
      print('Error generating category insights: $e');
      return {};
    }
  }

  // Data persistence methods
  static Future<List<AnomalyAlert>> getAnomalyAlerts() async {
    try {
      final data = await WebStorageService.getList(_anomalyAlertsKey);
      return data.map((item) => AnomalyAlert.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  // Add missing loadAnomalyAlerts method
  static Future<List<AnomalyAlert>> loadAnomalyAlerts() async {
    return await getAnomalyAlerts();
  }

  static Future<void> _saveAnomalyAlerts(List<AnomalyAlert> alerts) async {
    try {
      final data = alerts.map((alert) => alert.toJson()).toList();
      await WebStorageService.saveList(_anomalyAlertsKey, data);
    } catch (e) {
      print('Error saving anomaly alerts: $e');
    }
  }

  static Future<CashflowForecast?> getCashflowForecast() async {
    try {
      final data = await WebStorageService.getMap(_cashflowForecastKey);
      return data != null ? CashflowForecast.fromJson(data) : null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> _saveCashflowForecast(CashflowForecast forecast) async {
    try {
      await WebStorageService.saveMap(_cashflowForecastKey, forecast.toJson());
    } catch (e) {
      print('Error saving cashflow forecast: $e');
    }
  }

  static Future<List<PersonalizedAdvice>> getPersonalizedAdvice() async {
    try {
      final data = await WebStorageService.getList(_personalizedAdviceKey);
      return data.map((item) => PersonalizedAdvice.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  // Add missing loadPersonalizedAdvice method
  static Future<List<PersonalizedAdvice>> loadPersonalizedAdvice() async {
    return await getPersonalizedAdvice();
  }

  static Future<void> _savePersonalizedAdvice(List<PersonalizedAdvice> advice) async {
    try {
      final data = advice.map((item) => item.toJson()).toList();
      await WebStorageService.saveList(_personalizedAdviceKey, data);
    } catch (e) {
      print('Error saving personalized advice: $e');
    }
  }

  static Future<List<UserPattern>> getUserPatterns() async {
    try {
      final data = await WebStorageService.getList(_userPatternsKey);
      return data.map((item) => UserPattern.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveUserPatterns(List<UserPattern> patterns) async {
    try {
      final data = patterns.map((pattern) => pattern.toJson()).toList();
      await WebStorageService.saveList(_userPatternsKey, data);
    } catch (e) {
      print('Error saving user patterns: $e');
    }
  }

  static Future<Map<String, double>> getAnomalyThresholds() async {
    try {
      final data = await WebStorageService.getMap(_anomalyThresholdsKey);
      return data?.cast<String, double>() ?? {};
    } catch (e) {
      return {};
    }
  }

  static Future<void> saveAnomalyThresholds(Map<String, double> thresholds) async {
    try {
      await WebStorageService.saveMap(_anomalyThresholdsKey, thresholds);
    } catch (e) {
      print('Error saving anomaly thresholds: $e');
    }
  }

  static Future<Map<String, double>> getPredictionAccuracy() async {
    try {
      final data = await WebStorageService.getMap(_predictionAccuracyKey);
      return data?.cast<String, double>() ?? {};
    } catch (e) {
      return {};
    }
  }

  static Future<void> savePredictionAccuracy(Map<String, double> accuracy) async {
    try {
      await WebStorageService.saveMap(_predictionAccuracyKey, accuracy);
    } catch (e) {
      print('Error saving prediction accuracy: $e');
    }
  }
}