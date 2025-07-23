import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/web_storage_service.dart';
import '../services/enhanced_ml_service.dart';
import '../services/category_service.dart';
import '../services/export_service.dart';
import '../utils/quick_test.dart';
import '../widgets/edit_transaction_dialog.dart';

class TestingScreen extends StatefulWidget {
  const TestingScreen({Key? key}) : super(key: key);

  @override
  State<TestingScreen> createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen> with AutomaticKeepAliveClientMixin {
  late Future<List<Transaction>> _transactionsFuture;
  final List<String> _debugLogs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _addDebugLog(String message) {
    if (mounted) {
      setState(() {
        _debugLogs.insert(0, '${DateTime.now().toIso8601String().substring(11, 19)}: $message');
        if (_debugLogs.length > 30) {
          _debugLogs.removeLast();
        }
      });
    }
    print('🔍 DEBUG: $message');
  }

  void _loadTransactions() {
    setState(() {
      _transactionsFuture = WebStorageService.getTransactions(includeTestData: false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Note: Removed automatic reload to prevent duplications
    // Use the refresh button to manually reload if needed
  }

  Future<void> _testAddTransaction() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    _addDebugLog('🧪 Starting Add Transaction Test');
    
    try {
      _addDebugLog('Step 1: Creating test transaction object');
      final testTransaction = Transaction(
        id: 'debug_test_${DateTime.now().millisecondsSinceEpoch}',
        amount: 25.50,
        description: 'Debug Test Transaction',
        categoryId: 'food',
        date: DateTime.now(),
        type: TransactionType.expense,
        accountId: 'personal',
      );
      _addDebugLog('✅ Transaction object created successfully');

      _addDebugLog('Step 2: Saving to WebStorageService');
      await WebStorageService.addTransaction(testTransaction);
      _addDebugLog('✅ Transaction saved to storage successfully');

      _addDebugLog('Step 3: Verifying transaction was saved');
      final transactions = await WebStorageService.getTransactions();
      final found = transactions.any((t) => t.id == testTransaction.id);
      _addDebugLog(found ? '✅ Transaction found in storage' : '❌ Transaction NOT found in storage');

      _addDebugLog('Step 4: Testing ML service (non-blocking)');
      try {
        await EnhancedMLService.learnFromUserTransaction(testTransaction);
        _addDebugLog('✅ ML service completed successfully');
      } catch (e) {
        _addDebugLog('⚠️ ML service failed: $e');
      }

      _loadTransactions();
      _addDebugLog('🎉 Add Transaction Test COMPLETED');

    } catch (e, stackTrace) {
      _addDebugLog('❌ Add Transaction Test FAILED: $e');
      _addDebugLog('Stack trace: ${stackTrace.toString().substring(0, 100)}...');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testStorageOperations() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    _addDebugLog('🧪 Starting Storage Operations Test');
    
    try {
      _addDebugLog('Testing storage read...');
      final transactions = await WebStorageService.getTransactions();
      _addDebugLog('✅ Read ${transactions.length} transactions');

      _addDebugLog('Testing categories...');
      final categories = await WebStorageService.getCategories();
      _addDebugLog('✅ Read ${categories.length} categories from storage');

      _addDebugLog('Testing CategoryService...');
      final serviceCategories = await CategoryService.getCategories();
      _addDebugLog('✅ CategoryService returned ${serviceCategories.length} categories');

      _addDebugLog('🎉 Storage Operations Test COMPLETED');
    } catch (e) {
      _addDebugLog('❌ Storage Operations Test FAILED: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testFormValidation() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    _addDebugLog('🧪 Starting Form Validation Test');
    
    try {
      _addDebugLog('Testing form validation scenarios...');
      
      // Test 1: Empty form
      _addDebugLog('Test 1: Empty form validation');
      final emptyFormValid = _validateFormData('', '', null);
      _addDebugLog(emptyFormValid ? '❌ Empty form should be invalid' : '✅ Empty form correctly invalid');
      
      // Test 2: Valid form
      _addDebugLog('Test 2: Valid form validation');
      final validFormValid = _validateFormData('25.50', 'Test description', 'food');
      _addDebugLog(validFormValid ? '✅ Valid form correctly valid' : '❌ Valid form should be valid');
      
      // Test 3: Invalid amount
      _addDebugLog('Test 3: Invalid amount validation');
      final invalidAmountValid = _validateFormData('abc', 'Test description', 'food');
      _addDebugLog(invalidAmountValid ? '❌ Invalid amount should be invalid' : '✅ Invalid amount correctly invalid');
      
      _addDebugLog('🎉 Form Validation Test COMPLETED');
    } catch (e) {
      _addDebugLog('❌ Form Validation Test FAILED: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateFormData(String amount, String description, String? categoryId) {
    // Simulate form validation logic
    if (amount.isEmpty || description.isEmpty || categoryId == null) {
      return false;
    }
    
    final parsedAmount = double.tryParse(amount.replaceAll(',', '.'));
    if (parsedAmount == null || parsedAmount <= 0) {
      return false;
    }
    
    return true;
  }

  Future<void> _debugAddTransactionScreen() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    _addDebugLog('🧪 Starting Add Transaction Screen Debug');
    
    try {
      _addDebugLog('Simulating Add Transaction Screen workflow...');
      
      // Simulate the add transaction screen workflow
      _addDebugLog('Step 1: Form initialization');
      await Future.delayed(const Duration(milliseconds: 500));
      _addDebugLog('✅ Form initialized');
      
      _addDebugLog('Step 2: Category loading');
      final categories = await CategoryService.getCategories();
      _addDebugLog('✅ Loaded ${categories.length} categories');
      
      _addDebugLog('Step 3: Form validation test');
      final isValid = _validateFormData('50.00', 'Debug Screen Test', 'food');
      _addDebugLog(isValid ? '✅ Form validation passed' : '❌ Form validation failed');
      
      if (isValid) {
        _addDebugLog('Step 4: Creating transaction from form');
        final transaction = Transaction(
          id: 'debug_screen_test_${DateTime.now().millisecondsSinceEpoch}',
          amount: 50.00,
          description: 'Debug Screen Test',
          categoryId: 'food',
          date: DateTime.now(),
          type: TransactionType.expense,
          accountId: 'personal',
        );
        
        _addDebugLog('Step 5: Saving transaction');
        await WebStorageService.addTransaction(transaction);
        _addDebugLog('✅ Transaction saved successfully');
        
        _loadTransactions();
      }
      
      _addDebugLog('🎉 Add Transaction Screen Debug COMPLETED');
    } catch (e) {
      _addDebugLog('❌ Add Transaction Screen Debug FAILED: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Debug & Testing'),
        backgroundColor: Colors.blue[600]!,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export Transactions',
            onSelected: _handleExport,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'json',
                child: Row(
                  children: [
                    Icon(Icons.code, size: 18),
                    SizedBox(width: 8),
                    Text('Export as JSON'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, size: 18),
                    SizedBox(width: 8),
                    Text('Export as CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.grid_on, size: 18),
                    SizedBox(width: 8),
                    Text('Export as Excel'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Transactions',
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Debug Controls
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔧 Debug Controls',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Debug Buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _testAddTransaction,
                        icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_circle),
                        label: const Text('Test Add Transaction'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600]!,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _testStorageOperations,
                        icon: const Icon(Icons.storage),
                        label: const Text('Test Storage'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600]!,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _testFormValidation,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Test Form Validation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _debugAddTransactionScreen,
                        icon: const Icon(Icons.bug_report),
                        label: const Text('Debug Add Screen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600]!,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _debugLogs.clear();
                          });
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear Logs'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : () async {
                          setState(() {
                            _isLoading = true;
                          });
                          await QuickTest.clearAllData();
                          _loadTransactions();
                          _addDebugLog('🧹 All data cleared');
                          setState(() {
                            _isLoading = false;
                          });
                        },
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Clear All Data'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Debug Logs Section
            if (_debugLogs.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '📋 Debug Logs',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_debugLogs.length} entries',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _debugLogs.length,
                        itemBuilder: (context, index) {
                          final log = _debugLogs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Text(
                              log,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: log.contains('❌') ? Colors.red :
                                       log.contains('⚠️') ? Colors.orange :
                                       log.contains('✅') ? Colors.green :
                                       Colors.black87,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            
            // Transactions List
            Expanded(
              child: FutureBuilder<List<Transaction>>(
                future: _transactionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error loading transactions: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No transactions yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Use the debug buttons above to test!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  final transactions = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final isDebugTest = tx.id.startsWith('debug_test') || tx.id.startsWith('debug_screen_test');
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDebugTest 
                              ? Colors.purple[100] 
                              : (tx.type == TransactionType.income ? Colors.blue[100] : Colors.orange[100]),
                            child: Icon(
                              isDebugTest 
                                ? Icons.bug_report 
                                : (tx.type == TransactionType.income ? Icons.add : Icons.remove),
                              color: isDebugTest 
                                ? Colors.purple[600] 
                                : (tx.type == TransactionType.income ? Colors.blue[600]! : Colors.orange[700]!),
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(tx.description)),
                              if (isDebugTest)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'DEBUG',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '${tx.categoryId.isNotEmpty ? tx.categoryId : "No Category"} • ${_formatDate(tx.date)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${tx.type == TransactionType.income ? "+" : "-"}\$${tx.amount.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: tx.type == TransactionType.income ? Colors.blue[600]! : Colors.orange[700]!,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                          onTap: () => _editTransaction(tx),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _editTransaction(Transaction transaction) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditTransactionDialog(
        transaction: transaction,
        onTransactionUpdated: () {
          _loadTransactions();
        },
        onTransactionDeleted: () {
          _loadTransactions();
        },
      ),
    );
    
    // Reload transactions if dialog returned true (indicating a change was made)
    if (result == true) {
      _loadTransactions();
    }
  }

  Future<void> _handleExport(String format) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting transactions...'),
            ],
          ),
        ),
      );

      // Perform export based on format
      switch (format) {
        case 'json':
          await ExportService.exportToJson();
          break;
        case 'csv':
          await ExportService.exportToCsv();
          break;
        case 'excel':
          await ExportService.exportToExcel();
          break;
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transactions exported as ${format.toUpperCase()} successfully!'),
            backgroundColor: Colors.blue[600]!,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red[700],
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  bool get wantKeepAlive => true;
}