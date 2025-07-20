enum InsightType {
  recommendation,
  warning,
  achievement,
  anomaly,
  pattern,
  opportunity,
}

class FinancialInsight {
  final InsightType type;
  final String title;
  final String description;
  final double confidence; // 0.0 to 1.0
  final bool actionable;
  final String category;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  FinancialInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.confidence,
    required this.actionable,
    required this.category,
    DateTime? createdAt,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'confidence': confidence,
      'actionable': actionable,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory FinancialInsight.fromJson(Map<String, dynamic> json) {
    return FinancialInsight(
      type: InsightType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => InsightType.recommendation,
      ),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      actionable: json['actionable'] ?? false,
      category: json['category'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      metadata: json['metadata'],
    );
  }
}

class SpendingPrediction {
  final String categoryId;
  final double predictedAmount;
  final double confidence;
  final DateTime forDate;
  final String methodology;

  SpendingPrediction({
    required this.categoryId,
    required this.predictedAmount,
    required this.confidence,
    required this.forDate,
    required this.methodology,
  });

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'predicted_amount': predictedAmount,
      'confidence': confidence,
      'for_date': forDate.toIso8601String(),
      'methodology': methodology,
    };
  }

  factory SpendingPrediction.fromJson(Map<String, dynamic> json) {
    return SpendingPrediction(
      categoryId: json['category_id'] ?? '',
      predictedAmount: (json['predicted_amount'] ?? 0.0).toDouble(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      forDate: json['for_date'] != null 
          ? DateTime.parse(json['for_date'])
          : DateTime.now(),
      methodology: json['methodology'] ?? '',
    );
  }
}

class FinancialHealthMetrics {
  final double overallScore; // 0-100
  final double savingsRate;
  final double debtToIncomeRatio;
  final double expenseVariability;
  final int transactionConsistency;
  final Map<String, double> categoryScores;
  final DateTime calculatedAt;

  FinancialHealthMetrics({
    required this.overallScore,
    required this.savingsRate,
    required this.debtToIncomeRatio,
    required this.expenseVariability,
    required this.transactionConsistency,
    required this.categoryScores,
    DateTime? calculatedAt,
  }) : calculatedAt = calculatedAt ?? DateTime.now();

  String get healthLevel {
    if (overallScore >= 80) return 'Excellent';
    if (overallScore >= 60) return 'Good';
    if (overallScore >= 40) return 'Fair';
    return 'Needs Improvement';
  }

  Map<String, dynamic> toJson() {
    return {
      'overall_score': overallScore,
      'savings_rate': savingsRate,
      'debt_to_income_ratio': debtToIncomeRatio,
      'expense_variability': expenseVariability,
      'transaction_consistency': transactionConsistency,
      'category_scores': categoryScores,
      'calculated_at': calculatedAt.toIso8601String(),
    };
  }

  factory FinancialHealthMetrics.fromJson(Map<String, dynamic> json) {
    return FinancialHealthMetrics(
      overallScore: (json['overall_score'] ?? 0.0).toDouble(),
      savingsRate: (json['savings_rate'] ?? 0.0).toDouble(),
      debtToIncomeRatio: (json['debt_to_income_ratio'] ?? 0.0).toDouble(),
      expenseVariability: (json['expense_variability'] ?? 0.0).toDouble(),
      transactionConsistency: json['transaction_consistency'] ?? 0,
      categoryScores: Map<String, double>.from(json['category_scores'] ?? {}),
      calculatedAt: json['calculated_at'] != null 
          ? DateTime.parse(json['calculated_at'])
          : DateTime.now(),
    );
  }
}