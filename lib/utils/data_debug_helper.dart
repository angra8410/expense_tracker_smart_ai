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
      
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      
      // Create diverse sample transactions for the current month
      final sampleTransactions = [
        // Income transactions
        Transaction(
          id: 'tx_salary_${now.millisecondsSinceEpoch}',
          description: 'Monthly Salary',
          amount: 3000000.0, // 3M COP
          categoryId: 'salary',
          date: DateTime(now.year, now.month, 1, 9, 0), // First day of month
          type: TransactionType.income,
          accountId: 'default_account',
          createdAt: now,
        ),
        Transaction(
          id: 'tx_freelance_${now.millisecondsSinceEpoch + 1}',
          description: 'Freelance Project',
          amount: 800000.0, // 800K COP
          categoryId: 'other_income',
          date: DateTime(now.year, now.month, 15, 14, 30), // Mid month
          type: TransactionType.income,
          accountId: 'default_account',
          createdAt: now,
        ),
        
        // Food expenses
        Transaction(
          id: 'tx_food1_${now.millisecondsSinceEpoch + 2}',
          description: 'Grocery Shopping',
          amount: 120000.0,
          categoryId: 'food',
          date: DateTime(now.year, now.month, 3, 10, 30),
          type: TransactionType.expense,
          accountId: 'default_account',
          createdAt: now,
        ),
        Transaction(
          id: 'tx_food2_${now.millisecondsSinceEpoch + 3}',
          description: 'Restaurant Dinner',
          amount: 85000.0,
          categoryId: 'food',
          date: DateTime(now.year, now.month, 7, 19, 45),
          type: TransactionType.expense,
          accountId: 'default_account',
          createdAt: now,
        ),
        Transaction(
          id: 'tx_food3_${now.millisecondsSinceEpoch + 4}',
          description: 'Coffee Shop',
          amount: 25000.0,
          categoryId: 'food',
          date: DateTime(now.year, now.month, 12, 8, 15),
          type: TransactionType.expense,
          accountId: 'default_account',
          createdAt: now,
        ),
        
        // Transportation
        Transaction(
          id: 'tx_transport1_${now.millisecondsSinceEpoch + 5}',
          description: 'Gas Station',
          amount: 150000.0,
          categoryId: 'transportation',
          date: DateTime(now.year, now.month, 5, 16, 20),
          type: TransactionType.expense,
          accountId: 'default_account',
          createdAt: now,
        ),
        Transaction(
          id: 'tx_transport2_${now.millisecondsSinceEpoch + 6}',
          description: 'Uber Rides',
          amount: 45000.0,
          categoryId: 'transportation',
          date: DateTime(now.year, now.month, 10, 22, 30),
          type: TransactionType.expense,
          accountId: 'default_account',
          createdAt: now,
        ),
        
        // Entertainment
        Transaction(
          id: 'tx_entertainment1_${now.millisecondsSinceEpoch + 7}',
          description: 'Movie Theater',
          amount: 35000.0,
          categoryId: 'entertainment',
          date: DateTime(now.year, now.month, 8, 20, 0),
          type: TransactionType.expense,
          accountId: 'default_account',
          createdAt: now,
        ),
        Transaction(
          id: 'tx_entertainment2_${now.millisecondsSinceEpoch + 8}',
          description: 'Streaming Services',
          amount: 50000.0,
          categoryId: 'entertainment',
          date: DateTime(now.year, now.month, 1, 12, 0),
          type: TransactionType.expense,
          accountId: 'default_account',
          createdAt: now,
        ),
        
        // Shopping
        Transaction(
          id: 'tx_shopping1_${now.millisecondsSinceEpoch + 9}',
          description: 'Clothing Store',
          amount: 200000.0,
          categoryId: 'shopping',
          date: DateTime(now.year, now.month, 14, 15, 30),
          type: TransactionType.expense,
          accountId: 'default_account',
          createdAt: now,
        ),
        
        // Health
        Transaction(
          id: 'tx_health1_${now.millisecondsSinceEpoch + 10}',
          description: 'Pharmacy',
          amount: 75000.0,
          categoryId: 'health',
          date: DateTime(now.year, now.month, 6, 11, 45),
          type: TransactionType.expense,
          accountId: 'default_account',
          createdAt: now,
        ),
      ];
      
      // Clear existing transactions and save new ones
      await WebStorageService.saveTransactions(sampleTransactions);
      print('✅ Created ${sampleTransactions.length} sample transactions');
      
      // Calculate totals for verification
      final totalIncome = sampleTransactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);
      final totalExpenses = sampleTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      print('💰 Total Income: ${totalIncome.toStringAsFixed(0)} COP');
      print('💸 Total Expenses: ${totalExpenses.toStringAsFixed(0)} COP');
      print('💵 Balance: ${(totalIncome - totalExpenses).toStringAsFixed(0)} COP');
      
      // Create sample budgets for current month
      final budgets = [
        Budget(
          id: 'budget_food_${now.millisecondsSinceEpoch}',
          name: 'Food Budget',
          amount: 300000.0,
          categoryId: 'food',
          period: BudgetPeriod.monthly,
          startDate: currentMonth,
          endDate: DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1)),
          isActive: true,
          createdAt: now,
        ),
        Budget(
          id: 'budget_transport_${now.millisecondsSinceEpoch + 1}',
          name: 'Transportation Budget',
          amount: 250000.0,
          categoryId: 'transportation',
          period: BudgetPeriod.monthly,
          startDate: currentMonth,
          endDate: DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1)),
          isActive: true,
          createdAt: now,
        ),
        Budget(
          id: 'budget_entertainment_${now.millisecondsSinceEpoch + 2}',
          name: 'Entertainment Budget',
          amount: 150000.0,
          categoryId: 'entertainment',
          period: BudgetPeriod.monthly,
          startDate: currentMonth,
          endDate: DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1)),
          isActive: true,
          createdAt: now,
        ),
      ];
      
      // Save budgets
      for (final budget in budgets) {
        await BudgetService.updateBudget(budget);
        print('✅ Created budget: ${budget.name} (${budget.amount.toStringAsFixed(0)} COP)');
      }
      
      print('\n🎉 Test data recreated successfully!');
      print('📊 Analytics should now show current month data');
      print('🔄 Please refresh the Analytics screen to see the changes');
      
    } catch (e) {
      print('❌ Error recreating test data: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }
}