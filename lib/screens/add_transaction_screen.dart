import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/web_storage_service.dart';
import '../services/app_initialization_service.dart';
import '../services/settings_service.dart';
import 'package:uuid/uuid.dart';

class AddTransactionScreen extends StatefulWidget {
  final String currency;

  const AddTransactionScreen({super.key, required this.currency});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TransactionType _selectedType = TransactionType.expense;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _categoriesLoaded = false;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // Temporary localization method
  String _getLocalizedText(String key) {
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    
    switch (key) {
      case 'newTransaction': return isSpanish ? 'Nueva Transacción' : 'New Transaction';
      case 'addIncomeExpense': return isSpanish ? 'Agregar ingreso o gasto para rastrear con IA Inteligente' : 'Add income or expense to track with Smart AI';
      case 'transactionType': return isSpanish ? 'Tipo de Transacción' : 'Transaction Type';
      case 'expense': return isSpanish ? 'Gasto' : 'Expense';
      case 'income': return isSpanish ? 'Ingreso' : 'Income';
      case 'amount': return isSpanish ? 'Cantidad' : 'Amount';
      case 'description': return isSpanish ? 'Descripción' : 'Description';
      case 'whatWasThisFor': return isSpanish ? '¿Para qué fue esta transacción?' : 'What was this transaction for?';
      case 'category': return isSpanish ? 'Categoría' : 'Category';
      case 'selectCategory': return isSpanish ? 'Selecciona una categoría' : 'Select a category';
      case 'date': return isSpanish ? 'Fecha' : 'Date';
      case 'pleaseEnterAmount': return isSpanish ? 'Por favor ingresa una cantidad' : 'Please enter an amount';
      case 'pleaseEnterValidAmount': return isSpanish ? 'Por favor ingresa una cantidad válida' : 'Please enter a valid amount';
      case 'pleaseEnterDescription': return isSpanish ? 'Por favor ingresa una descripción' : 'Please enter a description';
      case 'pleaseSelectCategory': return isSpanish ? 'Por favor selecciona una categoría' : 'Please select a category';
      case 'saving': return isSpanish ? 'Guardando...' : 'Saving...';
      case 'addExpense': return isSpanish ? 'Agregar Gasto' : 'Add Expense';
      case 'addIncome': return isSpanish ? 'Agregar Ingreso' : 'Add Income';
      case 'loadingCategories': return isSpanish ? 'Cargando categorías...' : 'Loading categories...';
      case 'readyTransactions': return isSpanish ? '¡Listo! {count} categorías cargadas' : 'Ready! {count} categories loaded';
      default: return key;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await AppInitializationService.getCategories();
      setState(() {
        _categories = categories;
        _categoriesLoaded = true;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _categoriesLoaded = true;
      });
    }
  }

