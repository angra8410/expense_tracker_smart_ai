import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/web_storage_service.dart';
import '../services/enhanced_ml_service.dart';
import '../services/budget_notification_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/ml_models.dart';
import '../l10n/app_localizations.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<AnomalyAlert> _anomalies = [];
  List<PersonalizedAdvice> _advice = [];
  bool _isLoading = true;
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    
    // Register for budget update notifications (which are triggered when transactions change)
    BudgetNotificationService.addBudgetUpdateListener(_onTransactionUpdateNotification);
    
    _loadData();
  }

  @override
  void dispose() {
    // Unregister from budget update notifications
    BudgetNotificationService.removeBudgetUpdateListener(_onTransactionUpdateNotification);
    
    super.dispose();
  }

  /// Called when transactions change and analytics need to be refreshed
  void _onTransactionUpdateNotification() {
    if (mounted) {
      print('📊 Analytics screen received update notification, refreshing data...');
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Add debug information and use the same parameters as budget screen
      print('📊 Analytics: Loading transactions...');
      final transactions = await WebStorageService.getTransactions(includeTestData: false);
      final categories = await WebStorageService.getCategories();
      
      print('📊 Analytics: Loaded ${transactions.length} transactions');
      print('📊 Analytics: Loaded ${categories.length} categories');
      
      // Load ML insights
      final anomalies = await EnhancedMLService.loadAnomalyAlerts();
      final advice = await EnhancedMLService.loadPersonalizedAdvice();

      setState(() {
        _transactions = transactions;
        _categories = categories;
        _anomalies = anomalies;
        _advice = advice;
        _isLoading = false;
      });
      
      print('📊 Analytics: Data loaded successfully');
    } catch (e) {
      print('❌ Error loading analytics data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analytics),
        backgroundColor: Colors.blue[600]!,
        foregroundColor: Colors.white,
        actions: [
          // Add refresh button
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh Analytics',
          ),
          PopupMenuButton<String>(
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
              const PopupMenuItem(value: 'year', child: Text('This Year')),
            ],
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.date_range),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCards(),
                    const SizedBox(height: 24),
                    _buildSpendingChart(),
                    const SizedBox(height: 24),
                    _buildCategoryBreakdown(),
                    const SizedBox(height: 24),
                    _buildAnomalyAlerts(),
                    const SizedBox(height: 24),
                    _buildPersonalizedAdvice(),
                    const SizedBox(height: 24),
                    _buildFinancialHealthScore(),
                    const SizedBox(height: 24),
                    _buildSpendingVelocity(),
                    const SizedBox(height: 24),
                    _buildSavingsRate(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    final filteredTransactions = _getFilteredTransactions();
    final totalIncome = filteredTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = filteredTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpenses;

    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            'Income',
            totalIncome,
            Icons.trending_up,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildOverviewCard(
            'Expenses',
            totalExpenses,
            Icons.trending_down,
            Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildOverviewCard(
            'Balance',
            balance,
            Icons.account_balance,
            balance >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, double amount, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingChart() {
    final filteredTransactions = _getFilteredTransactions()
        .where((t) => t.type == TransactionType.expense)
        .toList();

    if (filteredTransactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Spending Trend',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text('No expense data available'),
            ],
          ),
        ),
      );
    }

    // Group transactions by day for the chart
    final dailySpending = <DateTime, double>{};
    for (var transaction in filteredTransactions) {
      final date = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
      dailySpending[date] = (dailySpending[date] ?? 0) + transaction.amount;
    }

    final sortedDates = dailySpending.keys.toList()..sort();
    final spots = sortedDates.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), dailySpending[entry.value]!);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Trend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('\$${value.toInt()}');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < sortedDates.length) {
                            final date = sortedDates[value.toInt()];
                            return Text('${date.day}/${date.month}');
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final filteredTransactions = _getFilteredTransactions()
        .where((t) => t.type == TransactionType.expense)
        .toList();

    if (filteredTransactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Category Breakdown',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text('No expense data available'),
            ],
          ),
        ),
      );
    }

    final categorySpending = <String, double>{};
    for (var transaction in filteredTransactions) {
      categorySpending[transaction.categoryId] = 
          (categorySpending[transaction.categoryId] ?? 0) + transaction.amount;
    }

    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...sortedCategories.take(5).map((entry) {
              final category = _categories.firstWhere(
                (c) => c.id == entry.key,
                orElse: () => Category(
                  id: entry.key,
                  name: 'Unknown',
                  iconCodePoint: Icons.help.codePoint,
                  colorValue: Colors.grey.value,
                ),
              );
              final percentage = (entry.value / categorySpending.values.reduce((a, b) => a + b)) * 100;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(category.icon, color: category.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(category.name),
                    ),
                    Text('\$${entry.value.toStringAsFixed(2)}'),
                    const SizedBox(width: 8),
                    Text('${percentage.toStringAsFixed(1)}%'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyAlerts() {
    if (_anomalies.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Anomaly Alerts',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text('No anomalies detected'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anomaly Alerts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._anomalies.take(3).map((anomaly) {
              Color severityColor;
              switch (anomaly.severity) {
                case AnomalySeverity.low:
                  severityColor = Colors.green;
                  break;
                case AnomalySeverity.medium:
                  severityColor = Colors.orange;
                  break;
                case AnomalySeverity.high:
                  severityColor = Colors.red;
                  break;
                case AnomalySeverity.critical:
                  severityColor = Colors.red[900]!;
                  break;
              }

              return Card(
                color: severityColor.withOpacity(0.1),
                child: ListTile(
                  leading: Icon(Icons.warning, color: severityColor),
                  title: Text(anomaly.type.toString().split('.').last),
                  subtitle: Text(
                    '${anomaly.transaction.description} - \$${anomaly.transaction.amount.toStringAsFixed(2)}\n'
                    'Expected: ${anomaly.expectedRange}',
                  ),
                  trailing: Text(
                    '${(anomaly.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: severityColor),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedAdvice() {
    if (_advice.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Personalized Advice',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text('No advice available'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personalized Advice',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._advice.take(3).map((advice) {
              Color priorityColor;
              switch (advice.priority) {
                case AdvicePriority.low:
                  priorityColor = Colors.green;
                  break;
                case AdvicePriority.medium:
                  priorityColor = Colors.orange;
                  break;
                case AdvicePriority.high:
                  priorityColor = Colors.red;
                  break;
                case AdvicePriority.critical:
                  priorityColor = Colors.red[900]!;
                  break;
              }

              return Card(
                color: priorityColor.withOpacity(0.1),
                child: ExpansionTile(
                  leading: Icon(Icons.lightbulb, color: priorityColor),
                  title: Text(advice.title),
                  subtitle: Text(advice.description),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Action Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...advice.actionItems.map((item) => Padding(
                            padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• '),
                                Expanded(child: Text(item)),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialHealthScore() {
    final filteredTransactions = _getFilteredTransactions();
    final totalIncome = filteredTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = filteredTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    double healthScore = 0.0;
    if (totalIncome > 0) {
      final savingsRate = (totalIncome - totalExpenses) / totalIncome;
      healthScore = (savingsRate * 100).clamp(0.0, 100.0);
    }

    Color scoreColor;
    if (healthScore >= 80) {
      scoreColor = Colors.green;
    } else if (healthScore >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Health Score',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: healthScore / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${healthScore.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              healthScore >= 80 ? 'Excellent financial health!' :
              healthScore >= 60 ? 'Good financial health' :
              'Consider improving your savings rate',
              style: TextStyle(color: scoreColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingVelocity() {
    final filteredTransactions = _getFilteredTransactions()
        .where((t) => t.type == TransactionType.expense)
        .toList();

    if (filteredTransactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Spending Velocity',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text('No expense data available'),
            ],
          ),
        ),
      );
    }

    final totalAmount = filteredTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final daysDiff = _selectedPeriod == 'week' ? 7 : 
                    _selectedPeriod == 'month' ? 30 : 365;
    final dailyAverage = totalAmount / daysDiff;
    final weeklyAverage = dailyAverage * 7;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Velocity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Daily Average',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '\$${dailyAverage.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Weekly Average',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '\$${weeklyAverage.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsRate() {
    final filteredTransactions = _getFilteredTransactions();
    final totalIncome = filteredTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = filteredTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    double savingsRate = 0.0;
    if (totalIncome > 0) {
      savingsRate = ((totalIncome - totalExpenses) / totalIncome * 100).clamp(-100.0, 100.0);
    }

    Color rateColor;
    if (savingsRate >= 20) {
      rateColor = Colors.green;
    } else if (savingsRate >= 10) {
      rateColor = Colors.orange;
    } else {
      rateColor = Colors.red;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Savings Rate',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (savingsRate + 100) / 200, // Normalize to 0-1 range
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(rateColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${savingsRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rateColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              savingsRate >= 20 ? 'Excellent savings rate!' :
              savingsRate >= 10 ? 'Good savings rate' :
              savingsRate >= 0 ? 'Consider saving more' :
              'You\'re spending more than you earn',
              style: TextStyle(color: rateColor),
            ),
          ],
        ),
      ),
    );
  }

  List<Transaction> _getFilteredTransactions() {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    return _transactions.where((t) => t.date.isAfter(startDate) || t.date.isAtSameMomentAs(startDate)).toList();
  }
}