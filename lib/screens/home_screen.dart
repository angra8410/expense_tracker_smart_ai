import 'package:flutter/material.dart';
import 'dart:async';
import '../services/web_storage_service.dart';
import '../services/settings_service.dart';
import '../services/transactions_service.dart';
import '../models/transaction.dart';
import '../widgets/edit_transaction_dialog.dart';
import '../screens/recurring_transactions_screen.dart';
import '../screens/import_screen.dart';
import '../screens/advanced_search_screen.dart';
import '../screens/currency_converter_screen.dart';
import '../utils/category_localization.dart';
import '../utils/hero_tag_manager.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  final String currency;

  const HomeScreen({super.key, this.onNavigateToTab, required this.currency});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  int _transactionCount = 0;
  int _realTransactionCount = 0;
  List<Transaction> _recentTransactions = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _startAutoRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when the screen becomes visible
    _loadDashboardData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  // Temporary localization method
  String _getLocalizedText(String key) {
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    
    switch (key) {
      case 'appTitle': return isSpanish ? '💰 Rastreador Inteligente de Gastos' : '💰 Smart Expense Tracker';
      case 'welcomeBack': return isSpanish ? '👋 ¡Bienvenido de nuevo, angra8410!' : '👋 Welcome back, angra8410!';
      case 'smartFinancial': return isSpanish ? 'Inteligencia financiera inteligente al alcance de tus manos' : 'Smart Financial Intelligence at your fingertips';
      case 'totalIncome': return isSpanish ? 'Ingresos Totales' : 'Total Income';
      case 'totalExpenses': return isSpanish ? 'Gastos Totales' : 'Total Expenses';
      case 'netBalance': return isSpanish ? 'Balance Neto' : 'Net Balance';
      case 'transactions': return isSpanish ? 'Transacciones' : 'Transactions';
      case 'real': return isSpanish ? 'reales' : 'real';
      case 'quickActions': return isSpanish ? '⚡ Acciones Rápidas' : '⚡ Quick Actions';
      case 'addTransaction': return isSpanish ? 'Agregar Transacción' : 'Add Transaction';
      case 'addTransactionDesc': return isSpanish ? 'Registrar nuevo ingreso o gasto' : 'Record new income or expense';
      case 'viewAnalytics': return isSpanish ? 'Ver Análisis' : 'View Analytics';
      case 'viewAnalyticsDesc': return isSpanish ? 'Ver tendencias e insights de gastos' : 'See spending trends and insights';
      case 'aiInsightsDesc': return isSpanish ? 'Inteligencia financiera inteligente' : 'Smart financial intelligence';
      case 'testLab': return isSpanish ? 'Laboratorio de Pruebas' : 'Test Lab';
      case 'testLabDesc': return isSpanish ? 'Generar datos de prueba para IA' : 'Generate test data for AI';
      case 'recurringTransactions': return isSpanish ? 'Transacciones Recurrentes' : 'Recurring Transactions';
      case 'recurringTransactionsDesc': return isSpanish ? 'Gestionar transacciones automáticas' : 'Manage automatic transactions';
      case 'importStatement': return isSpanish ? 'Importar Estado' : 'Import Statement';
      case 'importStatementDesc': return isSpanish ? 'Importar archivo CSV del banco' : 'Import bank statement CSV file';
      case 'searchTransactions': return isSpanish ? 'Buscar Transacciones' : 'Search Transactions';
      case 'searchTransactionsDesc': return isSpanish ? 'Búsqueda avanzada y filtros' : 'Advanced search and filters';
      case 'currencyConverter': return isSpanish ? 'Conversor de Moneda' : 'Currency Converter';
      case 'currencyConverterDesc': return isSpanish ? 'Convertir entre monedas con tasas en vivo' : 'Convert between currencies with live rates';
      case 'home': return isSpanish ? 'Inicio' : 'Home';
      case 'recentTransactions': return isSpanish ? '📊 Transacciones Recientes' : '📊 Recent Transactions';
      case 'viewAll': return isSpanish ? 'Ver Todo' : 'View All';
      case 'noTransactions': return isSpanish ? 'No hay transacciones aún' : 'No transactions yet';
      case 'addFirstTransaction': return isSpanish ? 'Agrega tu primera transacción o genera datos de prueba' : 'Add your first transaction or generate test data';
      case 'testData': return isSpanish ? 'Datos de Prueba' : 'Test Data';
      case 'smartAI': return isSpanish ? '🧠 Inteligencia AI Inteligente' : '🧠 Smart AI Intelligence';
      case 'getIntelligentInsights': return isSpanish ? 'Obtén insights inteligentes sobre tus patrones de gasto' : 'Get intelligent insights into your spending patterns';
      case 'exploreAI': return isSpanish ? 'Explorar Insights de IA' : 'Explore AI Insights';
      case 'refreshData': return isSpanish ? 'Actualizar Datos' : 'Refresh Data';
      default: return key;
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load transactions from both storage services (excluding test data)
      final webTransactions = await WebStorageService.getTransactions(includeTestData: false);
      final localTransactions = await TransactionsService.getTransactions(includeTestData: false);
      
      // Merge transactions from both sources, avoiding duplicates by ID
      final Map<String, Transaction> transactionMap = {};
      
      // Add all web transactions to the map
      for (final tx in webTransactions) {
        transactionMap[tx.id] = tx;
      }
      
      // Add all local transactions to the map (will overwrite duplicates)
      for (final tx in localTransactions) {
        transactionMap[tx.id] = tx;
      }
      
      // Convert map back to list
      final List<Transaction> allTransactions = transactionMap.values.toList();
      
      double income = 0.0;
      double expenses = 0.0;

      for (final transaction in allTransactions) {
        if (transaction.type == TransactionType.income) {
          income += transaction.amount;
        } else {
          expenses += transaction.amount;
        }
      }

      final sortedTransactions = List<Transaction>.from(allTransactions)
        ..sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _totalIncome = income;
        _totalExpenses = expenses;
        _transactionCount = allTransactions.length;
        _realTransactionCount = allTransactions.length; // All transactions are now real
        _recentTransactions = sortedTransactions.take(5).toList();
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatAmount(double amount) {
    return SettingsService.formatCurrency(amount, widget.currency);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_getLocalizedText('appTitle')),
          backgroundColor: Colors.purple[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final netBalance = _totalIncome - _totalExpenses;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[600]!, Colors.purple[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLocalizedText('welcomeBack'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getLocalizedText('smartFinancial'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                                      const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Colombia 🇨🇴 | ${widget.currency} | ${DateTime.now().toString().substring(0, 10)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      IconButton(
                        onPressed: _loadDashboardData,
                        icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                        tooltip: _getLocalizedText('refreshData'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Financial Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      _getLocalizedText('totalIncome'),
                      _formatAmount(_totalIncome),
                      Icons.trending_up,
                      Colors.blue[600]!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      _getLocalizedText('totalExpenses'),
                      _formatAmount(_totalExpenses),
                      Icons.trending_down,
                      Colors.orange[700]!,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      _getLocalizedText('netBalance'),
                      _formatAmount(netBalance),
                      netBalance >= 0 ? Icons.account_balance_wallet : Icons.warning,
                      netBalance >= 0 ? Colors.blue : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      _getLocalizedText('transactions'),
                      '$_transactionCount ($_realTransactionCount ${_getLocalizedText('real')})',
                      Icons.receipt_long,
                      Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Quick Actions Section
              Text(
                _getLocalizedText('quickActions'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Quick Action Cards
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      title: _getLocalizedText('addTransaction'),
                      description: _getLocalizedText('addTransactionDesc'),
                      icon: Icons.add_circle,
                      color: Colors.blue,
                      onTap: () => _navigateToTab(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      title: _getLocalizedText('viewAnalytics'),
                      description: _getLocalizedText('viewAnalyticsDesc'),
                      icon: Icons.analytics,
                      color: Colors.orange,
                      onTap: () => _navigateToTab(2),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      title: _getLocalizedText('searchTransactions'),
                      description: _getLocalizedText('searchTransactionsDesc'),
                      icon: Icons.search,
                      color: Colors.green,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdvancedSearchScreen(currency: widget.currency),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      title: _getLocalizedText('recurringTransactions'),
                      description: _getLocalizedText('recurringTransactionsDesc'),
                      icon: Icons.repeat,
                      color: Colors.deepPurple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecurringTransactionsScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      title: _getLocalizedText('testLab'),
                      description: _getLocalizedText('testLabDesc'),
                      icon: Icons.science,
                      color: Colors.teal,
                      onTap: () => _navigateToTab(5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      title: _getLocalizedText('importStatement'),
                      description: _getLocalizedText('importStatementDesc'),
                      icon: Icons.upload_file,
                      color: Colors.indigo,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ImportScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      title: _getLocalizedText('currencyConverter'),
                      description: _getLocalizedText('currencyConverterDesc'),
                      icon: Icons.currency_exchange,
                      color: Colors.amber[700]!,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CurrencyConverterScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(), // Empty space for symmetry
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Recent Transactions Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getLocalizedText('recentTransactions'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_transactionCount > 5)
                    TextButton(
                      onPressed: () => _navigateToTab(2),
                      child: Text(_getLocalizedText('viewAll')),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Recent Transactions List
              if (_recentTransactions.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        _getLocalizedText('noTransactions'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getLocalizedText('addFirstTransaction'),
                        style: TextStyle(color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _navigateToTab(1),
                            icon: const Icon(Icons.add),
                            label: Text(_getLocalizedText('addTransaction')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600]!,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => _navigateToTab(5),
                            icon: const Icon(Icons.science),
                            label: Text(_getLocalizedText('testData')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ..._recentTransactions.map((transaction) => _buildTransactionCard(transaction)),
              ],

              const SizedBox(height: 24),

              // Smart AI Promotion Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.purple[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          _getLocalizedText('smartAI'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getLocalizedText('getIntelligentInsights'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToTab(3),
                      icon: const Icon(Icons.psychology),
                      label: Text(_getLocalizedText('exploreAI')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.purple[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: HeroTagManager.CommonTags.homeSearchFab,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdvancedSearchScreen(currency: widget.currency),
          ),
        ),
        backgroundColor: Colors.purple[600],
        child: const Icon(Icons.search, color: Colors.white),
        tooltip: _getLocalizedText('searchTransactions'),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isIncome = transaction.type == TransactionType.income;
    final isTestTransaction = transaction.id.startsWith('test_');
    
    return GestureDetector(
      onTap: () => _editTransaction(transaction),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isTestTransaction ? Colors.orange[200]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isIncome ? Colors.blue[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isIncome ? Icons.add_circle : Icons.remove_circle,
                color: isIncome ? Colors.blue[600]! : Colors.orange[700]!,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transaction.description,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isTestTransaction)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'TEST',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700]!,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    transaction.date.toString().substring(0, 10),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${_formatAmount(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isIncome ? Colors.blue[600]! : Colors.orange[700]!,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTransaction(Transaction transaction) async {
    await showDialog(
      context: context,
      builder: (context) => EditTransactionDialog(
        transaction: transaction,
        onTransactionUpdated: () {
          _loadDashboardData();
        },
        onTransactionDeleted: () {
          _loadDashboardData();
        },
      ),
    );
  }

  void _navigateToTab(int tabIndex) {
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(tabIndex);
      
      final tabNames = [_getLocalizedText('home'), _getLocalizedText('addTransaction'), _getLocalizedText('viewAnalytics'), 'AI Insights', _getLocalizedText('testLab')];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚀 ${tabNames[tabIndex]}...'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.purple[600],
        ),
      );
    }
  }

  void _navigateToRecurringTransactions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RecurringTransactionsScreen(),
      ),
    );
  }
}