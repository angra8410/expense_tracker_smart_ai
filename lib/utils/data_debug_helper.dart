import '../services/web_storage_service.dart';
import '../services/budget_service.dart';
import '../models/transaction.dart';
import '../models/budget.dart';

class DataDebugHelper {
  static Future<void> debugTransactionBudgetMismatch() async {
    try {
      // Get all transactions
      final transactions = await WebStorageService.getTransactions();
      print('🔍 DEBUG: Found ${transactions.length} transactions');
      
      // Get all budgets
      final budgets = await BudgetService.getActiveBudgets();
      print('📊 DEBUG: Found ${budgets.length} active budgets');
      
      // Print all transactions
      print('\n📝 ALL TRANSACTIONS:');
      for (final transaction in transactions) {
        print('  ID: ${transaction.id}');
        print('  Description: ${transaction.description}');
        print('  Amount: ${transaction.amount}');
        print('  Category ID: ${transaction.categoryId}');
        print('  Date: ${transaction.date}');
        print('  Type: ${transaction.type}');
        print('  Created At: ${transaction.createdAt}');
        print('  ---');
      }
      
      // Print all budgets
      print('\n💰 ALL BUDGETS:');
      for (final budget in budgets) {
        print('  ID: ${budget.id}');
        print('  Name: ${budget.name}');
        print('  Amount: ${budget.amount}');
        print('  Category ID: ${budget.categoryId}');
        print('  Period: ${budget.period}');
        print('  Start Date: ${budget.startDate}');
        print('  End Date: ${budget.endDate}');
        print('  Active: ${budget.isActive}');
        print('  Created At: ${budget.createdAt}');
        print('  ---');
      }
      
      // Check for matches
      print('\n🔍 CHECKING MATCHES:');
      for (final budget in budgets) {
        print('Budget: ${budget.name} (${budget.categoryId})');
        final matchingTransactions = transactions.where((transaction) {
          final categoryMatch = transaction.categoryId == budget.categoryId;
          final typeMatch = transaction.type == TransactionType.expense;
          final dateAfterStart = transaction.date.isAfter(budget.startDate) || transaction.date.isAtSameMomentAs(budget.startDate);
          final dateBeforeEnd = transaction.date.isBefore(budget.endDate) || transaction.date.isAtSameMomentAs(budget.endDate);
          
          return categoryMatch && typeMatch && dateAfterStart && dateBeforeEnd;
        }).toList();
        
        print('  Matching transactions: ${matchingTransactions.length}');
        for (final tx in matchingTransactions) {
          print('    ✓ ${tx.description}: ${tx.amount}');
        }
      }
      
    } catch (e) {
      print('❌ Error in debug: $e');
    }
  }

  static Future<void> fixCategoryIdMismatch() async {
    try {
      final transactions = await WebStorageService.getTransactions();
      bool hasChanges = false;
      
      for (final transaction in transactions) {
        String? newCategoryId;
        
        // Check for common mismatches
        if (transaction.categoryId == 'comida' || transaction.categoryId == 'food_dining') {
          newCategoryId = 'food';
        }
        // Add more category fixes as needed
        
        if (newCategoryId != null && newCategoryId != transaction.categoryId) {
          print('🔧 Fixing transaction "${transaction.description}" category from "${transaction.categoryId}" to "$newCategoryId"');
          
          final updatedTransaction = Transaction(
            id: transaction.id,
            description: transaction.description,
            amount: transaction.amount,
            categoryId: newCategoryId,
            date: transaction.date,
            type: transaction.type,
            accountId: transaction.accountId, // Include the accountId
            createdAt: transaction.createdAt,
          );
          
          // Update the transaction
          final allTransactions = await WebStorageService.getTransactions();
          final index = allTransactions.indexWhere((t) => t.id == transaction.id);
          if (index != -1) {
            allTransactions[index] = updatedTransaction;
            await WebStorageService.saveTransactions(allTransactions);
            hasChanges = true;
          }
        }
      }
      
      if (hasChanges) {
        print('✅ Category IDs fixed successfully!');
      } else {
        print('ℹ️ No category ID mismatches found.');
      }
    } catch (e) {
      print('❌ Error fixing category IDs: $e');
    }
  }

