import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart AI Expense Tracker'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @aiInsights.
  ///
  /// In en, this message translates to:
  /// **'AI Insights'**
  String get aiInsights;

  /// No description provided for @testing.
  ///
  /// In en, this message translates to:
  /// **'Testing'**
  String get testing;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get editTransaction;

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get deleteTransaction;

  /// No description provided for @transactionAdded.
  ///
  /// In en, this message translates to:
  /// **'Transaction added successfully!'**
  String get transactionAdded;

  /// No description provided for @transactionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Transaction updated successfully!'**
  String get transactionUpdated;

  /// No description provided for @transactionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted successfully!'**
  String get transactionDeleted;

  /// No description provided for @confirmDeleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction?'**
  String get confirmDeleteTransaction;

  /// No description provided for @confirmDeleteTransactionMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get confirmDeleteTransactionMessage;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get enterDescription;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get pleaseEnterAmount;

  /// No description provided for @pleaseEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get pleaseEnterDescription;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get invalidAmount;

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterValidAmount;

  /// No description provided for @totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get totalIncome;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @netBalance.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get netBalance;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @addFirstTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add your first transaction to get started'**
  String get addFirstTransaction;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @categoryAdded.
  ///
  /// In en, this message translates to:
  /// **'Category added successfully!'**
  String get categoryAdded;

  /// No description provided for @categoryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Category updated successfully!'**
  String get categoryUpdated;

  /// No description provided for @categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category deleted successfully!'**
  String get categoryDeleted;

  /// No description provided for @confirmDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category?'**
  String get confirmDeleteCategory;

  /// No description provided for @confirmDeleteCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All transactions in this category will be moved to \'Other\'.'**
  String get confirmDeleteCategoryMessage;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @categoryIcon.
  ///
  /// In en, this message translates to:
  /// **'Category Icon'**
  String get categoryIcon;

  /// No description provided for @categoryColor.
  ///
  /// In en, this message translates to:
  /// **'Category Color'**
  String get categoryColor;

  /// No description provided for @pleaseEnterCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a category name'**
  String get pleaseEnterCategoryName;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategories;

  /// No description provided for @addFirstCategory.
  ///
  /// In en, this message translates to:
  /// **'Add your first category to organize your transactions'**
  String get addFirstCategory;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// No description provided for @confirmClearData.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all data?'**
  String get confirmClearData;

  /// No description provided for @confirmClearDataMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your transactions, categories, and settings will be permanently deleted.'**
  String get confirmClearDataMessage;

  /// No description provided for @dataCleared.
  ///
  /// In en, this message translates to:
  /// **'All data cleared successfully!'**
  String get dataCleared;

  /// No description provided for @dataExported.
  ///
  /// In en, this message translates to:
  /// **'Data exported successfully!'**
  String get dataExported;

  /// No description provided for @dataImported.
  ///
  /// In en, this message translates to:
  /// **'Data imported successfully!'**
  String get dataImported;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get lastWeek;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @localization.
  ///
  /// In en, this message translates to:
  /// **'Localization'**
  String get localization;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @chooseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Choose your currency'**
  String get chooseCurrency;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose your theme'**
  String get chooseTheme;

  /// No description provided for @refreshData.
  ///
  /// In en, this message translates to:
  /// **'Refresh Data'**
  String get refreshData;

  /// No description provided for @loadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Loading categories...'**
  String get loadingCategories;

  /// No description provided for @readyTransactions.
  ///
  /// In en, this message translates to:
  /// **'Ready! {count} categories loaded'**
  String readyTransactions(int count);

  /// No description provided for @coffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get coffee;

  /// No description provided for @lunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get lunch;

  /// No description provided for @gas.
  ///
  /// In en, this message translates to:
  /// **'Gas'**
  String get gas;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// No description provided for @grocery.
  ///
  /// In en, this message translates to:
  /// **'Grocery'**
  String get grocery;

  /// No description provided for @movie.
  ///
  /// In en, this message translates to:
  /// **'Movie'**
  String get movie;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @spendingOverview.
  ///
  /// In en, this message translates to:
  /// **'Spending Overview'**
  String get spendingOverview;

  /// No description provided for @categoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get categoryBreakdown;

  /// No description provided for @budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgets;

  /// No description provided for @budgetManagement.
  ///
  /// In en, this message translates to:
  /// **'Budget Management'**
  String get budgetManagement;

  /// No description provided for @createBudget.
  ///
  /// In en, this message translates to:
  /// **'Create Budget'**
  String get createBudget;

  /// No description provided for @editBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit Budget'**
  String get editBudget;

  /// No description provided for @updateBudget.
  ///
  /// In en, this message translates to:
  /// **'Update Budget'**
  String get updateBudget;

  /// No description provided for @deleteBudget.
  ///
  /// In en, this message translates to:
  /// **'Delete Budget'**
  String get deleteBudget;

  /// No description provided for @budgetName.
  ///
  /// In en, this message translates to:
  /// **'Budget Name'**
  String get budgetName;

  /// No description provided for @budgetPeriod.
  ///
  /// In en, this message translates to:
  /// **'Budget Period'**
  String get budgetPeriod;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @enableRollover.
  ///
  /// In en, this message translates to:
  /// **'Enable Rollover'**
  String get enableRollover;

  /// No description provided for @rolloverDescription.
  ///
  /// In en, this message translates to:
  /// **'Unused budget carries over to next period'**
  String get rolloverDescription;

  /// No description provided for @smartBudgetRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Smart Budget Recommendations'**
  String get smartBudgetRecommendations;

  /// No description provided for @budgetOverview.
  ///
  /// In en, this message translates to:
  /// **'Budget Overview'**
  String get budgetOverview;

  /// No description provided for @totalBudget.
  ///
  /// In en, this message translates to:
  /// **'Total Budget'**
  String get totalBudget;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpent;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @overallProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall Progress'**
  String get overallProgress;

  /// No description provided for @activeBudgets.
  ///
  /// In en, this message translates to:
  /// **'Active Budgets'**
  String get activeBudgets;

  /// No description provided for @noBudgetsYet.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet'**
  String get noBudgetsYet;

  /// No description provided for @createFirstBudget.
  ///
  /// In en, this message translates to:
  /// **'Create your first budget to start tracking your spending goals'**
  String get createFirstBudget;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'spent'**
  String get spent;

  /// No description provided for @budgeted.
  ///
  /// In en, this message translates to:
  /// **'budgeted'**
  String get budgeted;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'used'**
  String get used;

  /// No description provided for @suggested.
  ///
  /// In en, this message translates to:
  /// **'suggested'**
  String get suggested;

  /// No description provided for @pleaseEnterBudgetName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a budget name'**
  String get pleaseEnterBudgetName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @budgetCreated.
  ///
  /// In en, this message translates to:
  /// **'Budget created successfully!'**
  String get budgetCreated;

  /// No description provided for @budgetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Budget updated successfully!'**
  String get budgetUpdated;

  /// No description provided for @budgetDeleted.
  ///
  /// In en, this message translates to:
  /// **'Budget deleted successfully!'**
  String get budgetDeleted;

  /// No description provided for @confirmDeleteBudget.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this budget?'**
  String get confirmDeleteBudget;

  /// No description provided for @confirmDeleteBudgetMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All budget data will be permanently removed.'**
  String get confirmDeleteBudgetMessage;

  /// No description provided for @onTrack.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get onTrack;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @exceeded.
  ///
  /// In en, this message translates to:
  /// **'Exceeded'**
  String get exceeded;

  /// No description provided for @rolloverEnabled.
  ///
  /// In en, this message translates to:
  /// **'Rollover Enabled'**
  String get rolloverEnabled;

  /// No description provided for @rolloverDisabled.
  ///
  /// In en, this message translates to:
  /// **'Rollover Disabled'**
  String get rolloverDisabled;

  /// No description provided for @budgetRolledOver.
  ///
  /// In en, this message translates to:
  /// **'Budget rolled over with {amount} remaining'**
  String budgetRolledOver(String amount);

  /// No description provided for @aiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis'**
  String get aiAnalysis;

  /// No description provided for @aiAnalysisDescription.
  ///
  /// In en, this message translates to:
  /// **'Intelligent insights and spending patterns'**
  String get aiAnalysisDescription;

  /// No description provided for @aiAnalysisScore.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis Score'**
  String get aiAnalysisScore;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @noCategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get noCategoriesFound;

  /// No description provided for @debugControls.
  ///
  /// In en, this message translates to:
  /// **'Debug Controls'**
  String get debugControls;

  /// No description provided for @testCompleted.
  ///
  /// In en, this message translates to:
  /// **'Test completed'**
  String get testCompleted;

  /// No description provided for @allDataCleared.
  ///
  /// In en, this message translates to:
  /// **'All data cleared'**
  String get allDataCleared;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food & Dining'**
  String get categoryFood;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get categoryTransport;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// No description provided for @categoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// No description provided for @categoryBills.
  ///
  /// In en, this message translates to:
  /// **'Bills & Utilities'**
  String get categoryBills;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health & Fitness'**
  String get categoryHealth;

  /// No description provided for @categorySalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get categorySalary;

  /// No description provided for @categoryInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get categoryInvestment;

  /// No description provided for @categoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// No description provided for @categoryGift.
  ///
  /// In en, this message translates to:
  /// **'Gifts & Donations'**
  String get categoryGift;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @smartCategoryPrediction.
  ///
  /// In en, this message translates to:
  /// **'Smart Category Prediction'**
  String get smartCategoryPrediction;

  /// No description provided for @anomalyDetection.
  ///
  /// In en, this message translates to:
  /// **'Anomaly Detection'**
  String get anomalyDetection;

  /// No description provided for @cashflowForecast.
  ///
  /// In en, this message translates to:
  /// **'Cashflow Forecast'**
  String get cashflowForecast;

  /// No description provided for @personalizedAdvice.
  ///
  /// In en, this message translates to:
  /// **'Personalized Advice'**
  String get personalizedAdvice;

  /// No description provided for @mlInsights.
  ///
  /// In en, this message translates to:
  /// **'ML Insights'**
  String get mlInsights;

  /// No description provided for @unusualSpending.
  ///
  /// In en, this message translates to:
  /// **'Unusual Spending'**
  String get unusualSpending;

  /// No description provided for @spendingAnomaly.
  ///
  /// In en, this message translates to:
  /// **'Spending Anomaly Detected'**
  String get spendingAnomaly;

  /// No description provided for @forecastBalance.
  ///
  /// In en, this message translates to:
  /// **'Forecasted Balance'**
  String get forecastBalance;

  /// No description provided for @predictedIncome.
  ///
  /// In en, this message translates to:
  /// **'Predicted Income'**
  String get predictedIncome;

  /// No description provided for @predictedExpenses.
  ///
  /// In en, this message translates to:
  /// **'Predicted Expenses'**
  String get predictedExpenses;

  /// No description provided for @confidenceLevel.
  ///
  /// In en, this message translates to:
  /// **'Confidence: {confidence}%'**
  String confidenceLevel(String confidence);

  /// No description provided for @potentialSavings.
  ///
  /// In en, this message translates to:
  /// **'Potential Savings: {amount}'**
  String potentialSavings(String amount);

  /// No description provided for @mlAccuracy.
  ///
  /// In en, this message translates to:
  /// **'ML Accuracy: {accuracy}%'**
  String mlAccuracy(String accuracy);

  /// No description provided for @anomalyScore.
  ///
  /// In en, this message translates to:
  /// **'Anomaly Score: {score}'**
  String anomalyScore(String score);

  /// No description provided for @expectedRange.
  ///
  /// In en, this message translates to:
  /// **'Expected Range: {min} - {max}'**
  String expectedRange(String min, String max);

  /// No description provided for @forecastDays.
  ///
  /// In en, this message translates to:
  /// **'Forecast for {days} days'**
  String forecastDays(String days);

  /// No description provided for @adviceDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty: {difficulty}'**
  String adviceDifficulty(String difficulty);

  /// No description provided for @adviceTimeframe.
  ///
  /// In en, this message translates to:
  /// **'Timeframe: {timeframe}'**
  String adviceTimeframe(String timeframe);

  /// No description provided for @mlFeatures.
  ///
  /// In en, this message translates to:
  /// **'🤖 ML Features'**
  String get mlFeatures;

  /// No description provided for @smartCategoryAssignment.
  ///
  /// In en, this message translates to:
  /// **'Smart Category Auto-Assignment'**
  String get smartCategoryAssignment;

  /// No description provided for @smartCategoryDesc.
  ///
  /// In en, this message translates to:
  /// **'ML learns your patterns and suggests categories'**
  String get smartCategoryDesc;

  /// No description provided for @anomalyAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get alerts for unusual spending patterns'**
  String get anomalyAlertsDesc;

  /// No description provided for @cashflowForecastDesc.
  ///
  /// In en, this message translates to:
  /// **'Predict future account balances'**
  String get cashflowForecastDesc;

  /// No description provided for @personalizedAdviceDesc.
  ///
  /// In en, this message translates to:
  /// **'Custom recommendations based on your behavior'**
  String get personalizedAdviceDesc;

  /// No description provided for @enableMLFeatures.
  ///
  /// In en, this message translates to:
  /// **'Enable ML Features'**
  String get enableMLFeatures;

  /// No description provided for @mlAnalysisRunning.
  ///
  /// In en, this message translates to:
  /// **'Running ML Analysis...'**
  String get mlAnalysisRunning;

  /// No description provided for @mlAnalysisComplete.
  ///
  /// In en, this message translates to:
  /// **'ML Analysis Complete'**
  String get mlAnalysisComplete;

  /// No description provided for @insufficientDataForML.
  ///
  /// In en, this message translates to:
  /// **'Need more transactions for ML analysis'**
  String get insufficientDataForML;

  /// No description provided for @viewMLInsights.
  ///
  /// In en, this message translates to:
  /// **'View ML Insights'**
  String get viewMLInsights;

  /// No description provided for @anomalyAlerts.
  ///
  /// In en, this message translates to:
  /// **'Anomaly Alerts'**
  String get anomalyAlerts;

  /// No description provided for @noAnomaliesDetected.
  ///
  /// In en, this message translates to:
  /// **'No anomalies detected'**
  String get noAnomaliesDetected;

  /// No description provided for @forecastAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Forecast Accuracy'**
  String get forecastAccuracy;

  /// No description provided for @highConfidence.
  ///
  /// In en, this message translates to:
  /// **'High Confidence'**
  String get highConfidence;

  /// No description provided for @mediumConfidence.
  ///
  /// In en, this message translates to:
  /// **'Medium Confidence'**
  String get mediumConfidence;

  /// No description provided for @lowConfidence.
  ///
  /// In en, this message translates to:
  /// **'Low Confidence'**
  String get lowConfidence;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
