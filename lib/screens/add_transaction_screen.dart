import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/web_storage_service.dart';
import '../l10n/app_localizations.dart';

class AddTransactionScreen extends StatefulWidget {
  final String currency;

  const AddTransactionScreen({Key? key, required this.currency}) : super(key: key);

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
  bool _isSaving = false;
  
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _getLocalizedText(String key) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      // Fallback values
      switch (key) {
        case 'addExpense': return 'Add Expense';
        case 'addIncome': return 'Add Income';
        case 'amount': return 'Amount';
        case 'description': return 'Description';
        case 'category': return 'Category';
        case 'date': return 'Date';
        case 'save': return 'Save';
        case 'cancel': return 'Cancel';
        default: return key;
      }
    }
    
    switch (key) {
      case 'addExpense': return 'Add Expense'; // Fallback since it's missing from localizations
      case 'addIncome': return 'Add Income'; // Fallback since it's missing from localizations
      case 'amount': return localizations.amount;
      case 'description': return localizations.description;
      case 'category': return localizations.category;
      case 'date': return localizations.date;
      case 'save': return localizations.save;
      case 'cancel': return localizations.cancel;
      default: return key;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await WebStorageService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedType == TransactionType.expense 
            ? _getLocalizedText('addExpense')
            : _getLocalizedText('addIncome')),
        backgroundColor: _selectedType == TransactionType.expense 
            ? Colors.red[600] 
            : Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Transaction Type Toggle
          Container(
            width: double.infinity,
            color: _selectedType == TransactionType.expense 
                ? Colors.red[600] 
                : Colors.green[600],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedType = TransactionType.expense;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedType == TransactionType.expense 
                            ? Colors.white 
                            : Colors.transparent,
                        foregroundColor: _selectedType == TransactionType.expense 
                            ? Colors.red[600] 
                            : Colors.white,
                        elevation: _selectedType == TransactionType.expense ? 2 : 0,
                        side: BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(_getLocalizedText('addExpense')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedType = TransactionType.income;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedType == TransactionType.income 
                            ? Colors.white 
                            : Colors.transparent,
                        foregroundColor: _selectedType == TransactionType.income 
                            ? Colors.green[600] 
                            : Colors.white,
                        elevation: _selectedType == TransactionType.income ? 2 : 0,
                        side: BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(_getLocalizedText('addIncome')),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: '${_getLocalizedText('amount')} (${widget.currency})',
                        prefixIcon: Icon(
                          _selectedType == TransactionType.expense 
                              ? Icons.remove_circle_outline 
                              : Icons.add_circle_outline,
                          color: _selectedType == TransactionType.expense 
                              ? Colors.red[600] 
                              : Colors.green[600],
                        ),
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
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value.replaceAll(',', '.'));
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: _getLocalizedText('description'),
                        prefixIcon: Icon(Icons.description, color: Colors.grey[600]),
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
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: _getLocalizedText('category'),
                        prefixIcon: Icon(Icons.category, color: Colors.grey[600]),
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
                              Icon(category.icon, size: 20),
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
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey.shade600),
                            const SizedBox(width: 12),
                            Text(
                              '${_getLocalizedText('date')}: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // Save Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveTransaction,
              child: _isSaving
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Saving...'),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_selectedType == TransactionType.expense ? Icons.remove_circle : Icons.add_circle),
                        SizedBox(width: 8),
                        Text(
                          _selectedType == TransactionType.expense
                              ? _getLocalizedText('addExpense')
                              : _getLocalizedText('addIncome'),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedType == TransactionType.expense ? Colors.red[600] : Colors.green[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTransaction() async {
    print('💾 Save transaction button pressed');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      print('📝 Creating transaction object...');
      
      // Parse amount
      final amountText = _amountController.text.replaceAll(',', '.');
      final amount = double.parse(amountText);
      print('💰 Amount parsed: $amount');

      // Create transaction
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId!,
        type: _selectedType,
        date: _selectedDate,
        accountId: 'personal',
        createdAt: DateTime.now(),
      );
      print('✅ Transaction object created: ${transaction.id}');

      // Save to storage
      print('💾 Saving to WebStorageService...');
      await WebStorageService.addTransaction(transaction);
      print('✅ Transaction saved to storage');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('✅ Transaction saved successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        // Clear form
        _amountController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedCategoryId = null;
          _selectedDate = DateTime.now();
        });
        print('🧹 Form cleared');
      }

    } catch (e, stackTrace) {
      print('❌ Error saving transaction: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('❌ Error saving transaction: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}