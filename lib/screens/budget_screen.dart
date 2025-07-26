import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/budget_service.dart';
import '../services/budget_notification_service.dart';
import '../services/category_service.dart';
import '../services/settings_service.dart';
import '../services/web_storage_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/category_localization.dart';
import '../utils/data_debug_helper.dart';
import '../utils/hero_tag_manager.dart';

class BudgetScreen extends StatefulWidget {
  final String currency;
  
  const BudgetScreen({super.key, required this.currency});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> with WidgetsBindingObserver {
  List<Budget> _budgets = [];
  List<BudgetRecommendation> _recommendations = [];
  List<Category> _categories = [];
  List<BudgetProgress> _budgetProgress = [];
  bool _isLoading = true;
  DateTime _lastRefresh = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Register for budget update notifications
    BudgetNotificationService.addBudgetUpdateListener(_onBudgetUpdateNotification);
    
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // Unregister from budget update notifications
    BudgetNotificationService.removeBudgetUpdateListener(_onBudgetUpdateNotification);
    
    super.dispose();
  }

  /// Called when transactions change and budgets need to be refreshed
  void _onBudgetUpdateNotification() {
    if (mounted) {
      print('🔄 Budget screen received update notification, refreshing data...');
      _loadData();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app comes back to foreground or becomes visible
    if (state == AppLifecycleState.resumed && mounted) {
      // Only refresh if it's been more than 1 second since last refresh
      // to avoid excessive refreshing
      if (DateTime.now().difference(_lastRefresh).inSeconds > 1) {
        _loadData();
      }
    }
  }

  Future<void> _loadData() async {
    try {
      print('🔄 _loadData called at ${DateTime.now()}');
      setState(() => _isLoading = true);
      
      final budgets = await BudgetService.getActiveBudgets();
      final recommendations = await BudgetService.getBudgetRecommendations();
      final categories = await CategoryService.getCategories();
      
      // Calculate budget progress for each budget
      final budgetProgress = <BudgetProgress>[];
      for (final budget in budgets) {
        final progress = await BudgetService.getBudgetProgress(budget);
        budgetProgress.add(progress);
      }
      
      if (mounted) {
        setState(() {
          _budgets = budgets;
          _recommendations = recommendations;
          _categories = categories;
          _budgetProgress = budgetProgress;
          _isLoading = false;
          _lastRefresh = DateTime.now();
        });
        print('✅ Budget data refreshed successfully. Total spent across all budgets: ${budgetProgress.fold(0.0, (sum, p) => sum + p.spent)}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingData)),
        );
      }
    }
  }

  // Alias for _loadData to match the expected method name
  Future<void> _loadBudgets() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadBudgets,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Budget Overview
                    _buildBudgetOverview(l10n),
                    const SizedBox(height: 24),
                    
                    // Active Budgets
                    _buildActiveBudgets(l10n),
                    const SizedBox(height: 24),
                    
                    // Smart Recommendations
                    _buildSmartRecommendations(l10n),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: HeroTagManager.CommonTags.budgetFab,
        onPressed: () => _showCreateBudgetDialog(),
        icon: const Icon(Icons.add),
        label: Text(l10n.createBudget),
      ),
    );
  }

  Widget _buildBudgetOverview(AppLocalizations l10n) {
    final totalBudget = _budgetProgress.fold<double>(
      0.0, 
      (sum, progress) => sum + progress.budget.totalBudgetAmount,
    );
    final totalSpent = _budgetProgress.fold<double>(
      0.0, 
      (sum, progress) => sum + progress.spent,
    );
    final remaining = totalBudget - totalSpent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.budgetOverview,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: _isLoading ? null : _loadData,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: l10n.refreshData,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_budgetProgress.isEmpty)
              Text(
                l10n.noBudgetsYet,
                style: TextStyle(color: Colors.grey[600]),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildOverviewItem(l10n.totalBudget, totalBudget, Colors.blue),
                  _buildOverviewItem(l10n.totalSpent, totalSpent, Colors.orange),
                  _buildOverviewItem(l10n.remaining, remaining, Colors.green),
                ],
              ),
              const SizedBox(height: 16),
              
              LinearProgressIndicator(
                value: totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  totalSpent > totalBudget ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${((totalSpent / totalBudget) * 100).toStringAsFixed(1)}% ${l10n.used}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          SettingsService.formatCurrency(amount, widget.currency),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildActiveBudgets(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.activeBudgets,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            IconButton(
              onPressed: () => _showCreateBudgetDialog(),
              icon: const Icon(Icons.add_circle_outline),
              tooltip: l10n.createBudget,
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_budgetProgress.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noBudgetsYet,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.createFirstBudget,
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...(_budgetProgress.map((progress) => _buildBudgetCard(progress, l10n)).toList()),
      ],
    );
  }

  Widget _buildBudgetCard(BudgetProgress progress, AppLocalizations l10n) {
    final budget = progress.budget;
    
    final category = _categories.firstWhere(
      (c) => c.id == budget.categoryId,
      orElse: () => Category(
        id: budget.categoryId,
        name: 'Unknown',
        iconCodePoint: Icons.help_outline.codePoint,
        colorValue: Colors.grey.value,
      ),
    );

    Color statusColor;
    String statusText;
    switch (progress.status) {
      case BudgetStatus.onTrack:
        statusColor = Colors.green;
        statusText = l10n.onTrack;
        break;
      case BudgetStatus.warning:
        statusColor = Colors.orange;
        statusText = l10n.warning;
        break;
      case BudgetStatus.exceeded:
        statusColor = Colors.red;
        statusText = l10n.exceeded;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(category.icon, color: category.color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        CategoryLocalization.getLocalizedCategoryNameFromCategory(context, category),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditBudgetDialog(budget);
                        break;
                      case 'delete':
                        _showDeleteConfirmation(budget);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.edit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Status and rollover indicators
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (budget.rolloverEnabled) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      l10n.rolloverEnabled,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            
            // Budget amounts with rollover info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${SettingsService.formatCurrency(progress.spent, widget.currency)} ${l10n.spent}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (budget.rolloverAmount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '+ ${SettingsService.formatCurrency(budget.rolloverAmount, widget.currency)} rollover',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${SettingsService.formatCurrency(budget.totalBudgetAmount, widget.currency)} ${l10n.budgeted}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Progress bar
            LinearProgressIndicator(
              value: progress.percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
            const SizedBox(height: 8),
            
            Text(
              '${progress.percentage.toStringAsFixed(1)}% ${l10n.used}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add these new methods to the BudgetScreenState class:

  Future<void> _showEditBudgetDialog(Budget budget) async {
    await showDialog(
      context: context,
      builder: (context) => _EditBudgetDialog(
        budget: budget,
        currency: widget.currency,
        onBudgetUpdated: _loadData,
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Budget budget) async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteBudget),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.confirmDeleteBudgetMessage),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${budget.name} - ${SettingsService.formatCurrency(budget.amount, widget.currency)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteBudget(budget);
    }
  }

  Future<void> _deleteBudget(Budget budget) async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      await BudgetService.deleteBudget(budget.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.budgetDeleted)),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting budget: $e')),
        );
      }
    }
  }

  Widget _buildSmartRecommendations(AppLocalizations l10n) {
    if (_recommendations.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.smartBudgetRecommendations,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        
        ...(_recommendations.map((recommendation) => _buildRecommendationCard(recommendation, l10n)).toList()),
      ],
    );
  }

  Widget _buildRecommendationCard(BudgetRecommendation recommendation, AppLocalizations l10n) {
    // Find category name
    final category = _categories.firstWhere(
      (cat) => cat.id == recommendation.categoryId,
      orElse: () => Category(
        id: recommendation.categoryId,
        name: 'Unknown Category',
        iconCodePoint: Icons.category.codePoint,
        colorValue: Colors.grey.value,
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                category.icon,
                color: category.color,
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CategoryLocalization.getLocalizedCategoryNameFromCategory(context, category),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${SettingsService.formatCurrency(recommendation.suggestedAmount, widget.currency)} ${l10n.suggested}',
                    style: const TextStyle(color: Colors.blue),
                  ),
                  Text(
                    recommendation.reasoning,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            ElevatedButton(
              onPressed: () => _createSmartBudget(recommendation),
              child: Text(l10n.create),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(double percentage) {
    if (percentage >= 100) return Colors.red;
    if (percentage >= 80) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText(BudgetStatus status, AppLocalizations l10n) {
    switch (status) {
      case BudgetStatus.onTrack:
        return l10n.onTrack;
      case BudgetStatus.warning:
        return l10n.warning;
      case BudgetStatus.exceeded:
        return l10n.exceeded;
    }
  }

  Future<void> _showCreateBudgetDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _CreateBudgetDialog(
        currency: widget.currency,
        onBudgetCreated: _loadBudgets,
      ),
    );
  }

  Future<void> _createSmartBudget(BudgetRecommendation recommendation) async {
    try {
      await BudgetService.createSmartBudget(recommendation);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.budgetCreated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingData)),
        );
      }
    }
  }
}

