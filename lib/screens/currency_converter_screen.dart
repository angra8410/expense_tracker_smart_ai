import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/currency.dart';
import '../services/currency_exchange_service.dart';
import '../widgets/currency_converter_widget.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen>
    with TickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  
  Currency _fromCurrency = CurrencyConstants.popularCurrencies[3]; // COP
  Currency _toCurrency = CurrencyConstants.popularCurrencies[0]; // USD
  
  CurrencyConversion? _lastConversion;
  bool _isLoading = false;
  String? _errorMessage;
  List<CurrencyConversion> _conversionHistory = [];
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadConversionHistory();
    _amountController.text = '1000';
    _performConversion();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  Future<void> _loadConversionHistory() async {
    try {
      final history = await CurrencyExchangeService.getConversionHistory();
      if (mounted) {
        setState(() {
          _conversionHistory = history;
        });
      }
    } catch (e) {
      debugPrint('Error loading conversion history: $e');
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

        // Save to history
        await CurrencyExchangeService.saveConversionToHistory(conversion);
        await _loadConversionHistory();

        // Haptic feedback
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

  void _showCurrencyPicker({required bool isFromCurrency}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CurrencyPickerBottomSheet(
        selectedCurrency: isFromCurrency ? _fromCurrency : _toCurrency,
        onCurrencySelected: (currency) {
          setState(() {
            if (isFromCurrency) {
              _fromCurrency = currency;
            } else {
              _toCurrency = currency;
            }
          });
          _performConversion();
        },
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Currency Converter',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showConversionHistory(),
            tooltip: 'Conversion History',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await CurrencyExchangeService.clearCache();
              _performConversion();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exchange rates refreshed')),
                );
              }
            },
            tooltip: 'Refresh Rates',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Amount Input Card
                _buildAmountInputCard(colorScheme),
                
                const SizedBox(height: 24),
                
                // Currency Selection Cards
                _buildCurrencySelectionCards(colorScheme),
                
                const SizedBox(height: 24),
                
                // Conversion Result Card
                _buildConversionResultCard(colorScheme),
                
                const SizedBox(height: 24),
                
                // Quick Amount Buttons
                _buildQuickAmountButtons(colorScheme),
                
                const SizedBox(height: 24),
                
                // Popular Currencies
                _buildPopularCurrencies(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInputCard(ColorScheme colorScheme) {
    return Card(
      elevation: 8,
      shadowColor: colorScheme.primary.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount to Convert',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              focusNode: _amountFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Enter amount',
                prefixIcon: Icon(
                  Icons.attach_money,
                  color: colorScheme.primary,
                  size: 28,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (_) => _performConversion(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySelectionCards(ColorScheme colorScheme) {
    return Row(
      children: [
        // From Currency
        Expanded(
          child: _buildCurrencyCard(
            currency: _fromCurrency,
            label: 'From',
            onTap: () => _showCurrencyPicker(isFromCurrency: true),
            colorScheme: colorScheme,
          ),
        ),
        
        // Swap Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.swap_horiz, color: Colors.white),
              onPressed: _swapCurrencies,
              iconSize: 28,
            ),
          ),
        ),
        
        // To Currency
        Expanded(
          child: _buildCurrencyCard(
            currency: _toCurrency,
            label: 'To',
            onTap: () => _showCurrencyPicker(isFromCurrency: false),
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyCard({
    required Currency currency,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currency.flag,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 4),
              Text(
                currency.code,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                currency.name,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversionResultCard(ColorScheme colorScheme) {
    return Card(
      elevation: 8,
      shadowColor: colorScheme.secondary.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              colorScheme.secondaryContainer,
              colorScheme.secondaryContainer.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Converting...'),
            ] else if (_errorMessage != null) ...[
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (_lastConversion != null) ...[
              Text(
                'Converted Amount',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSecondaryContainer.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_lastConversion!.toCurrency.symbol}${_formatAmount(_lastConversion!.convertedAmount)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1 ${_lastConversion!.fromCurrency.code} = ${_lastConversion!.exchangeRate.rate.toStringAsFixed(4)} ${_lastConversion!.toCurrency.code}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSecondaryContainer.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Last updated: ${_formatTime(_lastConversion!.timestamp)}',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSecondaryContainer.withOpacity(0.6),
                ),
              ),
            ] else ...[
              Icon(
                Icons.currency_exchange,
                size: 48,
                color: colorScheme.onSecondaryContainer.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter an amount to convert',
                style: TextStyle(
                  color: colorScheme.onSecondaryContainer.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountButtons(ColorScheme colorScheme) {
    final quickAmounts = [100, 500, 1000, 5000, 10000];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Amounts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickAmounts.map((amount) {
            return ActionChip(
              label: Text('${_fromCurrency.symbol}${_formatAmount(amount.toDouble())}'),
              onPressed: () {
                _amountController.text = amount.toString();
                _performConversion();
              },
              backgroundColor: colorScheme.surfaceVariant,
              labelStyle: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPopularCurrencies(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Currencies',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: CurrencyConstants.popularCurrencies.length,
            itemBuilder: (context, index) {
              final currency = CurrencyConstants.popularCurrencies[index];
              final isSelected = currency.code == _fromCurrency.code || currency.code == _toCurrency.code;
              
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (_fromCurrency.code != currency.code) {
                        _fromCurrency = currency;
                      } else {
                        _toCurrency = currency;
                      }
                    });
                    _performConversion();
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
      ],
    );
  }

  void _showConversionHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConversionHistoryBottomSheet(
        conversions: _conversionHistory,
        onConversionSelected: (conversion) {
          setState(() {
            _fromCurrency = conversion.fromCurrency;
            _toCurrency = conversion.toCurrency;
            _amountController.text = conversion.amount.toString();
          });
          _performConversion();
        },
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