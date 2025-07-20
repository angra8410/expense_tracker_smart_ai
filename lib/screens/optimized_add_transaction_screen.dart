// Update the _saveTransaction method in your existing AddTransactionScreen

Future<void> _saveTransaction() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isSaving = true;
  });

  try {
    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
    
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      description: _descriptionController.text,
      categoryId: _selectedCategoryId!,
      date: _selectedDate,
      type: _selectedType,
      accountId: 'personal',
    );

    // Use optimized fast addition
    await PerformanceOptimizedMLService.addTransactionFast(transaction);
    
    // Track prediction accuracy (lightweight operation)
    if (_predictedCategoryId != null) {
      // Run this asynchronously to not block UI
      Future.microtask(() async {
        await EnhancedMLService.trackPredictionAccuracy(
          _predictedCategoryId!,
          _selectedCategoryId!,
        );
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedType == TransactionType.expense
                ? 'Expense added successfully!' 
                : 'Income added successfully!',
          ),
          backgroundColor: _selectedType == TransactionType.expense
              ? Colors.red[600] 
              : Colors.green[600],
        ),
      );
      Navigator.of(context).pop();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving transaction: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  } finally {
    setState(() {
      _isSaving = false;
    });
  }
}