  String _formatAmount(double amount) {
    return SettingsService.formatCurrency(amount, widget.currency);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getLocalizedText('newTransaction')),
        backgroundColor: _selectedType == TransactionType.expense 
            ? Colors.red[700] 
            : Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _selectedType == TransactionType.expense
                      ? [Colors.red[600]!, Colors.red[400]!]
                      : [Colors.green[600]!, Colors.green[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (_selectedType == TransactionType.expense ? Colors.red : Colors.green).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _selectedType == TransactionType.expense 
                            ? Icons.remove_circle 
                            : Icons.add_circle,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getLocalizedText('newTransaction'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getLocalizedText('addIncomeExpense'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Colombia 🇨🇴 | ${widget.currency} | Usuario: angra8410',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Type Section
                  Text(
                    _getLocalizedText('transactionType'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = TransactionType.expense;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _selectedType == TransactionType.expense
                                  ? Colors.red[100]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedType == TransactionType.expense
                                    ? Colors.red[300]!
                                    : Colors.grey[300]!,
                                width: _selectedType == TransactionType.expense ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.remove_circle,
                                  color: _selectedType == TransactionType.expense
                                      ? Colors.red[600]
                                      : Colors.grey[600],
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getLocalizedText('expense'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedType == TransactionType.expense
                                        ? Colors.red[600]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = TransactionType.income;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _selectedType == TransactionType.income
                                  ? Colors.green[100]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedType == TransactionType.income
                                    ? Colors.green[300]!
                                    : Colors.grey[300]!,
                                width: _selectedType == TransactionType.income ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.add_circle,
                                  color: _selectedType == TransactionType.income
                                      ? Colors.green[600]
                                      : Colors.grey[600],
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getLocalizedText('income'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedType == TransactionType.income
                                        ? Colors.green[600]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Amount Field
                  Text(
                    '${_getLocalizedText('amount')} (${widget.currency})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: widget.currency == 'COP' ? '1.500' : '1.50',
                      prefixText: SettingsService.getCurrencySymbol(widget.currency) + ' ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _selectedType == TransactionType.expense
                              ? Colors.red[600]!
                              : Colors.green[600]!,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _getLocalizedText('pleaseEnterAmount');
                      }
                      if (double.tryParse(value.replaceAll(',', '.')) == null) {
                        return _getLocalizedText('pleaseEnterValidAmount');
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Description Field
                  Text(
                    _getLocalizedText('description'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: _getLocalizedText('whatWasThisFor'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _selectedType == TransactionType.expense
                              ? Colors.red[600]!
                              : Colors.green[600]!,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _getLocalizedText('pleaseEnterDescription');
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Category Field
                  Text(
                    _getLocalizedText('category'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_categoriesLoaded) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(_getLocalizedText('loadingCategories')),
                        ],
                      ),
                    ),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        hintText: _getLocalizedText('selectCategory'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _selectedType == TransactionType.expense
                                ? Colors.red[600]!
                                : Colors.green[600]!,
                            width: 2,
                          ),
                        ),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category.id,
                          child: Row(
                            children: [
                              Icon(
                                category.icon,
                                color: category.color,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(category.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _getLocalizedText('pleaseSelectCategory');
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Date Field
                  Text(
                    _getLocalizedText('date'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            _selectedDate.toString().substring(0, 10),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveTransaction,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(_selectedType == TransactionType.expense
                              ? Icons.remove_circle
                              : Icons.add_circle),
                      label: Text(_isLoading
                          ? _getLocalizedText('saving')
                          : _selectedType == TransactionType.expense
                              ? _getLocalizedText('addExpense')
                              : _getLocalizedText('addIncome')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedType == TransactionType.expense
                            ? Colors.red[600]
                            : Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status Card
                  if (_categoriesLoaded) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getLocalizedText('readyTransactions').replaceAll('{count}', _categories.length.toString()),
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final amount = double.parse(_amountController.text.replaceAll(',', '.'));
        final description = _descriptionController.text;

        final transaction = Transaction(
          id: const Uuid().v4(),
          amount: amount,
          description: description,
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          type: _selectedType,
          accountId: 'personal',
        );

        await WebStorageService.addTransaction(transaction);
        print('✅ Debug: Transaction saved successfully - ${transaction.description} (${transaction.amount})');

        if (mounted) {
          final isSpanish = Localizations.localeOf(context).languageCode == 'es';
          final successMessage = _selectedType == TransactionType.expense
              ? (isSpanish ? 'Gasto de ${_formatAmount(amount)} agregado!' : 'Expense of ${_formatAmount(amount)} added!')
              : (isSpanish ? 'Ingreso de ${_formatAmount(amount)} agregado!' : 'Income of ${_formatAmount(amount)} added!');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $successMessage'),
              backgroundColor: _selectedType == TransactionType.expense 
                  ? Colors.red[600] 
                  : Colors.green[600],
            ),
          );

          // Clear form
          _amountController.clear();
          _descriptionController.clear();
          setState(() {
            _selectedCategoryId = null;
            _selectedDate = DateTime.now();
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Colors.red[600],
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}