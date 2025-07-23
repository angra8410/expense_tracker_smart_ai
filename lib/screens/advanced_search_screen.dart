import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/web_storage_service.dart';
import '../services/transactions_service.dart';
import '../services/settings_service.dart';
import '../widgets/advanced_search_filters.dart';
import '../widgets/edit_transaction_dialog.dart';

class AdvancedSearchScreen extends StatefulWidget {
  final String currency;

  const AdvancedSearchScreen({super.key, required this.currency});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];
  SearchFilters _currentFilters = SearchFilters();
  bool _isLoading = true;
  List<String> _availableCategories = [];
  List<String> _availableTags = [];
  double _minAmount = 0.0;
  double _maxAmount = 10000.0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load transactions from both storage services
      final webTransactions = await WebStorageService.getTransactions();
      final localTransactions = await TransactionsService.getTransactions();
      
      // Merge transactions from both sources, avoiding duplicates by ID
      final Map<String, Transaction> transactionMap = {};
      
      for (final tx in webTransactions) {
        transactionMap[tx.id] = tx;
      }
      
      for (final tx in localTransactions) {
        transactionMap[tx.id] = tx;
      }
      
      final allTransactions = transactionMap.values.toList();
      
      // Extract unique categories and tags
      final categories = <String>{};
      final tags = <String>{};
      double minAmt = double.infinity;
      double maxAmt = 0.0;
      
      for (final transaction in allTransactions) {
        categories.add(transaction.categoryId);
        
        // Extract tags from description (words starting with #)
        final words = transaction.description.split(' ');
        for (final word in words) {
          if (word.startsWith('#') && word.length > 1) {
            tags.add(word.substring(1));
          }
        }
        
        if (transaction.amount < minAmt) minAmt = transaction.amount;
        if (transaction.amount > maxAmt) maxAmt = transaction.amount;
      }

      setState(() {
        _allTransactions = allTransactions;
        _filteredTransactions = allTransactions;
        _availableCategories = categories.toList()..sort();
        _availableTags = tags.toList()..sort();
        _minAmount = minAmt == double.infinity ? 0.0 : minAmt;
        _maxAmount = maxAmt == 0.0 ? 10000.0 : maxAmt;
      });
      
      _applyFilters();
    } catch (e) {
      print('Error loading transactions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Transaction> filtered = List.from(_allTransactions);

    // Apply search query filter
    if (_currentFilters.searchQuery?.isNotEmpty ?? false) {
      final query = _currentFilters.searchQuery!.toLowerCase();
      filtered = filtered.where((transaction) {
        return transaction.description.toLowerCase().contains(query) ||
               transaction.categoryId.toLowerCase().contains(query) ||
               transaction.amount.toString().contains(query);
      }).toList();
    }

    // Apply date range filter
    if (_currentFilters.dateRange != null) {
      filtered = filtered.where((transaction) {
        return transaction.date.isAfter(_currentFilters.dateRange!.start.subtract(const Duration(days: 1))) &&
               transaction.date.isBefore(_currentFilters.dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Apply amount range filter
    if (_currentFilters.amountRange != null) {
      filtered = filtered.where((transaction) {
        return transaction.amount >= _currentFilters.amountRange!.start &&
               transaction.amount <= _currentFilters.amountRange!.end;
      }).toList();
    }

    // Apply transaction type filter
    if (_currentFilters.selectedTypes.isNotEmpty) {
      filtered = filtered.where((transaction) {
        return _currentFilters.selectedTypes.contains(transaction.type);
      }).toList();
    }

    // Apply category filter
    if (_currentFilters.selectedCategories.isNotEmpty) {
      filtered = filtered.where((transaction) {
        return _currentFilters.selectedCategories.contains(transaction.categoryId);
      }).toList();
    }

    // Apply tags filter
    if (_currentFilters.selectedTags.isNotEmpty) {
      filtered = filtered.where((transaction) {
        final words = transaction.description.split(' ');
        final transactionTags = words
            .where((word) => word.startsWith('#') && word.length > 1)
            .map((word) => word.substring(1))
            .toSet();
        
        return _currentFilters.selectedTags.any((tag) => transactionTags.contains(tag));
      }).toList();
    }

    // Apply sorting
    switch (_currentFilters.sortBy) {
      case 'date':
        filtered.sort((a, b) => _currentFilters.sortAscending 
            ? a.date.compareTo(b.date) 
            : b.date.compareTo(a.date));
        break;
      case 'amount':
        filtered.sort((a, b) => _currentFilters.sortAscending 
            ? a.amount.compareTo(b.amount) 
            : b.amount.compareTo(a.amount));
        break;
      case 'category':
        filtered.sort((a, b) => _currentFilters.sortAscending 
            ? a.categoryId.compareTo(b.categoryId) 
            : b.categoryId.compareTo(a.categoryId));
        break;
    }

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  void _onFiltersChanged(SearchFilters newFilters) {
    setState(() {
      _currentFilters = newFilters;
    });
    _applyFilters();
  }

  String _formatAmount(double amount) {
    return SettingsService.formatCurrency(amount, widget.currency);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Advanced Search'),
        backgroundColor: Colors.blue[600]!,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: AdvancedSearchFilters(
              initialFilters: _currentFilters,
              onFiltersChanged: _onFiltersChanged,
              availableCategories: _availableCategories,
              availableTags: _availableTags,
              minAmount: _minAmount,
              maxAmount: _maxAmount,
            ),
          ),

          // Results Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredTransactions.length} of ${_allTransactions.length} transactions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                if (_filteredTransactions.isNotEmpty)
                  Text(
                    'Total: ${_formatAmount(_filteredTransactions.fold(0.0, (sum, t) => sum + (t.type == TransactionType.income ? t.amount : -t.amount)))}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _filteredTransactions.fold(0.0, (sum, t) => sum + (t.type == TransactionType.income ? t.amount : -t.amount)) >= 0
                          ? Colors.blue[600]!
                          : Colors.orange[700]!,
                    ),
                  ),
              ],
            ),
          ),

          // Results List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _currentFilters.isEmpty 
                ? 'No transactions found'
                : 'No transactions match your filters',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentFilters.isEmpty 
                ? 'Add some transactions to get started'
                : 'Try adjusting your search criteria',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          if (!_currentFilters.isEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _onFiltersChanged(SearchFilters());
              },
              child: const Text('Clear All Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome ? Colors.blue[600]! : Colors.orange[700]!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: amountColor.withOpacity(0.1),
          child: Icon(
            isIncome ? Icons.trending_up : Icons.trending_down,
            color: amountColor,
          ),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${transaction.categoryId} • ${transaction.date.toString().split(' ')[0]}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            // Show tags if any
            if (transaction.description.contains('#')) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: transaction.description
                    .split(' ')
                    .where((word) => word.startsWith('#') && word.length > 1)
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange[700],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'}${_formatAmount(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: amountColor,
                fontSize: 16,
              ),
            ),
            Text(
              transaction.date.toString().split(' ')[1].substring(0, 5),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () => _showTransactionDetails(transaction),
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(transaction.description),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', transaction.type == TransactionType.income ? 'Income' : 'Expense'),
            _buildDetailRow('Amount', _formatAmount(transaction.amount)),
            _buildDetailRow('Category', transaction.categoryId),
            _buildDetailRow('Date', transaction.date.toString().split(' ')[0]),
            _buildDetailRow('Time', transaction.date.toString().split(' ')[1].substring(0, 8)),
            if (transaction.description.contains('#'))
              _buildDetailRow('Tags', transaction.description
                  .split(' ')
                  .where((word) => word.startsWith('#') && word.length > 1)
                  .join(', ')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _editTransaction(transaction);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _editTransaction(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => EditTransactionDialog(
        transaction: transaction,
        onTransactionUpdated: () {
          _loadTransactions(); // Reload transactions after edit
        },
      ),
    );
  }
}