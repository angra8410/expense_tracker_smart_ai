import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recurring_transaction.dart';
import '../models/category.dart';
import '../services/web_storage_service.dart';

class RecurringTransactionDialog extends StatefulWidget {
  final RecurringTransaction? recurringTransaction;
  final VoidCallback? onRecurringTransactionUpdated;
  final VoidCallback? onRecurringTransactionDeleted;

  const RecurringTransactionDialog({
    super.key,
    this.recurringTransaction,
    this.onRecurringTransactionUpdated,
    this.onRecurringTransactionDeleted,
  });

  @override
  State<RecurringTransactionDialog> createState() => _RecurringTransactionDialogState();
}

class _RecurringTransactionDialogState extends State<RecurringTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  
  String _selectedType = 'expense';
  String _selectedCategoryId = '';
  RecurrenceFrequency _selectedFrequency = RecurrenceFrequency.monthly;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isActive = true;
  int? _dayOfMonth;
  int? _dayOfWeek;
  
  List<Category> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.recurringTransaction != null) {
      final rt = widget.recurringTransaction!;
      _descriptionController.text = rt.description;
      _amountController.text = rt.amount.toString();
      _selectedType = rt.type;
      _selectedCategoryId = rt.categoryId;
      _selectedFrequency = rt.frequency;
      _startDate = rt.startDate;
      _endDate = rt.endDate;
      _isActive = rt.isActive;
      _dayOfMonth = rt.dayOfMonth;
      _dayOfWeek = rt.dayOfWeek;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await WebStorageService.getCategories();
      setState(() {
        _categories = categories;
        if (_selectedCategoryId.isEmpty && categories.isNotEmpty) {
          _selectedCategoryId = categories.first.id;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  Future<void> _saveRecurringTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      
      if (widget.recurringTransaction != null) {
        // Update existing recurring transaction
        final updatedRecurringTransaction = widget.recurringTransaction!.copyWith(
          description: _descriptionController.text,
          amount: amount,
          categoryId: _selectedCategoryId,
          type: _selectedType,
          frequency: _selectedFrequency,
          startDate: _startDate,
          endDate: _endDate,
          isActive: _isActive,
          dayOfMonth: _dayOfMonth,
          dayOfWeek: _dayOfWeek,
        );
        
        await WebStorageService.updateRecurringTransaction(updatedRecurringTransaction);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recurring transaction updated successfully')),
          );
          widget.onRecurringTransactionUpdated?.call();
          Navigator.of(context).pop();
        }
      } else {
        // Create new recurring transaction
        final newRecurringTransaction = RecurringTransaction.create(
          description: _descriptionController.text,
          amount: amount,
          categoryId: _selectedCategoryId,
          type: _selectedType,
          accountId: 'personal',
          frequency: _selectedFrequency,
          startDate: _startDate,
          endDate: _endDate,
          dayOfMonth: _dayOfMonth,
          dayOfWeek: _dayOfWeek,
        );
        
        await WebStorageService.addRecurringTransaction(newRecurringTransaction);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recurring transaction created successfully')),
          );
          widget.onRecurringTransactionUpdated?.call();
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving recurring transaction: $e')),
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

  Future<void> _deleteRecurringTransaction() async {
    if (widget.recurringTransaction == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Transaction'),
        content: const Text('Are you sure you want to delete this recurring transaction? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await WebStorageService.deleteRecurringTransaction(widget.recurringTransaction!.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recurring transaction deleted successfully')),
          );
          widget.onRecurringTransactionDeleted?.call();
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting recurring transaction: $e')),
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

  void _updateFrequencySpecificFields() {
    setState(() {
      switch (_selectedFrequency) {
        case RecurrenceFrequency.monthly:
          _dayOfMonth = _startDate.day;
          _dayOfWeek = null;
          break;
        case RecurrenceFrequency.weekly:
          _dayOfWeek = _startDate.weekday;
          _dayOfMonth = null;
          break;
        default:
          _dayOfMonth = null;
          _dayOfWeek = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.recurringTransaction != null;
    
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.repeat,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Recurring Transaction' : 'Add Recurring Transaction',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  if (isEditing)
                    IconButton(
                      onPressed: _isLoading ? null : _deleteRecurringTransaction,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete',
                    ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Amount and Type
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'expense', child: Text('Expense')),
                        DropdownMenuItem(value: 'income', child: Text('Income')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
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
                    _selectedCategoryId = value!;
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
              
              // Frequency
              DropdownButtonFormField<RecurrenceFrequency>(
                value: _selectedFrequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
                ),
                items: RecurrenceFrequency.values.map((frequency) {
                  String label;
                  switch (frequency) {
                    case RecurrenceFrequency.daily:
                      label = 'Daily';
                      break;
                    case RecurrenceFrequency.weekly:
                      label = 'Weekly';
                      break;
                    case RecurrenceFrequency.monthly:
                      label = 'Monthly';
                      break;
                    case RecurrenceFrequency.yearly:
                      label = 'Yearly';
                      break;
                  }
                  return DropdownMenuItem(
                    value: frequency,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFrequency = value!;
                    _updateFrequencySpecificFields();
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Start Date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (date != null) {
                    setState(() {
                      _startDate = date;
                      _updateFrequencySpecificFields();
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // End Date (Optional)
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? _startDate.add(const Duration(days: 365)),
                    firstDate: _startDate,
                    lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                  );
                  if (date != null) {
                    setState(() {
                      _endDate = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'End Date (Optional)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.event),
                    suffixIcon: _endDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _endDate = null;
                              });
                            },
                          )
                        : null,
                  ),
                  child: Text(
                    _endDate != null
                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'No end date',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Active toggle
              SwitchListTile(
                title: const Text('Active'),
                subtitle: Text(_isActive ? 'This recurring transaction is active' : 'This recurring transaction is paused'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveRecurringTransaction,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'Update' : 'Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}