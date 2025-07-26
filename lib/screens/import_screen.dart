import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/bank.dart';
import '../services/import_service.dart';
import '../services/bank_service.dart';
import '../services/country_bank_service.dart';
import '../services/transactions_service.dart';

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
  String? _selectedCountry;
  List<String> _availableCountries = [];

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _loadBanks();
  }

  Future<void> _loadCountries() async {
    await CountryBankService.initializeCountryBanks();
    setState(() {
      _availableCountries = CountryBankService.getAvailableCountries();
      _selectedCountry = _availableCountries.isNotEmpty ? _availableCountries.first : null;
    });
    if (_selectedCountry != null) {
      _loadBanksByCountry(_selectedCountry!);
    }
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

  Future<void> _loadBanksByCountry(String countryCode) async {
    try {
      final banks = await CountryBankService.getBanksByCountry(countryCode);
      setState(() {
        _banks = banks;
        _selectedBank = banks.isNotEmpty ? banks.first : null;
        _previewTransactions = null;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load banks for ${CountryBankService.getCountryName(countryCode)}: $e';
      });
    }
  }

  Future<void> _handleFileUpload() async {
    print('📤 File upload initiated');
    if (_selectedBank == null) {
      print('❌ No bank selected');
      setState(() {
        _error = 'Please select a bank first';
      });
      return;
    }

    print('🏦 Selected bank: ${_selectedBank!.name}');
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.csv';
    uploadInput.click();

    await uploadInput.onChange.first;
    final file = uploadInput.files?.first;
    if (file != null) {
      print('📁 File selected: ${file.name} (${file.size} bytes)');
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
        print('📄 CSV content loaded (${csvContent.length} characters)');
        
        final transactions = await ImportService.importFromCsv(
          csvContent,
          _selectedBank!,
        );

        print('✅ Import completed: ${transactions.length} transactions');
        setState(() {
          _previewTransactions = transactions;
          _isLoading = false;
        });
      } catch (e) {
        print('❌ Import failed: $e');
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    } else {
      print('❌ No file selected');
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
        await TransactionsService.addTransaction(transaction);
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
        child: SingleChildScrollView(
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
                    DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      decoration: const InputDecoration(
                        labelText: 'Select Country',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.public),
                      ),
                      items: _availableCountries.map((countryCode) {
                        return DropdownMenuItem(
                          value: countryCode,
                          child: Text(CountryBankService.getCountryName(countryCode)),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            _selectedCountry = value;
                            _previewTransactions = null;
                            _error = null;
                          });
                          _loadBanksByCountry(value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Bank>(
                      value: _selectedBank,
                      decoration: InputDecoration(
                        labelText: _selectedCountry != null 
                            ? 'Select Bank (${CountryBankService.getCountryName(_selectedCountry!)})'
                            : 'Select Bank',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.account_balance),
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
                    if (_selectedBank != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _selectedBank!.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (_selectedBank!.name == 'Nu Bank Colombia') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Nu Bank Colombia Format Guide',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Expected CSV format:\n'
                                '• Headers: fecha, descripción, monto\n'
                                '• Date format: "dd mmm" (e.g., "29 jun")\n'
                                '• Amount format: "+\$X.XXX.XXX,XX" or "-\$X.XXX.XXX,XX"\n'
                                '• Supports Colombian Peso format with Spanish months',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
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
      ),
    );
  }
}