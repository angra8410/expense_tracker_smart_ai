import 'dart:convert';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/bank.dart';
import '../services/web_storage_service.dart';
import '../services/bank_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class ImportService {
  static const _uuid = Uuid();

  static Future<List<Transaction>> importFromCsv(String csvContent, String bankId) async {
    try {
      final lines = const LineSplitter().convert(csvContent);
      if (lines.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Get bank configuration
      final banks = await BankService.getBanks();
      final bank = banks.firstWhere(
        (b) => b.id == bankId,
        orElse: () => throw Exception('Bank configuration not found'),
      );

      // Get header line and validate format
      final header = _parseCsvLine(lines.first);
      _validateCsvHeader(header, bank.csvFieldMapping);

      // Get categories for mapping
      final categories = await WebStorageService.getCategories();
      final categoryNameToId = _createCategoryNameToIdMap(categories);

      final transactions = <Transaction>[];

      // Process data lines
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final values = _parseCsvLine(line);
        if (values.length != header.length) {
          throw Exception('Invalid CSV format at line ${i + 1}');
        }

        final transaction = _createTransactionFromCsv(
          values,
          header,
          categoryNameToId,
          bank,
        );

        transactions.add(transaction);
      }

      return transactions;
    } catch (e) {
      throw Exception('Failed to import CSV: $e');
    }
  }

  static List<String> _parseCsvLine(String line) {
    final values = <String>[];
    bool inQuotes = false;
    StringBuffer currentValue = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          // Handle escaped quotes
          currentValue.write('"');
          i++; // Skip next quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        values.add(currentValue.toString().trim());
        currentValue.clear();
      } else {
        currentValue.write(char);
      }
    }

    values.add(currentValue.toString().trim());
    return values;
  }

  static void _validateCsvHeader(List<String> header, Map<String, String> fieldMapping) {
    final requiredFields = fieldMapping.values.toSet();
    final headerFields = header.map((field) => field.toLowerCase()).toSet();
    final missingFields = requiredFields.difference(headerFields);

    if (missingFields.isNotEmpty) {
      throw Exception(
          'Missing required fields in CSV header: ${missingFields.join(', ')}');
    }
  }

  static Map<String, String> _createCategoryNameToIdMap(List<Category> categories) {
    return {
      for (var category in categories) category.name.toLowerCase(): category.id
    };
  }

  static Transaction _createTransactionFromCsv(
    List<String> values,
    List<String> header,
    Map<String, String> categoryNameToId,
    Bank bank,
  ) {
    final fieldMap = Map.fromIterables(header, values);
    final mapping = bank.csvFieldMapping;

    // Parse amount
    final amountStr = fieldMap[mapping['amount']]!.replaceAll(RegExp(r'[^\d.-]'), '');
    final amount = double.parse(amountStr);

    // Parse type (if provided, otherwise infer from amount)
    final type = mapping['type'] != null
        ? fieldMap[mapping['type']]!.toLowerCase().contains('income') ||
                amount > 0
            ? TransactionType.income
            : TransactionType.expense
        : amount > 0
            ? TransactionType.income
            : TransactionType.expense;

    // Parse category (if provided, otherwise use default)
    String? categoryId;
    if (mapping['category'] != null) {
      final categoryName = fieldMap[mapping['category']]!.toLowerCase();
      categoryId = categoryNameToId[categoryName];
    }
    categoryId ??= categoryNameToId.entries.first.value; // Default to first category if not found

    // Parse date using bank's date format
    final dateStr = fieldMap[mapping['date']]!;
    final date = bank.dateFormat != null
        ? DateFormat(bank.dateFormat).parse(dateStr)
        : DateTime.parse(dateStr);

    return Transaction(
      id: _uuid.v4(),
      description: fieldMap[mapping['description']]!,
      amount: amount.abs(), // Store amount as positive
      type: type,
      categoryId: categoryId,
      date: date,
      accountId: bank.defaultAccountId ?? 'default',
    );
  }
}