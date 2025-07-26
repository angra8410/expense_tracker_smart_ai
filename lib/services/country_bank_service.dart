import '../models/bank.dart';
import 'web_storage_service.dart';
import 'package:uuid/uuid.dart';

class CountryBankService {
  static const _uuid = Uuid();
  static const String _storageKey = 'country_banks';

  // Colombian banks data based on official sources
  static final Map<String, List<Map<String, dynamic>>> _countryBanks = {
    'CO': [
      {
        'name': 'Bancolombia',
        'description': 'Largest bank in Colombia - CSV format: Fecha, Descripción, Valor, Saldo',
        'csvFieldMapping': {
          'description': 'descripción',
          'amount': 'valor',
          'date': 'fecha',
        },
        'dateFormat': 'dd/MM/yyyy',
        'amountFormat': '\$#,###,###.##',
        'currency': 'COP',
      },
      {
        'name': 'Nu Bank Colombia',
        'description': 'Nu Bank Colombia statement format with columns: Fecha, Descripción, Monto (COP format with +/- prefix)',
        'csvFieldMapping': {
          'description': 'descripción',
          'amount': 'monto',
          'date': 'fecha',
        },
        'dateFormat': 'dd MMM',
        'amountFormat': '+/-\$#.###.###,##',
        'currency': 'COP',
      },
      {
        'name': 'Banco Davivienda',
        'description': 'Davivienda bank statement format - CSV format: Fecha, Concepto, Débito, Crédito',
        'csvFieldMapping': {
          'description': 'concepto',
          'amount': 'débito',
          'date': 'fecha',
        },
        'dateFormat': 'dd/MM/yyyy',
        'amountFormat': '\$#,###,###.##',
        'currency': 'COP',
      },
      {
        'name': 'Banco de Bogotá',
        'description': 'Banco de Bogotá statement format - CSV format: Fecha, Descripción, Valor, Saldo',
        'csvFieldMapping': {
          'description': 'descripción',
          'amount': 'valor',
          'date': 'fecha',
        },
        'dateFormat': 'dd/MM/yyyy',
        'amountFormat': '\$#,###,###.##',
        'currency': 'COP',
      },
      {
        'name': 'Banco Santander Colombia',
        'description': 'Santander Colombia statement format - CSV format: Fecha, Descripción, Importe, Saldo',
        'csvFieldMapping': {
          'description': 'descripción',
          'amount': 'importe',
          'date': 'fecha',
        },
        'dateFormat': 'dd/MM/yyyy',
        'amountFormat': '\$#,###,###.##',
        'currency': 'COP',
      },
      {
        'name': 'BBVA Colombia',
        'description': 'BBVA Colombia statement format - CSV format: Fecha, Concepto, Cargo, Abono',
        'csvFieldMapping': {
          'description': 'concepto',
          'amount': 'cargo',
          'date': 'fecha',
        },
        'dateFormat': 'dd/MM/yyyy',
        'amountFormat': '\$#,###,###.##',
        'currency': 'COP',
      },
      {
        'name': 'Banco Agrario de Colombia',
        'description': 'Banco Agrario statement format - CSV format: Fecha, Descripción, Valor, Saldo',
        'csvFieldMapping': {
          'description': 'descripción',
          'amount': 'valor',
          'date': 'fecha',
        },
        'dateFormat': 'dd/MM/yyyy',
        'amountFormat': '\$#,###,###.##',
        'currency': 'COP',
      },
      {
        'name': 'Banco Popular',
        'description': 'Banco Popular statement format - CSV format: Fecha, Descripción, Débito, Crédito',
        'csvFieldMapping': {
          'description': 'descripción',
          'amount': 'débito',
          'date': 'fecha',
        },
        'dateFormat': 'dd/MM/yyyy',
        'amountFormat': '\$#,###,###.##',
        'currency': 'COP',
      },
      {
        'name': 'Scotiabank Colpatria',
        'description': 'Scotiabank Colpatria statement format - CSV format: Fecha, Descripción, Monto, Saldo',
        'csvFieldMapping': {
          'description': 'descripción',
          'amount': 'monto',
          'date': 'fecha',
        },
        'dateFormat': 'dd/MM/yyyy',
        'amountFormat': '\$#,###,###.##',
        'currency': 'COP',
      },
      {
        'name': 'Banco Itaú Colombia',
        'description': 'Itaú Colombia statement format - CSV format: Fecha, Descripción, Valor, Saldo',
        'csvFieldMapping': {
          'description': 'descripción',
          'amount': 'valor',
          'date': 'fecha',
        },
        'dateFormat': 'dd/MM/yyyy',
        'amountFormat': '\$#,###,###.##',
        'currency': 'COP',
      },
      {
        'name': 'Nu Bank Colombia',
        'description': 'Nu Bank Colombia statement format - CSV format: fecha, descripción, monto',
        'csvFieldMapping': {
          'description': 'descripción',
          'amount': 'monto',
          'date': 'fecha',
        },
        'dateFormat': 'dd mmm',
        'amountFormat': '\$#,###,###.##',
        'currency': 'COP',
      },
    ],
    'US': [
      {
        'name': 'Chase Bank',
        'description': 'Chase Bank statement format with columns: Transaction Date, Description, Amount, Type, Balance',
        'csvFieldMapping': {
          'description': 'description',
          'amount': 'amount',
          'date': 'transaction date',
        },
        'dateFormat': 'MM/dd/yyyy',
        'amountFormat': '#,##0.00',
        'currency': 'USD',
      },
      {
        'name': 'Bank of America',
        'description': 'Bank of America statement format with columns: Date, Description, Amount, Running Bal.',
        'csvFieldMapping': {
          'description': 'description',
          'amount': 'amount',
          'date': 'date',
        },
        'dateFormat': 'MM/dd/yyyy',
        'amountFormat': '#,##0.00',
        'currency': 'USD',
      },
      {
        'name': 'Wells Fargo',
        'description': 'Wells Fargo statement format with columns: Date, Amount, Description',
        'csvFieldMapping': {
          'description': 'description',
          'amount': 'amount',
          'date': 'date',
        },
        'dateFormat': 'MM/dd/yyyy',
        'amountFormat': '#,##0.00',
        'currency': 'USD',
      },
      {
        'name': 'Citibank',
        'description': 'Citibank statement format with columns: Date, Description, Debit, Credit, Status',
        'csvFieldMapping': {
          'description': 'description',
          'amount': 'debit',
          'date': 'date',
        },
        'dateFormat': 'MM/dd/yyyy',
        'amountFormat': '#,##0.00',
        'currency': 'USD',
      },
    ],
    'GENERIC': [
      {
        'name': 'Generic Format',
        'description': 'Standard CSV format with columns: Description, Amount, Type, Category, Date (YYYY-MM-DD)',
        'csvFieldMapping': {
          'description': 'description',
          'amount': 'amount',
          'type': 'type',
          'category': 'category',
          'date': 'date',
        },
        'dateFormat': 'yyyy-MM-dd',
        'amountFormat': '#,##0.00',
        'currency': 'USD',
      },
    ],
  };

