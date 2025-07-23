class Currency {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  final bool isPopular;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    this.isPopular = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      'flag': flag,
      'isPopular': isPopular,
    };
  }

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      flag: json['flag'] ?? '',
      isPopular: json['isPopular'] ?? false,
    );
  }
}

class ExchangeRate {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime lastUpdated;
  final String source;

  const ExchangeRate({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.lastUpdated,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'fromCurrency': fromCurrency,
      'toCurrency': toCurrency,
      'rate': rate,
      'lastUpdated': lastUpdated.toIso8601String(),
      'source': source,
    };
  }

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      fromCurrency: json['fromCurrency'] ?? '',
      toCurrency: json['toCurrency'] ?? '',
      rate: (json['rate'] ?? 0.0).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
      source: json['source'] ?? '',
    );
  }
}

class CurrencyConversion {
  final double amount;
  final Currency fromCurrency;
  final Currency toCurrency;
  final double convertedAmount;
  final ExchangeRate exchangeRate;
  final DateTime timestamp;

  const CurrencyConversion({
    required this.amount,
    required this.fromCurrency,
    required this.toCurrency,
    required this.convertedAmount,
    required this.exchangeRate,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'fromCurrency': fromCurrency.toJson(),
      'toCurrency': toCurrency.toJson(),
      'convertedAmount': convertedAmount,
      'exchangeRate': exchangeRate.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CurrencyConversion.fromJson(Map<String, dynamic> json) {
    return CurrencyConversion(
      amount: (json['amount'] ?? 0.0).toDouble(),
      fromCurrency: Currency.fromJson(json['fromCurrency'] ?? {}),
      toCurrency: Currency.fromJson(json['toCurrency'] ?? {}),
      convertedAmount: (json['convertedAmount'] ?? 0.0).toDouble(),
      exchangeRate: ExchangeRate.fromJson(json['exchangeRate'] ?? {}),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Predefined popular currencies
class CurrencyConstants {
  static const List<Currency> popularCurrencies = [
    Currency(
      code: 'USD',
      name: 'US Dollar',
      symbol: '\$',
      flag: '🇺🇸',
      isPopular: true,
    ),
    Currency(
      code: 'EUR',
      name: 'Euro',
      symbol: '€',
      flag: '🇪🇺',
      isPopular: true,
    ),
    Currency(
      code: 'GBP',
      name: 'British Pound',
      symbol: '£',
      flag: '🇬🇧',
      isPopular: true,
    ),
    Currency(
      code: 'COP',
      name: 'Colombian Peso',
      symbol: '\$',
      flag: '🇨🇴',
      isPopular: true,
    ),
    Currency(
      code: 'JPY',
      name: 'Japanese Yen',
      symbol: '¥',
      flag: '🇯🇵',
      isPopular: true,
    ),
    Currency(
      code: 'CAD',
      name: 'Canadian Dollar',
      symbol: 'C\$',
      flag: '🇨🇦',
      isPopular: true,
    ),
    Currency(
      code: 'AUD',
      name: 'Australian Dollar',
      symbol: 'A\$',
      flag: '🇦🇺',
      isPopular: true,
    ),
    Currency(
      code: 'CHF',
      name: 'Swiss Franc',
      symbol: 'CHF',
      flag: '🇨🇭',
      isPopular: true,
    ),
  ];

  static const List<Currency> allCurrencies = [
    ...popularCurrencies,
    Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳'),
    Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹', flag: '🇮🇳'),
    Currency(code: 'KRW', name: 'South Korean Won', symbol: '₩', flag: '🇰🇷'),
    Currency(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$', flag: '🇧🇷'),
    Currency(code: 'MXN', name: 'Mexican Peso', symbol: '\$', flag: '🇲🇽'),
    Currency(code: 'ARS', name: 'Argentine Peso', symbol: '\$', flag: '🇦🇷'),
    Currency(code: 'CLP', name: 'Chilean Peso', symbol: '\$', flag: '🇨🇱'),
    Currency(code: 'PEN', name: 'Peruvian Sol', symbol: 'S/', flag: '🇵🇪'),
    Currency(code: 'RUB', name: 'Russian Ruble', symbol: '₽', flag: '🇷🇺'),
    Currency(code: 'ZAR', name: 'South African Rand', symbol: 'R', flag: '🇿🇦'),
    Currency(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$', flag: '🇸🇬'),
    Currency(code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK\$', flag: '🇭🇰'),
    Currency(code: 'NOK', name: 'Norwegian Krone', symbol: 'kr', flag: '🇳🇴'),
    Currency(code: 'SEK', name: 'Swedish Krona', symbol: 'kr', flag: '🇸🇪'),
    Currency(code: 'DKK', name: 'Danish Krone', symbol: 'kr', flag: '🇩🇰'),
    Currency(code: 'PLN', name: 'Polish Zloty', symbol: 'zł', flag: '🇵🇱'),
    Currency(code: 'CZK', name: 'Czech Koruna', symbol: 'Kč', flag: '🇨🇿'),
    Currency(code: 'HUF', name: 'Hungarian Forint', symbol: 'Ft', flag: '🇭🇺'),
    Currency(code: 'TRY', name: 'Turkish Lira', symbol: '₺', flag: '🇹🇷'),
    Currency(code: 'ILS', name: 'Israeli Shekel', symbol: '₪', flag: '🇮🇱'),
    Currency(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ', flag: '🇦🇪'),
    Currency(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼', flag: '🇸🇦'),
    Currency(code: 'THB', name: 'Thai Baht', symbol: '฿', flag: '🇹🇭'),
    Currency(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM', flag: '🇲🇾'),
    Currency(code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp', flag: '🇮🇩'),
    Currency(code: 'PHP', name: 'Philippine Peso', symbol: '₱', flag: '🇵🇭'),
    Currency(code: 'VND', name: 'Vietnamese Dong', symbol: '₫', flag: '🇻🇳'),
  ];

  static Currency? getCurrencyByCode(String code) {
    try {
      return allCurrencies.firstWhere((currency) => currency.code == code);
    } catch (e) {
      return null;
    }
  }

  static List<Currency> searchCurrencies(String query) {
    if (query.isEmpty) return popularCurrencies;
    
    final lowerQuery = query.toLowerCase();
    return allCurrencies.where((currency) =>
      currency.code.toLowerCase().contains(lowerQuery) ||
      currency.name.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}