import '../models/transaction.dart';

// User Pattern Learning Model
class UserPattern {
  final String categoryId;
  final List<String> keywords;
  final double averageAmount;
  final int transactionCount;
  final double confidence;

  UserPattern({
    required this.categoryId,
    required this.keywords,
    required this.averageAmount,
    required this.transactionCount,
    required this.confidence,
  });

  UserPattern copyWith({
    String? categoryId,
    List<String>? keywords,
    double? averageAmount,
    int? transactionCount,
    double? confidence,
  }) {
    return UserPattern(
      categoryId: categoryId ?? this.categoryId,
      keywords: keywords ?? this.keywords,
      averageAmount: averageAmount ?? this.averageAmount,
      transactionCount: transactionCount ?? this.transactionCount,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'keywords': keywords,
      'average_amount': averageAmount,
      'transaction_count': transactionCount,
      'confidence': confidence,
    };
  }

  factory UserPattern.fromJson(Map<String, dynamic> json) {
    return UserPattern(
      categoryId: json['category_id'] ?? '',
      keywords: List<String>.from(json['keywords'] ?? []),
      averageAmount: (json['average_amount'] ?? 0.0).toDouble(),
      transactionCount: json['transaction_count'] ?? 0,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}

// Anomaly Detection Models
enum AnomalyType {
  unusuallyHigh,
  unusuallyLow,
  frequencyAnomaly,
  timingAnomaly,
}

enum AnomalySeverity {
  low,
  medium,
  high,
  critical,
}

class AnomalyAlert {
  final AnomalyType type;
  final Transaction transaction;
  final String expectedRange;
  final AnomalySeverity severity;
  final double confidence;
  final DateTime detectedAt;

  AnomalyAlert({
    required this.type,
    required this.transaction,
    required this.expectedRange,
    required this.severity,
    required this.confidence,
    DateTime? detectedAt,
  }) : detectedAt = detectedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'transaction': transaction.toJson(),
      'expected_range': expectedRange,
      'severity': severity.toString().split('.').last,
      'confidence': confidence,
      'detected_at': detectedAt.toIso8601String(),
    };
  }

  factory AnomalyAlert.fromJson(Map<String, dynamic> json) {
    return AnomalyAlert(
      type: AnomalyType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => AnomalyType.unusuallyHigh,
      ),
      transaction: Transaction.fromJson(json['transaction']),
      expectedRange: json['expected_range'] ?? '',
      severity: AnomalySeverity.values.firstWhere(
        (e) => e.toString().split('.').last == json['severity'],
        orElse: () => AnomalySeverity.low,
      ),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      detectedAt: json['detected_at'] != null 
          ? DateTime.parse(json['detected_at'])
          : DateTime.now(),
    );
  }
}

class AnomalyThreshold {
  final String categoryId;
  final double mean;
  final double standardDeviation;
  final double upperBound;
  final double lowerBound;

  AnomalyThreshold({
    required this.categoryId,
    required this.mean,
    required this.standardDeviation,
    required this.upperBound,
    required this.lowerBound,
  });

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'mean': mean,
      'standard_deviation': standardDeviation,
      'upper_bound': upperBound,
      'lower_bound': lowerBound,
    };
  }

  factory AnomalyThreshold.fromJson(Map<String, dynamic> json) {
    return AnomalyThreshold(
      categoryId: json['category_id'] ?? '',
      mean: (json['mean'] ?? 0.0).toDouble(),
      standardDeviation: (json['standard_deviation'] ?? 0.0).toDouble(),
      upperBound: (json['upper_bound'] ?? 0.0).toDouble(),
      lowerBound: (json['lower_bound'] ?? 0.0).toDouble(),
    );
  }
}

// Cashflow Forecasting Models
enum RiskLevel {
  low,
  medium,
  high,
}

class CashflowPrediction {
  final DateTime date;
  final double predictedIncome;
  final double predictedExpenses;
  final double predictedBalance;
  final double confidence;

