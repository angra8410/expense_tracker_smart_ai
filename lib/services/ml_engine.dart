import 'dart:math';
import '../models/transaction.dart';
import '../models/ml_models.dart';

class MLEngine {
  static const String _userPatternsKey = 'user_patterns';
  
  static Future<List<AnomalyAlert>> detectAnomalies(List<Transaction> transactions) async {
    if (transactions.isEmpty) return [];

    final alerts = <AnomalyAlert>[];
    
    // Group transactions by category
    final categoryTransactions = <String, List<Transaction>>{};
    for (var transaction in transactions) {
      if (!categoryTransactions.containsKey(transaction.categoryId)) {
        categoryTransactions[transaction.categoryId] = [];
      }
      categoryTransactions[transaction.categoryId]!.add(transaction);
    }

    // Check each category for anomalies
    for (var entry in categoryTransactions.entries) {
      final categoryId = entry.key;
      final categoryTxns = entry.value;
      
      if (categoryTxns.length < 5) continue; // Need enough data
      
      final amounts = categoryTxns.map((t) => t.amount).toList();
      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final variance = amounts.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / amounts.length;
      final stdDev = sqrt(variance);
      
      // Check for outliers (transactions > 2 standard deviations from mean)
      for (var transaction in categoryTxns) {
        final zScore = (transaction.amount - mean) / stdDev;
        if (zScore.abs() > 2.0) {
          alerts.add(AnomalyAlert(
            type: transaction.amount > mean ? AnomalyType.unusuallyHigh : AnomalyType.unusuallyLow,
            transaction: transaction,
            expectedRange: '${(mean - 2 * stdDev).toStringAsFixed(2)} - ${(mean + 2 * stdDev).toStringAsFixed(2)}',
            severity: zScore.abs() > 3.0 ? AnomalySeverity.high : AnomalySeverity.medium,
            confidence: min(1.0, zScore.abs() / 3.0),
          ));
        }
      }
    }

    return alerts;
  }

  static Future<CashflowForecast> generateCashflowForecast(List<Transaction> transactions) async {
    if (transactions.isEmpty) {
      return CashflowForecast(
        currentBalance: 0.0,
        predictions: [],
        riskLevel: RiskLevel.low,
        recommendations: ['Add more transaction data for better predictions'],
      );
    }

    final now = DateTime.now();
    final predictions = <CashflowPrediction>[];
    
    // Calculate current balance
    double currentBalance = 0.0;
    for (var transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        currentBalance += transaction.amount;
      } else {
        currentBalance -= transaction.amount;
      }
    }

    // Generate predictions for next 30 days
    for (int i = 1; i <= 30; i++) {
      final futureDate = now.add(Duration(days: i));
      
      // Simple prediction based on historical averages
      final recentTransactions = transactions.where((t) => 
        now.difference(t.date).inDays <= 30).toList();
      
      double avgDailyIncome = 0.0;
      double avgDailyExpenses = 0.0;
      
      if (recentTransactions.isNotEmpty) {
        final incomeTransactions = recentTransactions.where((t) => t.type == TransactionType.income);
        final expenseTransactions = recentTransactions.where((t) => t.type == TransactionType.expense);
        
        if (incomeTransactions.isNotEmpty) {
          avgDailyIncome = incomeTransactions.map((t) => t.amount).reduce((a, b) => a + b) / 30;
        }
        
        if (expenseTransactions.isNotEmpty) {
          avgDailyExpenses = expenseTransactions.map((t) => t.amount).reduce((a, b) => a + b) / 30;
        }
      }
      
      final predictedBalance = currentBalance + (avgDailyIncome - avgDailyExpenses) * i;
      
      predictions.add(CashflowPrediction(
        date: futureDate,
        predictedIncome: avgDailyIncome,
        predictedExpenses: avgDailyExpenses,
        predictedBalance: predictedBalance,
        confidence: max(0.1, 1.0 - (i / 30) * 0.5), // Confidence decreases over time
      ));
    }

    // Determine risk level
    final finalBalance = predictions.isNotEmpty ? predictions.last.predictedBalance : currentBalance;
    RiskLevel riskLevel;
    if (finalBalance < 0) {
      riskLevel = RiskLevel.high;
    } else if (finalBalance < currentBalance * 0.5) {
      riskLevel = RiskLevel.medium;
    } else {
      riskLevel = RiskLevel.low;
    }

