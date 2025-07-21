import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/app_initialization_service.dart';
import '../services/web_storage_service.dart';
import '../services/transactions_service.dart';
import '../services/settings_service.dart';

class IntelligenceScreen extends StatefulWidget {
  const IntelligenceScreen({Key? key}) : super(key: key);

  @override
  State<IntelligenceScreen> createState() => _IntelligenceScreenState();
}

class _IntelligenceScreenState extends State<IntelligenceScreen> {
  List<Category> _categories = [];
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  Map<String, dynamic> _insights = {};
  String _currency = 'COP'; // Default to Colombian Peso

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    // Load currency setting
    final prefs = await SharedPreferences.getInstance();
    final currency = prefs.getString('currency') ?? 'COP';
    
    try {
      // Load categories and transactions
      final categories = await AppInitializationService.getCategories();
      final webTransactions = await WebStorageService.getTransactions(includeTestData: false);
      final localTransactions = await TransactionsService.getTransactions(includeTestData: false);
      
      // Merge transactions from both sources, avoiding duplicates by ID
      final Map<String, Transaction> transactionMap = {};
      
      for (final tx in webTransactions) {
        transactionMap[tx.id] = tx;
      }
      
      for (final tx in localTransactions) {
        transactionMap[tx.id] = tx;
      }
      
      final allTransactions = transactionMap.values.toList();
      
      // Generate insights
      final insights = _generateInsights(allTransactions, categories);
      
      setState(() {
        _categories = categories;
        _transactions = allTransactions;
        _insights = insights;
        _currency = currency;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading intelligence data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Map<String, dynamic> _generateInsights(List<Transaction> transactions, List<Category> categories) {
    if (transactions.isEmpty) {
      return {
        'hasData': false,
        'message': 'Add some transactions to see AI insights',
      };
    }
    
    // Sort transactions by date (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));
    
    // Calculate basic metrics
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final savingsRate = totalIncome > 0 ? (totalIncome - totalExpenses) / totalIncome * 100 : 0.0;
    
    // Get top spending categories
    final Map<String, double> categorySpending = {};
    for (final tx in transactions.where((t) => t.type == TransactionType.expense)) {
      final categoryId = tx.categoryId;
      categorySpending[categoryId] = (categorySpending[categoryId] ?? 0) + tx.amount;
    }
    
    final topCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Get category names
    final topCategoriesWithNames = topCategories.take(3).map((entry) {
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => Category(id: 'unknown', name: 'Unknown', iconCodePoint: Icons.help.codePoint, iconFontFamily: Icons.help.fontFamily, colorValue: Colors.grey.value),
      );
      return {
        'category': category,
        'amount': entry.value,
        'percentage': totalExpenses > 0 ? (entry.value / totalExpenses * 100) : 0.0,
      };
    }).toList();
    
    // Check spending trends
    final now = DateTime.now();
    final thisMonth = transactions.where(
      (t) => t.date.month == now.month && t.date.year == now.year && t.type == TransactionType.expense
    ).fold(0.0, (sum, t) => sum + t.amount);
    
    final lastMonth = transactions.where(
      (t) => t.date.month == (now.month > 1 ? now.month - 1 : 12) && 
             t.date.year == (now.month > 1 ? now.year : now.year - 1) && 
             t.type == TransactionType.expense
    ).fold(0.0, (sum, t) => sum + t.amount);
    
    final spendingTrend = lastMonth > 0 ? ((thisMonth - lastMonth) / lastMonth * 100) : 0.0;
    
    return {
      'hasData': true,
      'totalTransactions': transactions.length,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'savingsRate': savingsRate,
      'topCategories': topCategoriesWithNames,
      'spendingTrend': spendingTrend,
      'lastTransaction': transactions.isNotEmpty ? transactions.first : null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Insights',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildInsightsContent(),
    );
  }
  
  Widget _buildInsightsContent() {
    if (_transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Add some transactions to see AI insights',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 16),
        _buildSpendingTrendCard(),
        const SizedBox(height: 16),
        _buildTopCategoriesCard(),
        const SizedBox(height: 16),
        _buildSavingsInsightCard(),
      ],
    );
  }
  
  Widget _buildSummaryCard() {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Income',
                  SettingsService.formatCurrency(_insights['totalIncome'], _currency),
                  Icons.arrow_upward,
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Expenses',
                  SettingsService.formatCurrency(_insights['totalExpenses'], _currency),
                  Icons.arrow_downward,
                  Colors.red,
                ),
                _buildSummaryItem(
                  'Transactions',
                  '${_insights['totalTransactions']}',
                  Icons.receipt_long,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
  
  Widget _buildSpendingTrendCard() {
    final spendingTrend = _insights['spendingTrend'] as double;
    final isPositive = spendingTrend > 0;
    final trendColor = isPositive ? Colors.red : Colors.green;
    final trendIcon = isPositive ? Icons.trending_up : Icons.trending_down;
    final trendText = isPositive 
        ? 'Spending increased by ${spendingTrend.abs().toStringAsFixed(1)}%'
        : 'Spending decreased by ${spendingTrend.abs().toStringAsFixed(1)}%';
    
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(trendIcon, color: trendColor),
                const SizedBox(width: 8),
                const Text(
                  'Spending Trend',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              trendText,
              style: TextStyle(fontSize: 16, color: trendColor),
            ),
            const SizedBox(height: 8),
            Text(
              isPositive
                  ? 'Consider reviewing your budget to reduce expenses.'
                  : 'Great job managing your expenses!',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTopCategoriesCard() {
    final topCategories = _insights['topCategories'] as List;
    
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Spending Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...topCategories.map((categoryData) {
              final category = categoryData['category'] as Category;
              final amount = categoryData['amount'] as double;
              final percentage = categoryData['percentage'] as double;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          IconData(
                            category.iconCodePoint,
                            fontFamily: category.iconFontFamily,
                          ),
                          color: Color(category.colorValue),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          SettingsService.formatCurrency(amount, _currency),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Color(category.colorValue)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${percentage.toStringAsFixed(1)}% of total expenses',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSavingsInsightCard() {
    final savingsRate = _insights['savingsRate'] as double;
    final savingsColor = savingsRate >= 20
        ? Colors.green
        : savingsRate >= 10
            ? Colors.orange
            : Colors.red;
    
    String savingsAdvice;
    if (savingsRate >= 20) {
      savingsAdvice = 'Excellent savings rate! You\'re on track for financial success.';
    } else if (savingsRate >= 10) {
      savingsAdvice = 'Good savings rate, but there\'s room for improvement. Try to increase it to 20%.';
    } else if (savingsRate > 0) {
      savingsAdvice = 'Your savings rate is low. Consider reducing expenses or increasing income.';
    } else {
      savingsAdvice = 'You\'re spending more than you earn. This is not sustainable in the long term.';
    }
    
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.savings, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Savings Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Your savings rate: ${savingsRate.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: savingsColor),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: savingsRate / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(savingsColor),
            ),
            const SizedBox(height: 12),
            Text(savingsAdvice, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}