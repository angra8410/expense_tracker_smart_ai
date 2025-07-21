import '../models/bank.dart';
import 'web_storage_service.dart';
import 'package:uuid/uuid.dart';

class BankService {
  static const _uuid = Uuid();
  static const String _storageKey = 'banks';

  static Future<List<Bank>> getBanks() async {
    final banksJson = await WebStorageService.getString(_storageKey) ?? '[]';
    final List<dynamic> banksList = WebStorageService.jsonDecode(banksJson);
    return banksList.map((json) => Bank.fromJson(json)).toList();
  }

  static Future<void> addBank(Bank bank) async {
    final banks = await getBanks();
    banks.add(bank);
    await _saveBanks(banks);
  }

  static Future<void> updateBank(Bank bank) async {
    final banks = await getBanks();
    final index = banks.indexWhere((b) => b.id == bank.id);
    if (index != -1) {
      banks[index] = bank;
      await _saveBanks(banks);
    }
  }

  static Future<void> deleteBank(String bankId) async {
    final banks = await getBanks();
    banks.removeWhere((b) => b.id == bankId);
    await _saveBanks(banks);
  }

  static Future<void> _saveBanks(List<Bank> banks) async {
    final banksJson = WebStorageService.jsonEncode(
      banks.map((bank) => bank.toJson()).toList(),
    );
    await WebStorageService.setString(_storageKey, banksJson);
  }

  static Future<void> initializeDefaultBanks() async {
    final banks = await getBanks();
    if (banks.isEmpty) {
      // Generic CSV format
      await addBank(Bank(
        id: _uuid.v4(),
        name: 'Generic Format',
        description: 'Standard CSV format with columns: Description, Amount, Type, Category, Date (YYYY-MM-DD)',
        csvFieldMapping: {
          'description': 'description',
          'amount': 'amount',
          'type': 'type',
          'category': 'category',
          'date': 'date',
        },
        dateFormat: 'yyyy-MM-dd',
      ));

      // Chase Bank format
      await addBank(Bank(
        id: _uuid.v4(),
        name: 'Chase Bank',
        description: 'Chase Bank statement format with columns: Transaction Date, Description, Amount, Type, Balance',
        csvFieldMapping: {
          'description': 'description',
          'amount': 'amount',
          'date': 'transaction date',
        },
        dateFormat: 'MM/dd/yyyy',
        amountFormat: '#,##0.00',
      ));

      // Bank of America format
      await addBank(Bank(
        id: _uuid.v4(),
        name: 'Bank of America',
        description: 'Bank of America statement format with columns: Date, Description, Amount, Running Bal.',
        csvFieldMapping: {
          'description': 'description',
          'amount': 'amount',
          'date': 'date',
        },
        dateFormat: 'MM/dd/yyyy',
        amountFormat: '#,##0.00',
      ));

      // Wells Fargo format
      await addBank(Bank(
        id: _uuid.v4(),
        name: 'Wells Fargo',
        description: 'Wells Fargo statement format with columns: Date, Amount, Description',
        csvFieldMapping: {
          'description': 'description',
          'amount': 'amount',
          'date': 'date',
        },
        dateFormat: 'MM/dd/yyyy',
        amountFormat: '#,##0.00',
      ));

      // Citibank format
      await addBank(Bank(
        id: _uuid.v4(),
        name: 'Citibank',
        description: 'Citibank statement format with columns: Date, Description, Debit, Credit, Status',
        csvFieldMapping: {
          'description': 'description',
          'amount': 'debit',
          'date': 'date',
        },
        dateFormat: 'MM/dd/yyyy',
        amountFormat: '#,##0.00',
      ));
    }
  }
}