  // Fix budget start dates to begin at start of day
  static Future<void> fixBudgetStartDates() async {
    try {
      print('🔧 Starting budget start date fix...');
      final budgets = await BudgetService.getActiveBudgets();
      print('📊 Found ${budgets.length} budgets to check');
      
      bool hasChanges = false;
      
      for (final budget in budgets) {
        print('\n🔍 Checking budget: ${budget.name}');
        print('  Current start date: ${budget.startDate}');
        print('  Current end date: ${budget.endDate}');
        
        final startOfDay = DateTime(
          budget.startDate.year, 
          budget.startDate.month, 
          budget.startDate.day
        );
        
        print('  Calculated start of day: $startOfDay');
        print('  Needs fixing: ${budget.startDate != startOfDay}');
        
        // Only update if the start date is not at the beginning of the day
        if (budget.startDate != startOfDay) {
          print('🔧 Fixing budget "${budget.name}" start date from ${budget.startDate} to $startOfDay');
          
          // Calculate new end date based on the corrected start date
          final newEndDate = _calculateEndDate(startOfDay, budget.period);
          print('  New end date: $newEndDate');
          
          final updatedBudget = budget.copyWith(
            startDate: startOfDay,
            endDate: newEndDate,
          );
          
          print('  Calling BudgetService.updateBudget...');
          await BudgetService.updateBudget(updatedBudget);
          print('  ✅ Budget updated successfully');
          hasChanges = true;
        } else {
          print('  ℹ️ Budget already has correct start date');
        }
      }
      
      if (hasChanges) {
        print('\n✅ Budget start dates fixed successfully!');
        print('🔄 Please refresh the budget screen to see changes');
      } else {
        print('\nℹ️ No budget start dates needed fixing.');
      }
    } catch (e) {
      print('❌ Error fixing budget start dates: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }
  
  // Helper method to calculate end date
  static DateTime _calculateEndDate(DateTime startDate, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return startDate.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case BudgetPeriod.yearly:
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
    }
  }

  // Recreate test data including transactions and budget
  static Future<void> recreateTestData() async {
    try {
      print('🔄 Recreating test data...');
      
      // Create the 120,000 COP transaction that was missing
      final transaction120k = Transaction(
        id: 'tx_120k_${DateTime.now().millisecondsSinceEpoch}',
        description: 'comida',
        amount: 120000.0,
        categoryId: 'food',
        date: DateTime(2025, 7, 19, 7, 22, 7, 519), // Original date from debug
        type: TransactionType.expense,
        accountId: 'default_account',
        createdAt: DateTime(2025, 7, 19, 7, 22, 7, 519),
      );
      
      // Create the 100,000 COP transaction
      final transaction100k = Transaction(
        id: 'tx_100k_${DateTime.now().millisecondsSinceEpoch}',
        description: 'comida',
        amount: 100000.0,
        categoryId: 'food',
        date: DateTime(2025, 7, 19, 7, 35, 40, 819), // Original date from debug
        type: TransactionType.expense,
        accountId: 'default_account',
        createdAt: DateTime(2025, 7, 19, 7, 35, 40, 819),
      );
      
      // Save transactions
      final transactions = [transaction120k, transaction100k];
      await WebStorageService.saveTransactions(transactions);
      print('✅ Created ${transactions.length} transactions');
      
      // Create budget with start date at beginning of day
      final budgetStartDate = DateTime(2025, 7, 19); // Start of day
      final budgetEndDate = DateTime(2025, 8, 19); // One month later
      
      final budget = Budget(
        id: 'budget_food_${DateTime.now().millisecondsSinceEpoch}',
        name: 'comida',
        amount: 1100000.0,
        categoryId: 'food',
        period: BudgetPeriod.monthly,
        startDate: budgetStartDate,
        endDate: budgetEndDate,
        isActive: true,
        createdAt: DateTime.now(),
      );
      
      // Save budget using BudgetService
      await BudgetService.updateBudget(budget);
      print('✅ Created budget: ${budget.name} (${budget.amount} COP)');
      print('   Start: ${budget.startDate}');
      print('   End: ${budget.endDate}');
      
      print('\n🎉 Test data recreated successfully!');
      print('📊 The budget should now show 220,000 COP spent (120k + 100k)');
      print('🔄 Please refresh the budget screen to see the changes');
      
    } catch (e) {
      print('❌ Error recreating test data: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }
}