  static final Map<String, String> _countryNames = {
    'CO': 'Colombia',
    'US': 'United States',
    'GENERIC': 'Generic/Other',
  };

  static List<String> getAvailableCountries() {
    return _countryBanks.keys.toList();
  }

  static String getCountryName(String countryCode) {
    return _countryNames[countryCode] ?? countryCode;
  }

  static Future<List<Bank>> getBanksByCountry(String countryCode) async {
    final bankData = _countryBanks[countryCode] ?? [];
    return bankData.map((data) => Bank(
      id: _uuid.v4(),
      name: data['name'],
      description: data['description'],
      csvFieldMapping: Map<String, String>.from(data['csvFieldMapping']),
      dateFormat: data['dateFormat'],
      amountFormat: data['amountFormat'],
      defaultAccountId: '${countryCode.toLowerCase()}-${data['name'].toLowerCase().replaceAll(' ', '-')}',
    )).toList();
  }

  static Future<List<Bank>> getAllBanks() async {
    final List<Bank> allBanks = [];
    for (final countryCode in _countryBanks.keys) {
      final banks = await getBanksByCountry(countryCode);
      allBanks.addAll(banks);
    }
    return allBanks;
  }

  static Future<void> initializeCountryBanks() async {
    // This method can be used to initialize any additional data
    // or fetch from external APIs in the future
    print('🏦 Country banks initialized with ${_countryBanks.length} countries');
  }

  // Future enhancement: Add method to fetch banks from external APIs
  static Future<List<Bank>> fetchBanksFromAPI(String countryCode) async {
    // This is where we could integrate with external APIs like:
    // - Bank Data API (apilayer.com)
    // - Open Banking APIs
    // - Country-specific financial authority APIs
    
    // For now, return the static data
    return getBanksByCountry(countryCode);
  }

  // Method to add custom bank for a country
  static Future<void> addCustomBank(String countryCode, Map<String, dynamic> bankData) async {
    if (!_countryBanks.containsKey(countryCode)) {
      _countryBanks[countryCode] = [];
    }
    _countryBanks[countryCode]!.add(bankData);
    
    // Save to persistent storage
    await _saveCountryBanks();
  }

  static Future<void> _saveCountryBanks() async {
    final banksJson = WebStorageService.jsonEncode(_countryBanks);
    await WebStorageService.setString(_storageKey, banksJson);
  }

  static Future<void> _loadCountryBanks() async {
    final banksJson = WebStorageService.getString(_storageKey);
    if (banksJson != null) {
      try {
        final Map<String, dynamic> loaded = WebStorageService.jsonDecode(banksJson);
        _countryBanks.addAll(loaded.cast<String, List<Map<String, dynamic>>>());
      } catch (e) {
        print('Error loading country banks: $e');
      }
    }
  }
}