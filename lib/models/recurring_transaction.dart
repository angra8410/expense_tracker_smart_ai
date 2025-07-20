import 'package:uuid/uuid.dart';

enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}

class RecurringTransaction {
  final String id;
  final String description;
  final double amount;
  final String categoryId;
  final String type; // 'income' or 'expense'
  final String accountId;
  final RecurrenceFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? lastExecuted;
  final DateTime createdAt;
  final bool isActive;
  final int? dayOfMonth; // For monthly recurrence (1-31)
  final int? dayOfWeek; // For weekly recurrence (1-7, Monday=1)

  RecurringTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.categoryId,
    required this.type,
    required this.accountId,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.lastExecuted,
    required this.createdAt,
    this.isActive = true,
    this.dayOfMonth,
    this.dayOfWeek,
  });

  factory RecurringTransaction.create({
    required String description,
    required double amount,
    required String categoryId,
    required String type,
    required String accountId,
    required RecurrenceFrequency frequency,
    required DateTime startDate,
    DateTime? endDate,
    int? dayOfMonth,
    int? dayOfWeek,
  }) {
    return RecurringTransaction(
      id: const Uuid().v4(),
      description: description,
      amount: amount,
      categoryId: categoryId,
      type: type,
      accountId: accountId,
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
      dayOfMonth: dayOfMonth,
      dayOfWeek: dayOfWeek,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'categoryId': categoryId,
      'type': type,
      'accountId': accountId,
      'frequency': frequency.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'lastExecuted': lastExecuted?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'dayOfMonth': dayOfMonth,
      'dayOfWeek': dayOfWeek,
    };
  }

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      categoryId: json['categoryId'] ?? '',
      type: json['type'] ?? 'expense',
      accountId: json['accountId'] ?? 'personal',
      frequency: RecurrenceFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => RecurrenceFrequency.monthly,
      ),
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      lastExecuted: json['lastExecuted'] != null ? DateTime.parse(json['lastExecuted']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      dayOfMonth: json['dayOfMonth'],
      dayOfWeek: json['dayOfWeek'],
    );
  }

  RecurringTransaction copyWith({
    String? id,
    String? description,
    double? amount,
    String? categoryId,
    String? type,
    String? accountId,
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastExecuted,
    DateTime? createdAt,
    bool? isActive,
    int? dayOfMonth,
    int? dayOfWeek,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastExecuted: lastExecuted ?? this.lastExecuted,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    );
  }

  DateTime? getNextExecutionDate() {
    final baseDate = lastExecuted ?? startDate;
    
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return baseDate.add(const Duration(days: 1));
      
      case RecurrenceFrequency.weekly:
        return baseDate.add(const Duration(days: 7));
      
      case RecurrenceFrequency.monthly:
        final nextMonth = DateTime(baseDate.year, baseDate.month + 1, dayOfMonth ?? baseDate.day);
        // Handle cases where dayOfMonth doesn't exist in the next month
        if (dayOfMonth != null && dayOfMonth! > 28) {
          final lastDayOfMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
          if (dayOfMonth! > lastDayOfMonth) {
            return DateTime(nextMonth.year, nextMonth.month, lastDayOfMonth);
          }
        }
        return nextMonth;
      
      case RecurrenceFrequency.yearly:
        return DateTime(baseDate.year + 1, baseDate.month, baseDate.day);
    }
  }

  bool shouldExecuteToday() {
    if (!isActive) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check if we've already executed today
    if (lastExecuted != null) {
      final lastExecDate = DateTime(lastExecuted!.year, lastExecuted!.month, lastExecuted!.day);
      if (lastExecDate.isAtSameMomentAs(today) || lastExecDate.isAfter(today)) {
        return false;
      }
    }
    
    // Check if start date has passed
    final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
    if (today.isBefore(startDateOnly)) {
      return false;
    }
    
    // Check if end date has passed
    if (endDate != null) {
      final endDateOnly = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (today.isAfter(endDateOnly)) {
        return false;
      }
    }
    
    final nextExecution = getNextExecutionDate();
    if (nextExecution == null) return false;
    
    final nextExecDate = DateTime(nextExecution.year, nextExecution.month, nextExecution.day);
    return today.isAtSameMomentAs(nextExecDate) || today.isAfter(nextExecDate);
  }

  @override
  String toString() {
    return 'RecurringTransaction(id: $id, description: $description, amount: $amount, frequency: $frequency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecurringTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}