enum BudgetPeriod {
  weekly,
  monthly,
  yearly,
}

enum BudgetStatus {
  onTrack,
  warning,
  exceeded,
}

class Budget {
  final String id;
  final String name;
  final double amount;
  final String categoryId;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime? createdAt;
  final bool rolloverEnabled;
  final double rolloverAmount;

  Budget({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.createdAt,
    this.rolloverEnabled = false,
    this.rolloverAmount = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category_id': categoryId,
      'period': period.toString().split('.').last,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'rollover_enabled': rolloverEnabled,
      'rollover_amount': rolloverAmount,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      categoryId: json['category_id'] ?? '',
      period: BudgetPeriod.values.firstWhere(
        (e) => e.toString().split('.').last == json['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date'])
          : DateTime.now().add(const Duration(days: 30)),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      rolloverEnabled: json['rollover_enabled'] ?? false,
      rolloverAmount: (json['rollover_amount'] ?? 0.0).toDouble(),
    );
  }

  Budget copyWith({
    String? id,
    String? name,
    double? amount,
    String? categoryId,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    bool? rolloverEnabled,
    double? rolloverAmount,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      rolloverEnabled: rolloverEnabled ?? this.rolloverEnabled,
      rolloverAmount: rolloverAmount ?? this.rolloverAmount,
    );
  }

  double get totalBudgetAmount => amount + rolloverAmount;

  @override
  String toString() {
    return 'Budget(id: $id, name: $name, amount: $amount, period: $period, rollover: $rolloverEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class BudgetProgress {
  final Budget budget;
  final double spent;
  final double remaining;
  final double percentage;
  final BudgetStatus status;
  final List<DailySpending> dailySpending;
  final DateTime lastUpdated;

  BudgetProgress({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.status,
    required this.dailySpending,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  bool get isOverBudget => spent > budget.amount;
  bool get isNearLimit => percentage >= 0.8 && percentage < 1.0;
  double get averageDailySpending {
    if (dailySpending.isEmpty) return 0.0;
    return dailySpending.map((d) => d.amount).reduce((a, b) => a + b) / dailySpending.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'budget': budget.toJson(),
      'spent': spent,
      'remaining': remaining,
      'percentage': percentage,
      'status': status.toString().split('.').last,
      'daily_spending': dailySpending.map((d) => d.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory BudgetProgress.fromJson(Map<String, dynamic> json) {
    return BudgetProgress(
      budget: Budget.fromJson(json['budget'] ?? {}),
      spent: (json['spent'] ?? 0.0).toDouble(),
      remaining: (json['remaining'] ?? 0.0).toDouble(),
      percentage: (json['percentage'] ?? 0.0).toDouble(),
      status: BudgetStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => BudgetStatus.onTrack,
      ),
      dailySpending: (json['daily_spending'] as List<dynamic>?)
          ?.map((d) => DailySpending.fromJson(d))
          .toList() ?? [],
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated'])
          : DateTime.now(),
    );
  }
}

class DailySpending {
  final DateTime date;
  final double amount;
  final int transactionCount;

  DailySpending({
    required this.date,
    required this.amount,
    required this.transactionCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'amount': amount,
      'transaction_count': transactionCount,
    };
  }

  factory DailySpending.fromJson(Map<String, dynamic> json) {
    return DailySpending(
      date: json['date'] != null 
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      amount: (json['amount'] ?? 0.0).toDouble(),
      transactionCount: json['transaction_count'] ?? 0,
    );
  }
}

class BudgetRecommendation {
  final String id;
  final String title;
  final String description;
  final double suggestedAmount;
  final String categoryId;
  final BudgetPeriod suggestedPeriod;
  final double confidence;
  final String reasoning;
  final DateTime createdAt;

  BudgetRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.suggestedAmount,
    required this.categoryId,
    required this.suggestedPeriod,
    required this.confidence,
    required this.reasoning,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'suggested_amount': suggestedAmount,
      'category_id': categoryId,
      'suggested_period': suggestedPeriod.toString().split('.').last,
      'confidence': confidence,
      'reasoning': reasoning,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BudgetRecommendation.fromJson(Map<String, dynamic> json) {
    return BudgetRecommendation(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      suggestedAmount: (json['suggested_amount'] ?? 0.0).toDouble(),
      categoryId: json['category_id'] ?? '',
      suggestedPeriod: BudgetPeriod.values.firstWhere(
        (e) => e.toString().split('.').last == json['suggested_period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      reasoning: json['reasoning'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}