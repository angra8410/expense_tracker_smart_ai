import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../models/financial_intelligence.dart';
import '../services/intelligence_service.dart';
import '../services/web_storage_service.dart';
import 'ml_insights_screen.dart';
=======
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/app_initialization_service.dart';
import '../services/web_storage_service.dart';
import '../services/transactions_service.dart';
import '../services/settings_service.dart';
>>>>>>> dd0532278731c5cc55e6d7f669d18270155e542b

class IntelligenceScreen extends StatefulWidget {
  const IntelligenceScreen({Key? key}) : super(key: key);

  @override
  State<IntelligenceScreen> createState() => _IntelligenceScreenState();
}

class _IntelligenceScreenState extends State<IntelligenceScreen> {
<<<<<<< HEAD
  bool _isLoading = true;
  List<FinancialInsight> _insights = [];
  FinancialHealthMetrics? _healthMetrics;
  List<SpendingPrediction> _predictions = [];
=======
  List<Category> _categories = [];
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  Map<String, dynamic> _insights = {};
  String _currency = 'COP'; // Default to Colombian Peso
>>>>>>> dd0532278731c5cc55e6d7f669d18270155e542b

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _loadIntelligenceData();
  }

  Future<void> _loadIntelligenceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        IntelligenceService.getLatestInsights(),
        IntelligenceService.getFinancialHealth(),
        IntelligenceService.getSpendingPredictions(),
      ]);

      setState(() {
        _insights = results[0] as List<FinancialInsight>;
        _healthMetrics = results[1] as FinancialHealthMetrics?;
        _predictions = results[2] as List<SpendingPrediction>;
=======
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
>>>>>>> dd0532278731c5cc55e6d7f669d18270155e542b
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading intelligence data: $e');
      setState(() {
        _isLoading = false;
      });
    }
<<<<<<< HEAD
=======
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
>>>>>>> dd0532278731c5cc55e6d7f669d18270155e542b
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadIntelligenceData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_healthMetrics != null) _buildHealthMetricsCard(),
                    const SizedBox(height: 16),
                    _buildQuickInsights(),
                    const SizedBox(height: 16),
                    _buildAdvancedAnalysisCard(),
                    const SizedBox(height: 16),
                    if (_predictions.isNotEmpty) _buildPredictionsCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHealthMetricsCard() {
    final score = _healthMetrics!.overallScore;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getScoreIcon(score),
                  color: _getHealthScoreColor(score),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Financial Health Score',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '${score.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _getHealthScoreColor(score),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/ 100',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getHealthScoreColor(score)),
              minHeight: 8,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Savings Rate',
                    '${(_healthMetrics!.savingsRate * 100).toStringAsFixed(1)}%',
                    Icons.savings,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Expense Variability',
                    '${(_healthMetrics!.expenseVariability * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
                  ),
=======
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
>>>>>>> dd0532278731c5cc55e6d7f669d18270155e542b
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[600], size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[600],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickInsights() {
    final actionableInsights = _insights.where((i) => i.actionable).take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Insights',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 12),
        ...actionableInsights.map((insight) => Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getInsightTypeColor(insight.type),
              child: Icon(
                _getInsightTypeIcon(insight.type),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(insight.title),
            subtitle: Text(insight.description),
            trailing: Text(
              '${(insight.confidence * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildAdvancedAnalysisCard() {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MLInsightsScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: Colors.purple[600],
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Advanced ML Analysis',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Get deeper insights with machine learning analysis, anomaly detection, and personalized recommendations.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildFeatureChip('Anomaly Detection', Icons.warning_amber),
                  const SizedBox(width: 8),
                  _buildFeatureChip('Smart Predictions', Icons.trending_up),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildFeatureChip('Cashflow Forecast', Icons.account_balance),
                  const SizedBox(width: 8),
                  _buildFeatureChip('Personal Advice', Icons.lightbulb),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.purple[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.purple[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
=======
  
  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
        ),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
  
  Widget _buildSpendingTrendCard() {
    final spendingTrend = _insights['spendingTrend'] as double;
    final isPositive = spendingTrend > 0;
    final trendText = isPositive
        ? 'Spending increased by ${spendingTrend.abs().toStringAsFixed(1)}% compared to last month'
        : spendingTrend < 0
            ? 'Spending decreased by ${spendingTrend.abs().toStringAsFixed(1)}% compared to last month'
            : 'Spending is the same as last month';
    
    final trendColor = isPositive ? Colors.red : Colors.green;
    final trendIcon = isPositive ? Icons.trending_up : Icons.trending_down;
    
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
>>>>>>> dd0532278731c5cc55e6d7f669d18270155e542b
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
<<<<<<< HEAD
                Icon(
                  Icons.trending_up,
                  color: Colors.orange[600],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Spending Predictions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
=======
                Icon(trendIcon, color: trendColor),
                const SizedBox(width: 8),
                const Text(
                  'Spending Trend',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
>>>>>>> dd0532278731c5cc55e6d7f669d18270155e542b
                ),
              ],
            ),
            const SizedBox(height: 16),
<<<<<<< HEAD
            ..._predictions.take(3).map((prediction) => FutureBuilder<String>(
              future: _getCategoryName(prediction.categoryId),
              builder: (context, snapshot) {
                final categoryName = snapshot.data ?? prediction.categoryId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.orange[600],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              'Predicted: \$${prediction.predictedAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(prediction.confidence * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            )).toList(),
=======
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
>>>>>>> dd0532278731c5cc55e6d7f669d18270155e542b
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD

  Future<String> _getCategoryName(String categoryId) async {
    try {
      final categories = await WebStorageService.getCategories();
      final category = categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => throw Exception('Category not found'),
      );
      return category.name;
    } catch (e) {
      return categoryId; // Fallback to ID if category not found
    }
  }

  Color _getHealthScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(double score) {
    if (score >= 80) return Icons.sentiment_very_satisfied;
    if (score >= 60) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  Color _getInsightTypeColor(InsightType type) {
    switch (type) {
      case InsightType.recommendation:
        return Colors.blue;
      case InsightType.warning:
        return Colors.orange;
      case InsightType.achievement:
        return Colors.green;
      case InsightType.anomaly:
        return Colors.red;
      case InsightType.pattern:
        return Colors.purple;
      case InsightType.opportunity:
        return Colors.teal;
    }
  }

  IconData _getInsightTypeIcon(InsightType type) {
    switch (type) {
      case InsightType.recommendation:
        return Icons.lightbulb;
      case InsightType.warning:
        return Icons.warning;
      case InsightType.achievement:
        return Icons.star;
      case InsightType.anomaly:
        return Icons.error;
      case InsightType.pattern:
        return Icons.trending_up;
      case InsightType.opportunity:
        return Icons.flag;
=======
  
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
>>>>>>> dd0532278731c5cc55e6d7f669d18270155e542b
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