import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/currency.dart';
import '../services/currency_exchange_service.dart';

class CurrencyConverterWidget extends StatefulWidget {
  final double? initialAmount;
  final Currency? initialFromCurrency;
  final Currency? initialToCurrency;
  final Function(CurrencyConversion)? onConversionComplete;

  const CurrencyConverterWidget({
    super.key,
    this.initialAmount,
    this.initialFromCurrency,
    this.initialToCurrency,
    this.onConversionComplete,
  });

  @override
  State<CurrencyConverterWidget> createState() => _CurrencyConverterWidgetState();
}

class _CurrencyConverterWidgetState extends State<CurrencyConverterWidget> {
  final TextEditingController _amountController = TextEditingController();
  
  Currency _fromCurrency = CurrencyConstants.popularCurrencies[3]; // COP
  Currency _toCurrency = CurrencyConstants.popularCurrencies[0]; // USD
  
  CurrencyConversion? _lastConversion;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount.toString();
    }
    
    if (widget.initialFromCurrency != null) {
      _fromCurrency = widget.initialFromCurrency!;
    }
    
    if (widget.initialToCurrency != null) {
      _toCurrency = widget.initialToCurrency!;
    }
    
    if (widget.initialAmount != null) {
      _performConversion();
    }
  }

  Future<void> _performConversion() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() {
        _lastConversion = null;
        _errorMessage = null;
      });
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid amount';
        _lastConversion = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final conversion = await CurrencyExchangeService.convertCurrency(
        amount: amount,
        fromCurrency: _fromCurrency.code,
        toCurrency: _toCurrency.code,
      );

      if (mounted) {
        setState(() {
          _lastConversion = conversion;
          _isLoading = false;
        });

        widget.onConversionComplete?.call(conversion);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Conversion failed: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    
    HapticFeedback.mediumImpact();
    _performConversion();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.currency_exchange,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Currency Converter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Enter amount',
                prefixIcon: Icon(
                  Icons.attach_money,
                  color: colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (_) => _performConversion(),
            ),
            
            const SizedBox(height: 16),
            
            // Currency Selection
            Row(
              children: [
                // From Currency
                Expanded(
                  child: _buildCompactCurrencyCard(
                    currency: _fromCurrency,
                    label: 'From',
                    colorScheme: colorScheme,
                  ),
                ),
                
                // Swap Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: IconButton(
                    icon: Icon(
                      Icons.swap_horiz,
                      color: colorScheme.primary,
                    ),
                    onPressed: _swapCurrencies,
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
                
                // To Currency
                Expanded(
                  child: _buildCompactCurrencyCard(
                    currency: _toCurrency,
                    label: 'To',
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Conversion Result
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (_isLoading) ...[
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(height: 8),
                    const Text('Converting...', style: TextStyle(fontSize: 12)),
                  ] else if (_errorMessage != null) ...[
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (_lastConversion != null) ...[
                    Text(
                      '${_lastConversion!.toCurrency.symbol}${_formatAmount(_lastConversion!.convertedAmount)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1 ${_lastConversion!.fromCurrency.code} = ${_lastConversion!.exchangeRate.rate.toStringAsFixed(4)} ${_lastConversion!.toCurrency.code}',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSecondaryContainer.withOpacity(0.7),
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.currency_exchange,
                      size: 32,
                      color: colorScheme.onSecondaryContainer.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter an amount to convert',
                      style: TextStyle(
                        color: colorScheme.onSecondaryContainer.withOpacity(0.7),
                        fontSize: 12,
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

  Widget _buildCompactCurrencyCard({
    required Currency currency,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currency.flag,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 4),
              Text(
                currency.code,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
    }
  }
}

class CurrencyPickerBottomSheet extends StatefulWidget {
  final Currency selectedCurrency;
  final Function(Currency) onCurrencySelected;

  const CurrencyPickerBottomSheet({
    super.key,
    required this.selectedCurrency,
    required this.onCurrencySelected,
  });

  @override
  State<CurrencyPickerBottomSheet> createState() => _CurrencyPickerBottomSheetState();
}

class _CurrencyPickerBottomSheetState extends State<CurrencyPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Currency> _filteredCurrencies = CurrencyConstants.allCurrencies;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCurrencies);
  }

  void _filterCurrencies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCurrencies = CurrencyConstants.allCurrencies.where((currency) {
        return currency.code.toLowerCase().contains(query) ||
               currency.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Select Currency',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search currencies...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Popular Currencies Section
          if (_searchController.text.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Popular Currencies',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: CurrencyConstants.popularCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = CurrencyConstants.popularCurrencies[index];
                  final isSelected = currency.code == widget.selectedCurrency.code;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () {
                        widget.onCurrencySelected(currency);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 70,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? colorScheme.primary.withOpacity(0.1)
                              : colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected 
                              ? Border.all(color: colorScheme.primary, width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currency.flag,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currency.code,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected 
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'All Currencies',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Currency List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredCurrencies.length,
              itemBuilder: (context, index) {
                final currency = _filteredCurrencies[index];
                final isSelected = currency.code == widget.selectedCurrency.code;
                
                return ListTile(
                  leading: Text(
                    currency.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    currency.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(currency.code),
                  trailing: isSelected 
                      ? Icon(Icons.check, color: colorScheme.primary)
                      : null,
                  onTap: () {
                    widget.onCurrencySelected(currency);
                    Navigator.pop(context);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tileColor: isSelected 
                      ? colorScheme.primary.withOpacity(0.1)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ConversionHistoryBottomSheet extends StatelessWidget {
  final List<CurrencyConversion> conversions;
  final Function(CurrencyConversion) onConversionSelected;

  const ConversionHistoryBottomSheet({
    super.key,
    required this.conversions,
    required this.onConversionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Conversion History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // History List
          Expanded(
            child: conversions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No conversion history yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: conversions.length,
                    itemBuilder: (context, index) {
                      final conversion = conversions[index];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                conversion.fromCurrency.flag,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const Icon(Icons.arrow_downward, size: 12),
                              Text(
                                conversion.toCurrency.flag,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                          title: Text(
                            '${conversion.fromCurrency.symbol}${_formatAmount(conversion.amount)} → ${conversion.toCurrency.symbol}${_formatAmount(conversion.convertedAmount)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            '${conversion.fromCurrency.code} to ${conversion.toCurrency.code} • ${_formatTime(conversion.timestamp)}',
                          ),
                          onTap: () {
                            onConversionSelected(conversion);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}