class _CreateBudgetDialog extends StatefulWidget {
  final String currency;
  final VoidCallback onBudgetCreated;

  const _CreateBudgetDialog({
    required this.currency,
    required this.onBudgetCreated,
  });

  @override
  State<_CreateBudgetDialog> createState() => _CreateBudgetDialogState();
}

class _CreateBudgetDialogState extends State<_CreateBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedCategoryId;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  bool _rolloverEnabled = false;
  bool _includeHistoricalData = true;
  List<Category> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryService.getCategories();
      setState(() => _categories = categories);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingData)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Text(l10n.createBudget),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.budgetName,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterBudgetName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: '${l10n.amount} (${SettingsService.getCurrencySymbol(widget.currency)})',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterAmount;
                  }
                  if (double.tryParse(value) == null) {
                    return l10n.pleaseEnterValidAmount;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: l10n.category,
                  border: const OutlineInputBorder(),
                ),
                items: _categories.map((category) => DropdownMenuItem(
                  value: category.id,
                  child: Row(
                    children: [
                      Icon(category.icon, color: category.color, size: 20),
                      const SizedBox(width: 8),
                      Text(CategoryLocalization.getLocalizedCategoryNameFromCategory(context, category)),
                    ],
                  ),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return l10n.pleaseSelectCategory;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<BudgetPeriod>(
                value: _selectedPeriod,
                decoration: InputDecoration(
                  labelText: l10n.budgetPeriod,
                  border: const OutlineInputBorder(),
                ),
                items: BudgetPeriod.values.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(_getPeriodText(period, l10n)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Include Historical Data Toggle
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _includeHistoricalData ? Icons.history : Icons.today,
                          color: _includeHistoricalData ? Colors.blue : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Include existing transactions',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Switch(
                          value: _includeHistoricalData,
                          onChanged: (value) {
                            setState(() {
                              _includeHistoricalData = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _includeHistoricalData 
                        ? 'Budget will include transactions added before budget creation'
                        : 'Budget will only track transactions from today forward',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Rollover Toggle
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _rolloverEnabled ? Icons.autorenew : Icons.block,
                          color: _rolloverEnabled ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.enableRollover,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Switch(
                          value: _rolloverEnabled,
                          onChanged: (value) {
                            setState(() {
                              _rolloverEnabled = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.rolloverDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createBudget,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.create),
        ),
      ],
    );
  }

  String _getPeriodText(BudgetPeriod period, AppLocalizations l10n) {
    switch (period) {
      case BudgetPeriod.weekly:
        return l10n.weekly;
      case BudgetPeriod.monthly:
        return l10n.monthly;
      case BudgetPeriod.yearly:
        return l10n.yearly;
    }
  }

  Future<void> _createBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      DateTime startDate;
      
      if (_includeHistoricalData && _selectedCategoryId != null) {
        // Get existing transactions for this category to determine appropriate start date
        final transactions = await WebStorageService.getTransactions();
        final categoryTransactions = transactions.where((t) => 
          t.categoryId == _selectedCategoryId && t.type == TransactionType.expense
        ).toList();
        
        if (categoryTransactions.isNotEmpty) {
          // Sort transactions by date and get the earliest one
          categoryTransactions.sort((a, b) => a.date.compareTo(b.date));
          final earliestDate = categoryTransactions.first.date;
          
          // Start from the beginning of the period that contains the earliest transaction
          switch (_selectedPeriod) {
            case BudgetPeriod.weekly:
              // Start from the beginning of the week containing the earliest transaction
              final daysFromMonday = earliestDate.weekday - 1;
              startDate = DateTime(earliestDate.year, earliestDate.month, earliestDate.day - daysFromMonday);
              break;
            case BudgetPeriod.monthly:
              // Start from the beginning of the month containing the earliest transaction
              startDate = DateTime(earliestDate.year, earliestDate.month, 1);
              break;
            case BudgetPeriod.yearly:
              // Start from the beginning of the year containing the earliest transaction
              startDate = DateTime(earliestDate.year, 1, 1);
              break;
          }
        } else {
          // No existing transactions, start from today
          final now = DateTime.now();
          startDate = DateTime(now.year, now.month, now.day);
        }
      } else {
        // Start from the beginning of the current day
        final now = DateTime.now();
        startDate = DateTime(now.year, now.month, now.day);
      }
      
      final budget = Budget(
        id: 'budget_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text,
        amount: double.parse(_amountController.text),
        categoryId: _selectedCategoryId!,
        period: _selectedPeriod,
        startDate: startDate,
        endDate: _calculateEndDate(startDate, _selectedPeriod),
        isActive: true,
        rolloverEnabled: _rolloverEnabled,
        rolloverAmount: 0.0,
      );

      await BudgetService.updateBudget(budget);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.budgetCreated)),
        );
        widget.onBudgetCreated();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating budget: $e')),
        );
      }
    }
  }

  DateTime _calculateEndDate(DateTime startDate, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return startDate.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case BudgetPeriod.yearly:
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}

