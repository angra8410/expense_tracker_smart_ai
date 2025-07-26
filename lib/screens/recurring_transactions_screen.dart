import 'package:flutter/material.dart';
import '../models/recurring_transaction.dart';
import '../models/category.dart';
import '../services/web_storage_service.dart';
import '../services/recurring_transactions_service.dart';
import '../utils/hero_tag_manager.dart';
import '../widgets/recurring_transaction_dialog.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() => _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState extends State<RecurringTransactionsScreen> {
  List<RecurringTransaction> _recurringTransactions = [];
  List<Category> _categories = [];
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _upcomingTransactions = [];
  bool _isLoading = true;
  bool _showInactive = false;

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
      final recurringTransactions = await WebStorageService.getRecurringTransactions();
      final categories = await WebStorageService.getCategories();
      final summary = await RecurringTransactionsService.getRecurringTransactionsSummary();
      final upcoming = await RecurringTransactionsService.getUpcomingRecurringTransactions();

      setState(() {
        _recurringTransactions = recurringTransactions;
        _categories = categories;
        _summary = summary;
        _upcomingTransactions = upcoming;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _showRecurringTransactionDialog([RecurringTransaction? recurringTransaction]) {
    showDialog(
      context: context,
      builder: (context) => RecurringTransactionDialog(
        recurringTransaction: recurringTransaction,
        onRecurringTransactionUpdated: _loadData,
        onRecurringTransactionDeleted: _loadData,
      ),
    );
  }

  Future<void> _toggleRecurringTransactionStatus(RecurringTransaction recurringTransaction) async {
    try {
      if (recurringTransaction.isActive) {
        await RecurringTransactionsService.pauseRecurringTransaction(recurringTransaction.id);
      } else {
        await RecurringTransactionsService.resumeRecurringTransaction(recurringTransaction.id);
      }
      _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              recurringTransaction.isActive 
                  ? 'Recurring transaction paused' 
                  : 'Recurring transaction resumed'
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  Future<void> _executeRecurringTransaction(RecurringTransaction recurringTransaction) async {
    try {
      final transaction = await RecurringTransactionsService.executeRecurringTransactionById(recurringTransaction.id);
      if (transaction != null) {
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recurring transaction executed successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error executing transaction: $e')),
        );
      }
    }
  }

  String _getCategoryName(String categoryId) {
    try {
      return _categories.firstWhere((cat) => cat.id == categoryId).name;
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getCategoryIcon(String categoryId) {
    try {
      // For now, return a simple emoji representation
      // In a real app, you might want to map specific categories to emojis
      final category = _categories.firstWhere((cat) => cat.id == categoryId);
      // Map common category IDs to emojis
      switch (categoryId) {
        case 'food': return '🍽️';
        case 'transport': return '🚗';
        case 'entertainment': return '🎬';
        case 'shopping': return '🛒';
        case 'bills': return '📄';
        case 'health': return '❤️';
        case 'salary': return '💰';
        default: return '💳';
      }
    } catch (e) {
      return '❓';
    }
  }

  String _getFrequencyText(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
    }
  }

  Widget _buildSummaryCard() {
    if (_summary.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Active',
                    '${_summary['activeRecurringTransactions'] ?? 0}',
                    Colors.green,
                    Icons.play_arrow,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Total',
                    '${_summary['totalRecurringTransactions'] ?? 0}',
                    Colors.blue,
                    Icons.repeat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Monthly Income',
                    '\$${(_summary['estimatedMonthlyIncome'] ?? 0.0).toStringAsFixed(2)}',
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Monthly Expenses',
                    '\$${(_summary['estimatedMonthlyExpenses'] ?? 0.0).toStringAsFixed(2)}',
                    Colors.red,
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryItem(
              'Estimated Monthly Net',
              '\$${(_summary['estimatedMonthlyNet'] ?? 0.0).toStringAsFixed(2)}',
              (_summary['estimatedMonthlyNet'] ?? 0.0) >= 0 ? Colors.green : Colors.red,
              Icons.account_balance,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard() {
    if (_upcomingTransactions.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Upcoming (Next 30 Days)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._upcomingTransactions.take(5).map((upcoming) {
              final rt = upcoming['recurringTransaction'] as RecurringTransaction;
              final nextDate = upcoming['nextExecutionDate'] as DateTime;
              final daysUntil = upcoming['daysUntilExecution'] as int;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: rt.type == 'income' ? Colors.blue[600]! : Colors.orange[700]!,
                  child: Text(_getCategoryIcon(rt.categoryId)),
                ),
                title: Text(rt.description),
                subtitle: Text(
                  '${_getFrequencyText(rt.frequency)} • ${_getCategoryName(rt.categoryId)}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${rt.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rt.type == 'income' ? Colors.blue[600]! : Colors.orange[700]!,
                      ),
                    ),
                    Text(
                      daysUntil == 0 ? 'Today' : '${daysUntil}d',
                      style: const TextStyle(fontSize: 12),
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

  Widget _buildRecurringTransactionCard(RecurringTransaction recurringTransaction) {
    final nextExecution = recurringTransaction.getNextExecutionDate();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: recurringTransaction.isActive
              ? (recurringTransaction.type == 'income' ? Colors.blue[600]! : Colors.orange[700]!)
              : Colors.grey,
          child: Text(_getCategoryIcon(recurringTransaction.categoryId)),
        ),
        title: Text(
          recurringTransaction.description,
          style: TextStyle(
            color: recurringTransaction.isActive ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getFrequencyText(recurringTransaction.frequency)} • ${_getCategoryName(recurringTransaction.categoryId)}',
              style: TextStyle(
                color: recurringTransaction.isActive ? null : Colors.grey,
              ),
            ),
            if (nextExecution != null)
              Text(
                'Next: ${nextExecution.day}/${nextExecution.month}/${nextExecution.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: recurringTransaction.isActive ? Colors.blue : Colors.grey,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${recurringTransaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: recurringTransaction.isActive
                        ? (recurringTransaction.type == 'income' ? Colors.blue[600]! : Colors.orange[700]!)
                        : Colors.grey,
                  ),
                ),
                if (!recurringTransaction.isActive)
                  const Text(
                    'Paused',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showRecurringTransactionDialog(recurringTransaction);
                    break;
                  case 'toggle':
                    _toggleRecurringTransactionStatus(recurringTransaction);
                    break;
                  case 'execute':
                    _executeRecurringTransaction(recurringTransaction);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(recurringTransaction.isActive ? Icons.pause : Icons.play_arrow),
                      const SizedBox(width: 8),
                      Text(recurringTransaction.isActive ? 'Pause' : 'Resume'),
                    ],
                  ),
                ),
                if (recurringTransaction.isActive)
                  const PopupMenuItem(
                    value: 'execute',
                    child: Row(
                      children: [
                        Icon(Icons.play_circle),
                        SizedBox(width: 8),
                        Text('Execute Now'),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: () => _showRecurringTransactionDialog(recurringTransaction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _showInactive
        ? _recurringTransactions
        : _recurringTransactions.where((rt) => rt.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _showInactive = !_showInactive;
              });
            },
            tooltip: _showInactive ? 'Hide Inactive' : 'Show Inactive',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildUpcomingCard(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.repeat),
                      const SizedBox(width: 8),
                      Text(
                        'Recurring Transactions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Text(
                        '${filteredTransactions.length} items',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (filteredTransactions.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.repeat,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _showInactive
                                  ? 'No recurring transactions found'
                                  : 'No active recurring transactions',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create recurring transactions for bills, subscriptions, and regular income.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredTransactions.map(_buildRecurringTransactionCard),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: HeroTagManager.CommonTags.recurringFab,
        onPressed: () => _showRecurringTransactionDialog(),
        tooltip: 'Add Recurring Transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
}