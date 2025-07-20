import 'dart:async';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/ml_models.dart';
import 'web_storage_service.dart';
import 'ml_engine.dart';

class SmartMLService {
  static Timer? _mlAnalysisTimer;
  static DateTime? _lastMLAnalysis;

  // Storage keys
  static const String _anomalyAlertsKey = 'smart_anomaly_alerts';
  static const String _personalizedAdviceKey = 'smart_personalized_advice';
  static const String _categoryPredictionsKey = 'smart_category_predictions';

  /// Initialize the Smart ML Service
  static Future<void> initialize() async {
    _startPeriodicMLAnalysis();
    await _ensureRecentMLAnalysis();
  }

  /// Dispose resources
  static void dispose() {
    _mlAnalysisTimer?.cancel();
  }

  /// 1. Smart Category Prediction
  static Future<String> predictCategory(
    String description,
    double amount,
    DateTime date,
  ) async {
    try {
      // Use ML Engine for prediction
      final predictedCategory = await MLEngine.predictCategory(description, amount);
      
      // Store prediction for learning
      await _storeCategoryPrediction(description, amount, date, predictedCategory);
      
      return predictedCategory;
    } catch (e) {
      print('Error predicting category: $e');
      final categories = await WebStorageService.getCategories();
      return categories.isNotEmpty ? categories.first.id : 'unknown';
    }
  }

  /// 2. Get Anomaly Alerts
  static Future<List<AnomalyAlert>> getAnomalyAlerts() async {
    await _ensureRecentMLAnalysis();
    return await _loadAnomalyAlerts();
  }

  /// 3. Get Cashflow Forecast
  static Future<CashflowForecast> getCashflowForecast(int daysAhead) async {
    try {
      final transactions = await WebStorageService.getTransactions();
      return await MLEngine.forecastCashflow(transactions);
    } catch (e) {
      print('Error generating cashflow forecast: $e');
      return CashflowForecast(
        currentBalance: 0.0,
        predictions: [],
        riskLevel: RiskLevel.low,
        recommendations: [],
      );
    }
  }

  /// 4. Get Personalized Financial Advice
  static Future<List<PersonalizedAdvice>> getPersonalizedAdvice() async {
    await _ensureRecentMLAnalysis();
    return await _loadPersonalizedAdvice();
  }

  /// Run comprehensive ML analysis
  static Future<void> runMLAnalysis() async {
    try {
      final transactions = await WebStorageService.getTransactions();
      final categories = await WebStorageService.getCategories();
      
      if (transactions.length < 10) {
        print('Insufficient data for ML analysis');
        return;
      }

      // 1. Detect anomalies
      final anomalies = await MLEngine.detectAnomalies(transactions);
      await _saveAnomalyAlerts(anomalies);

      // 2. Generate personalized advice
      final advice = await MLEngine.generatePersonalizedAdvice(transactions);
      await _savePersonalizedAdvice(advice);

      _lastMLAnalysis = DateTime.now();
      
      print('ML Analysis completed successfully');
    } catch (e) {
      print('Error running ML analysis: $e');
    }
  }

  /// Learn from user transaction
  static Future<void> learnFromTransaction(Transaction transaction) async {
    await MLEngine.learnFromTransaction(transaction);
  }

  /// Get category prediction accuracy
  static Future<double> getCategoryPredictionAccuracy() async {
    try {
      final predictions = await _loadCategoryPredictions();
      if (predictions.isEmpty) return 0.0;
      
      int correct = 0;
      for (var prediction in predictions) {
        if (prediction['actual_category'] == prediction['predicted_category']) {
          correct++;
        }
      }
      
      return correct / predictions.length;
    } catch (e) {
      return 0.0;
    }
  }

  /// Track category prediction accuracy
  static Future<void> trackCategoryPredictionAccuracy(
    String predictedCategory,
    String actualCategory,
  ) async {
    try {
      final predictions = await _loadCategoryPredictions();
      
      predictions.add({
        'predicted_category': predictedCategory,
        'actual_category': actualCategory,
        'timestamp': DateTime.now().toIso8601String(),
        'correct': predictedCategory == actualCategory,
      });
      
      // Keep only last 1000 predictions
      if (predictions.length > 1000) {
        predictions.removeRange(0, predictions.length - 1000);
      }
      
      await _saveCategoryPredictions(predictions);
    } catch (e) {
      print('Error tracking prediction accuracy: $e');
    }
  }

  // Private helper methods

  static void _startPeriodicMLAnalysis() {
    _mlAnalysisTimer = Timer.periodic(const Duration(hours: 6), (timer) {
      runMLAnalysis();
    });
  }

  static Future<void> _ensureRecentMLAnalysis() async {
    if (_lastMLAnalysis == null || 
        DateTime.now().difference(_lastMLAnalysis!).inHours > 6) {
      await runMLAnalysis();
    }
  }

  static Future<void> _storeCategoryPrediction(
    String description,
    double amount,
    DateTime date,
    String predictedCategory,
  ) async {
    try {
      final predictions = await _loadCategoryPredictions();
      
      predictions.add({
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'predicted_category': predictedCategory,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      await _saveCategoryPredictions(predictions);
    } catch (e) {
      print('Error storing category prediction: $e');
    }
  }

  // Storage methods
  static Future<List<AnomalyAlert>> _loadAnomalyAlerts() async {
    try {
      final jsonList = await WebStorageService.getList(_anomalyAlertsKey);
      return jsonList.map((json) => AnomalyAlert.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> _saveAnomalyAlerts(List<AnomalyAlert> alerts) async {
    final jsonList = alerts.map((alert) => alert.toJson()).toList();
    await WebStorageService.saveList(_anomalyAlertsKey, jsonList);
  }

  static Future<List<PersonalizedAdvice>> _loadPersonalizedAdvice() async {
    try {
      final jsonList = await WebStorageService.getList(_personalizedAdviceKey);
      return jsonList.map((json) => PersonalizedAdvice.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> _savePersonalizedAdvice(List<PersonalizedAdvice> advice) async {
    final jsonList = advice.map((item) => item.toJson()).toList();
    await WebStorageService.saveList(_personalizedAdviceKey, jsonList);
  }

  static Future<List<Map<String, dynamic>>> _loadCategoryPredictions() async {
    try {
      return await WebStorageService.getList(_categoryPredictionsKey);
    } catch (e) {
      return [];
    }
  }

  static Future<void> _saveCategoryPredictions(List<Map<String, dynamic>> predictions) async {
    await WebStorageService.saveList(_categoryPredictionsKey, predictions);
  }
}