// Add the missing _EditBudgetDialog class
class _EditBudgetDialog extends StatefulWidget {
  final Budget budget;
  final String currency;
  final VoidCallback onBudgetUpdated;

  const _EditBudgetDialog({
    required this.budget,
    required this.currency,
    required this.onBudgetUpdated,
  });

  @override
  State<_EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends State<_EditBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late String? _selectedCategoryId;
  late BudgetPeriod _selectedPeriod;
  late bool _rolloverEnabled;
  List<Category> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.budget.name);
    _amountController = TextEditingController(text: widget.budget.amount.toString());
    _selectedCategoryId = widget.budget.categoryId;
    _selectedPeriod = widget.budget.period;
    _rolloverEnabled = widget.budget.rolloverEnabled;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryService.getCategories();
      setState(() => _categories = categories);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingData)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Text(l10n.editBudget),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.budgetName,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterBudgetName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: '${l10n.amount} (${SettingsService.getCurrencySymbol(widget.currency)})',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterAmount;
                  }
                  if (double.tryParse(value) == null) {
                    return l10n.pleaseEnterValidAmount;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: l10n.category,
                  border: const OutlineInputBorder(),
                ),
                items: _categories.map((category) => DropdownMenuItem(
                  value: category.id,
                  child: Row(
                    children: [
                      Icon(category.icon, color: category.color, size: 20),
                      const SizedBox(width: 8),
                      Text(CategoryLocalization.getLocalizedCategoryNameFromCategory(context, category)),
                    ],
                  ),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return l10n.pleaseSelectCategory;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<BudgetPeriod>(
                value: _selectedPeriod,
                decoration: InputDecoration(
                  labelText: l10n.budgetPeriod,
                  border: const OutlineInputBorder(),
                ),
                items: BudgetPeriod.values.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(_getPeriodText(period, l10n)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Rollover Toggle
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _rolloverEnabled ? Icons.autorenew : Icons.block,
                          color: _rolloverEnabled ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.enableRollover,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Switch(
                          value: _rolloverEnabled,
                          onChanged: (value) {
                            setState(() {
                              _rolloverEnabled = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.rolloverDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateBudget,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.updateBudget),
        ),
      ],
    );
  }

  String _getPeriodText(BudgetPeriod period, AppLocalizations l10n) {
    switch (period) {
      case BudgetPeriod.weekly:
        return l10n.weekly;
      case BudgetPeriod.monthly:
        return l10n.monthly;
      case BudgetPeriod.yearly:
        return l10n.yearly;
    }
  }

  Future<void> _updateBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedBudget = widget.budget.copyWith(
        name: _nameController.text,
        amount: double.parse(_amountController.text),
        categoryId: _selectedCategoryId!,
        period: _selectedPeriod,
        rolloverEnabled: _rolloverEnabled,
        endDate: _calculateEndDate(widget.budget.startDate, _selectedPeriod),
      );

      await BudgetService.updateBudget(updatedBudget);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.budgetUpdated)),
        );
        widget.onBudgetUpdated();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating budget: $e')),
        );
      }
    }
  }

  DateTime _calculateEndDate(DateTime startDate, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return startDate.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case BudgetPeriod.yearly:
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}