import 'package:flutter/material.dart';

/// Simple notification service to handle budget updates when transactions change
class BudgetNotificationService {
  static final List<VoidCallback> _budgetUpdateCallbacks = [];
  
  /// Register a callback to be called when budgets need to be refreshed
  static void addBudgetUpdateListener(VoidCallback callback) {
    _budgetUpdateCallbacks.add(callback);
    print('📋 Budget listener registered. Total listeners: ${_budgetUpdateCallbacks.length}');
  }
  
  /// Remove a callback
  static void removeBudgetUpdateListener(VoidCallback callback) {
    _budgetUpdateCallbacks.remove(callback);
    print('📋 Budget listener removed. Total listeners: ${_budgetUpdateCallbacks.length}');
  }
  
  /// Notify all listeners that budgets should be refreshed
  static void notifyBudgetUpdate() {
    print('🔄 Notifying ${_budgetUpdateCallbacks.length} budget listeners to refresh');
    for (final callback in _budgetUpdateCallbacks) {
      try {
        callback();
      } catch (e) {
        print('❌ Error calling budget update callback: $e');
      }
    }
  }
  
  /// Clear all listeners (useful for testing or cleanup)
  static void clearAllListeners() {
    _budgetUpdateCallbacks.clear();
    print('🧹 All budget listeners cleared');
  }
}