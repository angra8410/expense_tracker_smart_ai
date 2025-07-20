import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/web_storage_service.dart';
import '../services/category_service.dart';
import '../services/settings_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/category_localization.dart';
import '../services/app_initialization_service.dart';

class AnalyticsScreen extends StatefulWidget {
  final String currency;

  const AnalyticsScreen({super.key, required this.currency});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with AutomaticKeepAliveClientMixin {
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String _selectedPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await WebStorageService.getTransactions();
      final categories = await AppInitializationService.getCategories();
      
      setState(() {
        _transactions = transactions;
        _categories = categories;
      });
    } catch (e) {
      print('Error loading analytics data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Transaction> _getFilteredTransactions() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    switch (_selectedPeriod) {
      case 'This Month':
      case 'Este Mes':
        return _transactions.where((t) => t.date.isAfter(startOfMonth)).toList();
      case 'Last Month':
      case 'Mes Pasado':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 1);
        return _transactions.where((t) => t.date.isAfter(lastMonth) && t.date.isBefore(endOfLastMonth)).toList();
      case 'This Year':
      case 'Este Año':
        final startOfYear = DateTime(now.year, 1, 1);
        return _transactions.where((t) => t.date.isAfter(startOfYear)).toList();
      case 'All Time':
      case 'Todo el Tiempo':
      default:
        return _transactions;
    }
  }

  Map<String, double> _getCategorySpending() {
    final filteredTransactions = _getFilteredTransactions();
    final expenses = filteredTransactions.where((t) => t.type == TransactionType.expense);
    
    Map<String, double> categorySpending = {};
    
    for (final transaction in expenses) {
      final categoryName = _getCategoryName(transaction.categoryId);
      categorySpending[categoryName] = (categorySpending[categoryName] ?? 0) + transaction.amount;
    }
    
    return categorySpending;
  }

  String _getCategoryName(String categoryId) {
    final category = _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category(id: 'unknown', name: 'Unknown', iconCodePoint: Icons.help.codePoint, iconFontFamily: Icons.help.fontFamily, colorValue: Colors.grey.value),
    );
    return CategoryLocalization.getLocalizedCategoryNameFromCategory(context, category);
  }

  double _getTotalIncome() {
    return _getFilteredTransactions()
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _getTotalExpenses() {
    return _getFilteredTransactions()
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  String _formatAmount(double amount) {
    return SettingsService.formatCurrency(amount, widget.currency);
  }

  List<String> _getPeriodOptions(AppLocalizations l10n) {
    return [
      l10n.thisMonth,
      l10n.lastMonth,
      l10n.thisYear,
      l10n.allTime,
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('📊 ${l10n.analytics}'),
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final filteredTransactions = _getFilteredTransactions();
    final totalIncome = _getTotalIncome();
    final totalExpenses = _getTotalExpenses();
    final netBalance = totalIncome - totalExpenses;
    final categorySpending = _getCategorySpending();

    return Scaffold(
      body: Column(
        children: [
          // Period Selector
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border(bottom: BorderSide(color: Colors.orange[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      setState(() {
                        _selectedPeriod = value;
                      });
                    },
                    itemBuilder: (context) => _getPeriodOptions(l10n).map((period) => PopupMenuItem(
                      value: period,
                      child: Text(period),
                    )).toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_selectedPeriod),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  tooltip: l10n.refreshData,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noTransactionsYet,
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.addFirstTransaction,
                          style: TextStyle(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards
                        Text(
                          l10n.spendingOverview,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                l10n.totalIncome,
                                _formatAmount(totalIncome),
                                Icons.trending_up,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                l10n.totalExpenses,
                                _formatAmount(totalExpenses),
                                Icons.trending_down,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        _buildSummaryCard(
                          l10n.netBalance,
                          _formatAmount(netBalance),
                          netBalance >= 0 ? Icons.account_balance_wallet : Icons.warning,
                          netBalance >= 0 ? Colors.blue : Colors.orange,
                        ),

                        const SizedBox(height: 32),

                        // Category Breakdown
                        if (categorySpending.isNotEmpty) ...[
                          Text(
                            l10n.categoryBreakdown,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          ...categorySpending.entries.map((entry) => 
                            _buildCategoryItem(entry.key, entry.value, totalExpenses)
                          ).toList(),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String categoryName, double amount, double totalExpenses) {
    final percentage = totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatAmount(amount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red[400]!),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}