  CashflowPrediction({
    required this.date,
    required this.predictedIncome,
    required this.predictedExpenses,
    required this.predictedBalance,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'predicted_income': predictedIncome,
      'predicted_expenses': predictedExpenses,
      'predicted_balance': predictedBalance,
      'confidence': confidence,
    };
  }

  factory CashflowPrediction.fromJson(Map<String, dynamic> json) {
    return CashflowPrediction(
      date: DateTime.parse(json['date']),
      predictedIncome: (json['predicted_income'] ?? 0.0).toDouble(),
      predictedExpenses: (json['predicted_expenses'] ?? 0.0).toDouble(),
      predictedBalance: (json['predicted_balance'] ?? 0.0).toDouble(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}

class CashflowForecast {
  final double currentBalance;
  final List<CashflowPrediction> predictions;
  final RiskLevel riskLevel;
  final List<String> recommendations;

  CashflowForecast({
    required this.currentBalance,
    required this.predictions,
    required this.riskLevel,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_balance': currentBalance,
      'predictions': predictions.map((p) => p.toJson()).toList(),
      'risk_level': riskLevel.toString().split('.').last,
      'recommendations': recommendations,
    };
  }

  factory CashflowForecast.fromJson(Map<String, dynamic> json) {
    return CashflowForecast(
      currentBalance: (json['current_balance'] ?? 0.0).toDouble(),
      predictions: (json['predictions'] as List)
          .map((p) => CashflowPrediction.fromJson(p))
          .toList(),
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['risk_level'],
        orElse: () => RiskLevel.low,
      ),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
}

class TimeSeriesModel {
  final double averageAmount;
  final double trend;
  final Map<int, double> seasonality; // Day of week patterns
  final double confidence;

  TimeSeriesModel({
    required this.averageAmount,
    required this.trend,
    required this.seasonality,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'average_amount': averageAmount,
      'trend': trend,
      'seasonality': seasonality.map((k, v) => MapEntry(k.toString(), v)),
      'confidence': confidence,
    };
  }

  factory TimeSeriesModel.fromJson(Map<String, dynamic> json) {
    return TimeSeriesModel(
      averageAmount: (json['average_amount'] ?? 0.0).toDouble(),
      trend: (json['trend'] ?? 0.0).toDouble(),
      seasonality: (json['seasonality'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(int.parse(k), v.toDouble())) ?? {},
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}

// Alias for TimeSeriesModel for cashflow modeling
typedef CashflowModel = TimeSeriesModel;

// Personalized Advice Models
enum AdvicePriority {
  low,
  medium,
  high,
  critical,
}

class PersonalizedAdvice {
  final String title;
  final String description;
  final List<String> actionItems;
  final AdvicePriority priority;
  final double confidence;
  final String category;
  final DateTime createdAt;

  PersonalizedAdvice({
    required this.title,
    required this.description,
    required this.actionItems,
    required this.priority,
    required this.confidence,
    required this.category,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'action_items': actionItems,
      'priority': priority.toString().split('.').last,
      'confidence': confidence,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PersonalizedAdvice.fromJson(Map<String, dynamic> json) {
    return PersonalizedAdvice(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      actionItems: List<String>.from(json['action_items'] ?? []),
      priority: AdvicePriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => AdvicePriority.low,
      ),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

// Helper Models
class StatisticalData {
  final double mean;
  final double standardDeviation;
  final double median;
  final double variance;

  StatisticalData(this.mean, this.standardDeviation, this.median, this.variance);
}

class SpendingBehaviorAnalysis {
  final Map<int, double> weekdaySpending; // 1-7 (Monday-Sunday)
  final Map<int, double> monthlySpending; // 1-12
  final Map<String, double> categorySpending;
  final double averageTransactionAmount;
  final int spendingFrequency;

  SpendingBehaviorAnalysis({
    required this.weekdaySpending,
    required this.monthlySpending,
    required this.categorySpending,
    required this.averageTransactionAmount,
    required this.spendingFrequency,
  });
}