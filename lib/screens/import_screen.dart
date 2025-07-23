import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/bank.dart';
import '../services/import_service.dart';
import '../services/bank_service.dart';
import '../services/web_storage_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({Key? key}) : super(key: key);

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isLoading = false;
  String? _error;
  List<Transaction>? _previewTransactions;
  List<Bank> _banks = [];
  Bank? _selectedBank;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    try {
      final banks = await BankService.getBanks();
      setState(() {
        _banks = banks;
        _selectedBank = banks.isNotEmpty ? banks.first : null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load banks: $e';
      });
    }
  }

  Future<void> _handleFileUpload() async {
    if (_selectedBank == null) {
      setState(() {
        _error = 'Please select a bank first';
      });
      return;
    }

    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.csv';
    uploadInput.click();

    await uploadInput.onChange.first;
    final file = uploadInput.files?.first;
    if (file != null) {
      setState(() {
        _isLoading = true;
        _error = null;
        _previewTransactions = null;
      });

      try {
        final reader = html.FileReader();
        reader.readAsText(file);

        await reader.onLoad.first;
        final csvContent = reader.result as String;
        final transactions = await ImportService.importFromCsv(
          csvContent,
          _selectedBank!.id,
        );

        setState(() {
          _previewTransactions = transactions;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmImport() async {
    if (_previewTransactions == null || _previewTransactions!.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Save transactions
      for (final transaction in _previewTransactions!) {
        await WebStorageService.addTransaction(transaction);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully imported ${_previewTransactions!.length} transactions'),
          backgroundColor: Colors.blue[600]!,
        ),
      );

      setState(() {
        _previewTransactions = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to save transactions: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Transactions'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Import Bank Statement',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Bank>(
                      value: _selectedBank,
                      decoration: const InputDecoration(
                        labelText: 'Select Bank',
                        border: OutlineInputBorder(),
                      ),
                      items: _banks.map((bank) {
                        return DropdownMenuItem(
                          value: bank,
                          child: Text(bank.name),
                        );
                      }).toList(),
                      onChanged: (Bank? value) {
                        setState(() {
                          _selectedBank = value;
                          _previewTransactions = null;
                          _error = null;
                        });
                      },
                    ),
                    if (_selectedBank != null) ...[                      const SizedBox(height: 16),
                      Text(
                        _selectedBank!.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleFileUpload,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload CSV File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading) ...[              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_error != null) ...[              const SizedBox(height: 16),
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_previewTransactions != null) ...[              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Preview (${_previewTransactions!.length} transactions)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _confirmImport,
                            icon: const Icon(Icons.check),
                            label: const Text('Confirm Import'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600]!,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 400,
                        child: ListView.builder(
                          itemCount: _previewTransactions!.length,
                          itemBuilder: (context, index) {
                            final transaction = _previewTransactions![index];
                            return ListTile(
                              leading: Icon(
                                transaction.type == TransactionType.income
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: transaction.type == TransactionType.income
                                    ? Colors.blue[600]!
                                    : Colors.orange[700]!,
                              ),
                              title: Text(transaction.description),
                              subtitle: Text(transaction.date.toString()),
                              trailing: Text(
                                '${transaction.type == TransactionType.income ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: transaction.type == TransactionType.income
                                      ? Colors.blue[600]!
                                      : Colors.orange[700]!,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}