    // Generate recommendations
    final recommendations = <String>[];
    if (riskLevel == RiskLevel.high) {
      recommendations.add('Consider reducing expenses or increasing income');
      recommendations.add('Review your largest expense categories');
    } else if (riskLevel == RiskLevel.medium) {
      recommendations.add('Monitor your spending closely');
      recommendations.add('Consider building an emergency fund');
    } else {
      recommendations.add('Your finances look stable');
      recommendations.add('Consider investing surplus funds');
    }

    return CashflowForecast(
      currentBalance: currentBalance,
      predictions: predictions,
      riskLevel: riskLevel,
      recommendations: recommendations,
    );
  }

  // Add the missing forecastCashflow method (alias for generateCashflowForecast)
  static Future<CashflowForecast> forecastCashflow(List<Transaction> transactions) async {
    return generateCashflowForecast(transactions);
  }

  static Future<List<PersonalizedAdvice>> generatePersonalizedAdvice(List<Transaction> transactions) async {
    if (transactions.isEmpty) return [];

    final advice = <PersonalizedAdvice>[];
    
    // Analyze spending patterns
    final categorySpending = <String, double>{};
    double totalExpenses = 0.0;
    
    for (var transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        categorySpending[transaction.categoryId] = 
            (categorySpending[transaction.categoryId] ?? 0.0) + transaction.amount;
        totalExpenses += transaction.amount;
      }
    }

    // Find top spending categories
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Generate advice for top spending categories
    for (int i = 0; i < min(3, sortedCategories.length); i++) {
      final category = sortedCategories[i];
      final percentage = (category.value / totalExpenses) * 100;
      
      if (percentage > 20) { // If category is more than 20% of total spending
        advice.add(PersonalizedAdvice(
          title: 'High spending in ${category.key}',
          description: 'You\'re spending ${percentage.toStringAsFixed(1)}% of your budget on ${category.key}. Consider ways to reduce this.',
          actionItems: [
            'Review recent ${category.key} transactions',
            'Set a monthly limit for ${category.key}',
            'Look for alternatives or discounts'
          ],
          priority: percentage > 30 ? AdvicePriority.high : AdvicePriority.medium,
          confidence: 0.8,
          category: category.key,
        ));
      }
    }

    // Check for irregular spending patterns
    final recentTransactions = transactions.where((t) => 
      DateTime.now().difference(t.date).inDays <= 7).toList();
    
    if (recentTransactions.length > transactions.length * 0.3) {
      advice.add(PersonalizedAdvice(
        title: 'Increased spending activity',
        description: 'You\'ve had more transactions than usual this week.',
        actionItems: [
          'Review recent purchases',
          'Check if any were unnecessary',
          'Consider a spending pause'
        ],
        priority: AdvicePriority.medium,
        confidence: 0.7,
        category: 'general',
      ));
    }

    return advice;
  }

  // Add the missing predictCategory method
  static Future<String> predictCategory(String description, double amount) async {
    // Simple keyword-based category prediction
    final descriptionLower = description.toLowerCase();
    
    // Define category keywords
    final categoryKeywords = {
      'food': ['restaurant', 'food', 'grocery', 'cafe', 'pizza', 'burger', 'coffee', 'lunch', 'dinner', 'breakfast'],
      'transport': ['gas', 'fuel', 'uber', 'taxi', 'bus', 'train', 'parking', 'metro', 'transport'],
      'shopping': ['store', 'shop', 'mall', 'amazon', 'purchase', 'buy', 'clothing', 'shoes'],
      'entertainment': ['movie', 'cinema', 'game', 'music', 'concert', 'theater', 'netflix', 'spotify'],
      'utilities': ['electric', 'water', 'gas', 'internet', 'phone', 'utility', 'bill'],
      'healthcare': ['doctor', 'hospital', 'pharmacy', 'medical', 'health', 'clinic', 'medicine'],
      'education': ['school', 'university', 'course', 'book', 'education', 'tuition'],
    };

    // Find best matching category
    String bestCategory = 'other';
    int maxMatches = 0;

    for (var entry in categoryKeywords.entries) {
      int matches = 0;
      for (var keyword in entry.value) {
        if (descriptionLower.contains(keyword)) {
          matches++;
        }
      }
      if (matches > maxMatches) {
        maxMatches = matches;
        bestCategory = entry.key;
      }
    }

    return bestCategory;
  }

  // Add the missing learnFromTransaction method
  static Future<void> learnFromTransaction(Transaction transaction) async {
    try {
      // Update user patterns based on the transaction
      final patterns = await _loadUserPatterns();
      
      // Find existing pattern for this category or create new one
      final existingPatternIndex = patterns.indexWhere((p) => p.categoryId == transaction.categoryId);
      
      if (existingPatternIndex >= 0) {
        // Update existing pattern
        final existingPattern = patterns[existingPatternIndex];
        final newCount = existingPattern.transactionCount + 1;
        final newAverage = ((existingPattern.averageAmount * existingPattern.transactionCount) + transaction.amount) / newCount;
        
        // Extract keywords from transaction description
        final keywords = _extractKeywords(transaction.description);
        final updatedKeywords = List<String>.from(existingPattern.keywords);
        for (var keyword in keywords) {
          if (!updatedKeywords.contains(keyword)) {
            updatedKeywords.add(keyword);
          }
        }
        
        patterns[existingPatternIndex] = UserPattern(
          categoryId: existingPattern.categoryId,
          keywords: updatedKeywords,
          averageAmount: newAverage,
          transactionCount: newCount,
          confidence: min(1.0, newCount / 10.0), // Confidence increases with more data
        );
      } else {
        // Create new pattern
        patterns.add(UserPattern(
          categoryId: transaction.categoryId,
          keywords: _extractKeywords(transaction.description),
          averageAmount: transaction.amount,
          transactionCount: 1,
          confidence: 0.1, // Low confidence for new patterns
        ));
      }
      
      // Save updated patterns
      await _saveUserPatterns(patterns);
    } catch (e) {
      print('Error learning from transaction: $e');
    }
  }

  static List<String> _extractKeywords(String description) {
    // Simple keyword extraction - split by spaces and filter
    final words = description.toLowerCase().split(' ');
    return words.where((word) => word.length > 2).take(5).toList();
  }

  static Future<List<UserPattern>> _loadUserPatterns() async {
    try {
      // In a real app, this would load from SharedPreferences or a database
      // For now, return empty list
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> _saveUserPatterns(List<UserPattern> patterns) async {
    try {
      // In a real app, this would save to SharedPreferences or a database
      // For now, do nothing
    } catch (e) {
      print('Error saving user patterns: $e');
    }
  }
}

class UserBehaviorProfile {
  String userId;
  Map<String, double> categoryPreferences = {};
  Map<String, double> timeBasedPatterns = {};
  List<MapEntry<String, double>> topSpendingCategories = [];
  Map<String, int> spendingFrequency = {};
  Map<int, double> preferredSpendingHours = {};
  Map<int, double> preferredSpendingDays = {};
  double savingsRate = 0.0;
  double averageTransactionAmount = 0.0;

  UserBehaviorProfile({required this.userId});

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category_preferences': categoryPreferences,
      'time_based_patterns': timeBasedPatterns,
      'top_spending_categories': topSpendingCategories.map((e) => {'key': e.key, 'value': e.value}).toList(),
      'spending_frequency': spendingFrequency,
      'preferred_spending_hours': preferredSpendingHours.map((k, v) => MapEntry(k.toString(), v)),
      'preferred_spending_days': preferredSpendingDays.map((k, v) => MapEntry(k.toString(), v)),
      'savings_rate': savingsRate,
      'average_transaction_amount': averageTransactionAmount,
    };
  }

  factory UserBehaviorProfile.fromJson(Map<String, dynamic> json) {
    final profile = UserBehaviorProfile(userId: json['user_id'] ?? '');
    profile.categoryPreferences = Map<String, double>.from(json['category_preferences'] ?? {});
    profile.timeBasedPatterns = Map<String, double>.from(json['time_based_patterns'] ?? {});
    
    final topSpendingList = json['top_spending_categories'] as List? ?? [];
    profile.topSpendingCategories = topSpendingList
        .map((item) => MapEntry<String, double>(item['key'] ?? '', (item['value'] ?? 0.0).toDouble()))
        .toList();
    
    profile.spendingFrequency = Map<String, int>.from(json['spending_frequency'] ?? {});
    
    final preferredHours = json['preferred_spending_hours'] as Map<String, dynamic>? ?? {};
    profile.preferredSpendingHours = preferredHours.map((k, v) => MapEntry(int.parse(k), v.toDouble()));
    
    final preferredDays = json['preferred_spending_days'] as Map<String, dynamic>? ?? {};
    profile.preferredSpendingDays = preferredDays.map((k, v) => MapEntry(int.parse(k), v.toDouble()));
    
    profile.savingsRate = (json['savings_rate'] ?? 0.0).toDouble();
    profile.averageTransactionAmount = (json['average_transaction_amount'] ?? 0.0).toDouble();
    
    return profile;
  }
}