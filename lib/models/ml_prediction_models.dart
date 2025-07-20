class CategoryPredictionResult {
  final String categoryId;
  final double confidence;

  CategoryPredictionResult({
    required this.categoryId,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'confidence': confidence,
    };
  }

  factory CategoryPredictionResult.fromJson(Map<String, dynamic> json) {
    return CategoryPredictionResult(
      categoryId: json['categoryId'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}

class MLInsightsSummary {
  final int totalAnomalies;
  final int criticalAnomalies;
  final int totalAdvice;
  final int highPriorityAdviceCount;
  final double categoryPredictionAccuracy;
  final DateTime lastAnalysis;

  MLInsightsSummary({
    required this.totalAnomalies,
    required this.criticalAnomalies,
    required this.totalAdvice,
    required this.highPriorityAdviceCount,
    required this.categoryPredictionAccuracy,
    required this.lastAnalysis,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalAnomalies': totalAnomalies,
      'criticalAnomalies': criticalAnomalies,
      'totalAdvice': totalAdvice,
      'highPriorityAdviceCount': highPriorityAdviceCount,
      'categoryPredictionAccuracy': categoryPredictionAccuracy,
      'lastAnalysis': lastAnalysis.toIso8601String(),
    };
  }

  factory MLInsightsSummary.fromJson(Map<String, dynamic> json) {
    return MLInsightsSummary(
      totalAnomalies: json['totalAnomalies'] ?? 0,
      criticalAnomalies: json['criticalAnomalies'] ?? 0,
      totalAdvice: json['totalAdvice'] ?? 0,
      highPriorityAdviceCount: json['highPriorityAdviceCount'] ?? 0,
      categoryPredictionAccuracy: (json['categoryPredictionAccuracy'] ?? 0.0).toDouble(),
      lastAnalysis: json['lastAnalysis'] != null 
          ? DateTime.parse(json['lastAnalysis'])
          : DateTime.now(),
    );
  }
}