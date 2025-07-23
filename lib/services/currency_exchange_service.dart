import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/currency.dart';
import 'web_storage_service.dart';

class CurrencyExchangeService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const String _fallbackUrl = 'https://api.fixer.io/latest';
  static const String _cacheKey = 'exchange_rates_cache';
  static const String _lastUpdateKey = 'exchange_rates_last_update';
  static const Duration _cacheValidDuration = Duration(hours: 1);

  /// Get live exchange rates for a base currency
  static Future<Map<String, double>> getExchangeRates(String baseCurrency) async {
    try {
      // Check cache first
      final cachedRates = await _getCachedRates(baseCurrency);
      if (cachedRates != null) {
        debugPrint('💰 Using cached exchange rates for $baseCurrency');
        return cachedRates;
      }

      // Fetch from API
      debugPrint('🌐 Fetching live exchange rates for $baseCurrency');
      final rates = await _fetchLiveRates(baseCurrency);
      
      // Cache the results
      await _cacheRates(baseCurrency, rates);
      
      return rates;
    } catch (e) {
      debugPrint('❌ Error fetching exchange rates: $e');
      
      // Return fallback rates if API fails
      return _getFallbackRates(baseCurrency);
    }
  }

  /// Fetch live rates from API
  static Future<Map<String, double>> _fetchLiveRates(String baseCurrency) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$baseCurrency'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = Map<String, double>.from(
          (data['rates'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ),
        );
        
        debugPrint('✅ Successfully fetched ${rates.length} exchange rates');
        return rates;
      } else {
        throw Exception('API returned status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔄 Primary API failed, trying fallback...');
      return await _fetchFallbackRates(baseCurrency);
    }
  }

  /// Fetch from fallback API
  static Future<Map<String, double>> _fetchFallbackRates(String baseCurrency) async {
    try {
      // Using a free tier API that doesn't require API key
      final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/$baseCurrency'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = Map<String, double>.from(
          (data['rates'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ),
        );
        
        debugPrint('✅ Successfully fetched ${rates.length} rates from fallback API');
        return rates;
      } else {
        throw Exception('Fallback API failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Fallback API also failed: $e');
      throw Exception('All exchange rate APIs failed');
    }
  }

  /// Get cached rates if still valid
  static Future<Map<String, double>?> _getCachedRates(String baseCurrency) async {
    try {
      final lastUpdateStr = await WebStorageService.getString('${_lastUpdateKey}_$baseCurrency');
      if (lastUpdateStr == null) return null;

      final lastUpdate = DateTime.parse(lastUpdateStr);
      final now = DateTime.now();
      
      if (now.difference(lastUpdate) > _cacheValidDuration) {
        debugPrint('💾 Cache expired for $baseCurrency');
        return null;
      }

      final cachedDataStr = await WebStorageService.getString('${_cacheKey}_$baseCurrency');
      if (cachedDataStr == null) return null;

      final cachedData = json.decode(cachedDataStr) as Map<String, dynamic>;
      return Map<String, double>.from(
        cachedData.map((key, value) => MapEntry(key, (value as num).toDouble())),
      );
    } catch (e) {
      debugPrint('❌ Error reading cached rates: $e');
      return null;
    }
  }

  /// Cache exchange rates
  static Future<void> _cacheRates(String baseCurrency, Map<String, double> rates) async {
    try {
      await WebStorageService.setString(
        '${_cacheKey}_$baseCurrency',
        json.encode(rates),
      );
      await WebStorageService.setString(
        '${_lastUpdateKey}_$baseCurrency',
        DateTime.now().toIso8601String(),
      );
      debugPrint('💾 Cached exchange rates for $baseCurrency');
    } catch (e) {
      debugPrint('❌ Error caching rates: $e');
    }
  }

  /// Get fallback rates when API is unavailable
  static Map<String, double> _getFallbackRates(String baseCurrency) {
    debugPrint('🔄 Using fallback exchange rates for $baseCurrency');
    
    // Static fallback rates (approximate values for demo)
    const fallbackRates = {
      'USD': {
        'EUR': 0.85,
        'GBP': 0.73,
        'COP': 4200.0,
        'JPY': 110.0,
        'CAD': 1.25,
        'AUD': 1.35,
        'CHF': 0.92,
        'CNY': 6.45,
        'INR': 74.0,
        'BRL': 5.2,
        'MXN': 20.0,
      },
      'EUR': {
        'USD': 1.18,
        'GBP': 0.86,
        'COP': 4950.0,
        'JPY': 129.0,
        'CAD': 1.47,
        'AUD': 1.59,
        'CHF': 1.08,
      },
      'COP': {
        'USD': 0.00024,
        'EUR': 0.0002,
        'GBP': 0.00017,
        'JPY': 0.026,
        'CAD': 0.0003,
        'AUD': 0.00032,
        'CHF': 0.00022,
      },
    };

    if (fallbackRates.containsKey(baseCurrency)) {
      return Map<String, double>.from(fallbackRates[baseCurrency]!);
    }

    // If base currency not in fallback, return empty map
    return {};
  }

  /// Convert amount between currencies
  static Future<CurrencyConversion> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      final fromCurrencyObj = CurrencyConstants.getCurrencyByCode(fromCurrency);
      final toCurrencyObj = CurrencyConstants.getCurrencyByCode(toCurrency);

      if (fromCurrencyObj == null || toCurrencyObj == null) {
        throw Exception('Invalid currency code');
      }

      // If same currency, return as-is
      if (fromCurrency == toCurrency) {
        final exchangeRate = ExchangeRate(
          fromCurrency: fromCurrency,
          toCurrency: toCurrency,
          rate: 1.0,
          lastUpdated: DateTime.now(),
          source: 'Same Currency',
        );

        return CurrencyConversion(
          amount: amount,
          fromCurrency: fromCurrencyObj,
          toCurrency: toCurrencyObj,
          convertedAmount: amount,
          exchangeRate: exchangeRate,
          timestamp: DateTime.now(),
        );
      }

      // Get exchange rates
      final rates = await getExchangeRates(fromCurrency);
      final rate = rates[toCurrency];

      if (rate == null) {
        throw Exception('Exchange rate not available for $fromCurrency to $toCurrency');
      }

      final convertedAmount = amount * rate;
      
      final exchangeRate = ExchangeRate(
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        rate: rate,
        lastUpdated: DateTime.now(),
        source: 'Live API',
      );

      return CurrencyConversion(
        amount: amount,
        fromCurrency: fromCurrencyObj,
        toCurrency: toCurrencyObj,
        convertedAmount: convertedAmount,
        exchangeRate: exchangeRate,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Currency conversion error: $e');
      rethrow;
    }
  }

  /// Get multiple currency rates for a base currency
  static Future<List<ExchangeRate>> getMultipleCurrencyRates({
    required String baseCurrency,
    required List<String> targetCurrencies,
  }) async {
    try {
      final rates = await getExchangeRates(baseCurrency);
      final exchangeRates = <ExchangeRate>[];

      for (final targetCurrency in targetCurrencies) {
        final rate = rates[targetCurrency];
        if (rate != null) {
          exchangeRates.add(ExchangeRate(
            fromCurrency: baseCurrency,
            toCurrency: targetCurrency,
            rate: rate,
            lastUpdated: DateTime.now(),
            source: 'Live API',
          ));
        }
      }

      return exchangeRates;
    } catch (e) {
      debugPrint('❌ Error getting multiple currency rates: $e');
      return [];
    }
  }

  /// Get historical conversion data (for charts/trends)
  static Future<List<CurrencyConversion>> getConversionHistory() async {
    try {
      final historyStr = await WebStorageService.getString('conversion_history');
      if (historyStr == null) return [];

      final historyData = json.decode(historyStr) as List<dynamic>;
      return historyData
          .map((item) => CurrencyConversion.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting conversion history: $e');
      return [];
    }
  }

  /// Save conversion to history
  static Future<void> saveConversionToHistory(CurrencyConversion conversion) async {
    try {
      final history = await getConversionHistory();
      history.insert(0, conversion);

      // Keep only last 50 conversions
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }

      await WebStorageService.setString(
        'conversion_history',
        json.encode(history.map((c) => c.toJson()).toList()),
      );
      
      debugPrint('💾 Saved conversion to history: ${conversion.fromCurrency.code} → ${conversion.toCurrency.code}');
    } catch (e) {
      debugPrint('❌ Error saving conversion history: $e');
    }
  }

  /// Clear cache (useful for testing or manual refresh)
  static Future<void> clearCache() async {
    try {
      // Clear all cached exchange rates
      for (final currency in CurrencyConstants.popularCurrencies) {
        await WebStorageService.remove('${_cacheKey}_${currency.code}');
        await WebStorageService.remove('${_lastUpdateKey}_${currency.code}');
      }
      debugPrint('🗑️ Exchange rate cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Get cache status for debugging
  static Future<Map<String, dynamic>> getCacheStatus() async {
    final status = <String, dynamic>{};
    
    for (final currency in CurrencyConstants.popularCurrencies) {
      final lastUpdateStr = await WebStorageService.getString('${_lastUpdateKey}_${currency.code}');
      if (lastUpdateStr != null) {
        final lastUpdate = DateTime.parse(lastUpdateStr);
        final age = DateTime.now().difference(lastUpdate);
        status[currency.code] = {
          'lastUpdate': lastUpdate.toIso8601String(),
          'ageMinutes': age.inMinutes,
          'isValid': age < _cacheValidDuration,
        };
      }
    }
    
    return status;
  }
}