// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart AI Expense Tracker';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get transactions => 'Transactions';

  @override
  String get categories => 'Categories';

  @override
  String get settings => 'Settings';

  @override
  String get analytics => 'Analytics';

  @override
  String get home => 'Home';

  @override
  String get add => 'Add';

  @override
  String get aiInsights => 'AI Insights';

  @override
  String get testing => 'Testing';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get editTransaction => 'Edit Transaction';

  @override
  String get deleteTransaction => 'Delete Transaction';

  @override
  String get transactionAdded => 'Transaction added successfully!';

  @override
  String get transactionUpdated => 'Transaction updated successfully!';

  @override
  String get transactionDeleted => 'Transaction deleted successfully!';

  @override
  String get confirmDeleteTransaction =>
      'Are you sure you want to delete this transaction?';

  @override
  String get confirmDeleteTransactionMessage => 'This action cannot be undone.';

  @override
  String get amount => 'Amount';

  @override
  String get description => 'Description';

  @override
  String get category => 'Category';

  @override
  String get date => 'Date';

  @override
  String get type => 'Type';

  @override
  String get expense => 'Expense';

  @override
  String get income => 'Income';

  @override
  String get submit => 'Submit';

  @override
  String get save => 'Save';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get selectDate => 'Select Date';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get enterDescription => 'Enter description';

  @override
  String get pleaseEnterAmount => 'Please enter an amount';

  @override
  String get pleaseEnterDescription => 'Please enter a description';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get invalidAmount => 'Please enter a valid amount';

  @override
  String get pleaseEnterValidAmount => 'Please enter a valid amount';

  @override
  String get totalIncome => 'Total Income';

  @override
  String get totalExpenses => 'Total Expenses';

  @override
  String get balance => 'Balance';

  @override
  String get netBalance => 'Net Balance';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get addFirstTransaction => 'Add your first transaction to get started';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get viewAll => 'View All';

  @override
  String get addCategory => 'Add Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get categoryAdded => 'Category added successfully!';

  @override
  String get categoryUpdated => 'Category updated successfully!';

  @override
  String get categoryDeleted => 'Category deleted successfully!';

  @override
  String get confirmDeleteCategory =>
      'Are you sure you want to delete this category?';

  @override
  String get confirmDeleteCategoryMessage =>
      'This action cannot be undone. All transactions in this category will be moved to \'Other\'.';

  @override
  String get categoryName => 'Category Name';

  @override
  String get categoryIcon => 'Category Icon';

  @override
  String get categoryColor => 'Category Color';

  @override
  String get pleaseEnterCategoryName => 'Please enter a category name';

  @override
  String get noCategories => 'No categories yet';

  @override
  String get addFirstCategory =>
      'Add your first category to organize your transactions';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get systemMode => 'System';

  @override
  String get language => 'Language';

  @override
  String get currency => 'Currency';

  @override
  String get notifications => 'Notifications';

  @override
  String get exportData => 'Export Data';

  @override
  String get importData => 'Import Data';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get confirmClearData => 'Are you sure you want to clear all data?';

  @override
  String get confirmClearDataMessage =>
      'This action cannot be undone. All your transactions, categories, and settings will be permanently deleted.';

  @override
  String get dataCleared => 'All data cleared successfully!';

  @override
  String get dataExported => 'Data exported successfully!';

  @override
  String get dataImported => 'Data imported successfully!';

  @override
  String get thisWeek => 'This Week';

  @override
  String get lastWeek => 'Last Week';

  @override
  String get appearance => 'Appearance';

  @override
  String get localization => 'Localization';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get chooseCurrency => 'Choose your currency';

  @override
  String get chooseTheme => 'Choose your theme';

  @override
  String get refreshData => 'Refresh Data';

  @override
  String get loadingCategories => 'Loading categories...';

  @override
  String readyTransactions(int count) {
    return 'Ready! $count categories loaded';
  }

  @override
  String get coffee => 'Coffee';

  @override
  String get lunch => 'Lunch';

  @override
  String get gas => 'Gas';

  @override
  String get salary => 'Salary';

  @override
  String get grocery => 'Grocery';

  @override
  String get movie => 'Movie';

  @override
  String get thisMonth => 'This Month';

  @override
  String get lastMonth => 'Last Month';

  @override
  String get thisYear => 'This Year';

  @override
  String get allTime => 'All Time';

  @override
  String get spendingOverview => 'Spending Overview';

  @override
  String get categoryBreakdown => 'Category Breakdown';

  @override
  String get budgets => 'Budgets';

  @override
  String get budgetManagement => 'Budget Management';

  @override
  String get createBudget => 'Create Budget';

  @override
  String get editBudget => 'Edit Budget';

  @override
  String get updateBudget => 'Update Budget';

  @override
  String get deleteBudget => 'Delete Budget';

  @override
  String get budgetName => 'Budget Name';

  @override
  String get budgetPeriod => 'Budget Period';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get enableRollover => 'Enable Rollover';

  @override
  String get rolloverDescription => 'Unused budget carries over to next period';

  @override
  String get smartBudgetRecommendations => 'Smart Budget Recommendations';

  @override
  String get budgetOverview => 'Budget Overview';

  @override
  String get totalBudget => 'Total Budget';

  @override
  String get totalSpent => 'Total Spent';

  @override
  String get remaining => 'Remaining';

  @override
  String get overallProgress => 'Overall Progress';

  @override
  String get activeBudgets => 'Active Budgets';

  @override
  String get noBudgetsYet => 'No budgets yet';

  @override
  String get createFirstBudget =>
      'Create your first budget to start tracking your spending goals';

  @override
  String get spent => 'spent';

  @override
  String get budgeted => 'budgeted';

  @override
  String get used => 'used';

  @override
  String get suggested => 'suggested';

  @override
  String get pleaseEnterBudgetName => 'Please enter a budget name';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get update => 'Update';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get budgetCreated => 'Budget created successfully!';

  @override
  String get budgetUpdated => 'Budget updated successfully!';

  @override
  String get budgetDeleted => 'Budget deleted successfully!';

  @override
  String get confirmDeleteBudget =>
      'Are you sure you want to delete this budget?';

  @override
  String get confirmDeleteBudgetMessage =>
      'This action cannot be undone. All budget data will be permanently removed.';

  @override
  String get onTrack => 'On Track';

  @override
  String get warning => 'Warning';

  @override
  String get exceeded => 'Exceeded';

  @override
  String get rolloverEnabled => 'Rollover Enabled';

  @override
  String get rolloverDisabled => 'Rollover Disabled';

  @override
  String budgetRolledOver(String amount) {
    return 'Budget rolled over with $amount remaining';
  }

  @override
  String get aiAnalysis => 'AI Analysis';

  @override
  String get aiAnalysisDescription =>
      'Intelligent insights and spending patterns';

  @override
  String get aiAnalysisScore => 'AI Analysis Score';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get noCategoriesFound => 'No categories found';

  @override
  String get debugControls => 'Debug Controls';

  @override
  String get testCompleted => 'Test completed';

  @override
  String get allDataCleared => 'All data cleared';

  @override
  String get categoryFood => 'Food & Dining';

  @override
  String get categoryTransport => 'Transportation';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryBills => 'Bills & Utilities';

  @override
  String get categoryHealth => 'Health & Fitness';

  @override
  String get categorySalary => 'Salary';

  @override
  String get categoryInvestment => 'Investments';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryGift => 'Gifts & Donations';

  @override
  String get categoryOther => 'Other';

  @override
  String get smartCategoryPrediction => 'Smart Category Prediction';

  @override
  String get anomalyDetection => 'Anomaly Detection';

  @override
  String get cashflowForecast => 'Cashflow Forecast';

  @override
  String get personalizedAdvice => 'Personalized Advice';

  @override
  String get mlInsights => 'ML Insights';

  @override
  String get unusualSpending => 'Unusual Spending';

  @override
  String get spendingAnomaly => 'Spending Anomaly Detected';

  @override
  String get forecastBalance => 'Forecasted Balance';

  @override
  String get predictedIncome => 'Predicted Income';

  @override
  String get predictedExpenses => 'Predicted Expenses';

  @override
  String confidenceLevel(String confidence) {
    return 'Confidence: $confidence%';
  }

  @override
  String potentialSavings(String amount) {
    return 'Potential Savings: $amount';
  }

  @override
  String mlAccuracy(String accuracy) {
    return 'ML Accuracy: $accuracy%';
  }

  @override
  String anomalyScore(String score) {
    return 'Anomaly Score: $score';
  }

  @override
  String expectedRange(String min, String max) {
    return 'Expected Range: $min - $max';
  }

  @override
  String forecastDays(String days) {
    return 'Forecast for $days days';
  }

  @override
  String adviceDifficulty(String difficulty) {
    return 'Difficulty: $difficulty';
  }

  @override
  String adviceTimeframe(String timeframe) {
    return 'Timeframe: $timeframe';
  }

  @override
  String get mlFeatures => '🤖 ML Features';

  @override
  String get smartCategoryAssignment => 'Smart Category Auto-Assignment';

  @override
  String get smartCategoryDesc =>
      'ML learns your patterns and suggests categories';

  @override
  String get anomalyAlertsDesc => 'Get alerts for unusual spending patterns';

  @override
  String get cashflowForecastDesc => 'Predict future account balances';

  @override
  String get personalizedAdviceDesc =>
      'Custom recommendations based on your behavior';

  @override
  String get enableMLFeatures => 'Enable ML Features';

  @override
  String get mlAnalysisRunning => 'Running ML Analysis...';

  @override
  String get mlAnalysisComplete => 'ML Analysis Complete';

  @override
  String get insufficientDataForML => 'Need more transactions for ML analysis';

  @override
  String get viewMLInsights => 'View ML Insights';

  @override
  String get anomalyAlerts => 'Anomaly Alerts';

  @override
  String get noAnomaliesDetected => 'No anomalies detected';

  @override
  String get forecastAccuracy => 'Forecast Accuracy';

  @override
  String get highConfidence => 'High Confidence';

  @override
  String get mediumConfidence => 'Medium Confidence';

  @override
  String get lowConfidence => 'Low Confidence';
}
