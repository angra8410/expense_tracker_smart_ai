import 'dart:convert';
import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/bank.dart';
import '../services/web_storage_service.dart';
import '../services/category_service.dart';
import '../services/bank_service.dart';

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

      // Parse CSV headers
      List<String> header = _parseCsvLine(lines.first);
      int startLine = 1; // Skip header line
      
      // Special handling for Nu Bank Colombia - normalize headers to lowercase
      if (bank.name == 'Nu Bank Colombia') {
        // Convert headers to lowercase for case-insensitive matching
        header = header.map((h) => h.toLowerCase()).toList();
      }
      
      // Validate headers
      _validateCsvHeader(header, bank.csvFieldMapping);

      // Get categories for mapping
      final categories = await CategoryService.getCategories();
      final categoryNameToId = _createCategoryNameToIdMap(categories);

      final transactions = <Transaction>[];

      // Process data lines
      for (var i = startLine; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final values = _parseCsvLine(line);
        if (values.length != header.length) {
          print('Warning: Line ${i + 1} has ${values.length} fields, expected ${header.length}');
          continue; // Skip malformed lines instead of throwing error
        }

        try {
          final transaction = _createTransactionFromCsv(
            values,
            header,
            categoryNameToId,
            bank,
          );

          transactions.add(transaction);
        } catch (e) {
          print('Warning: Failed to parse line ${i + 1}: $e');
          continue; // Skip problematic lines
        }
      }

      if (transactions.isEmpty) {
        throw Exception('No valid transactions found in CSV file');
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

    // Parse amount with special handling for Nu Bank Colombia format
    String amountStr = fieldMap[mapping['amount']]!;
    double amount;
    TransactionType type;

    if (bank.name == 'Nu Bank Colombia') {
      // Handle Colombian peso format: -$X.XXX.XXX,XX or +$X.XXX.XXX,XX
      final isNegative = amountStr.startsWith('-');
      final isPositive = amountStr.startsWith('+');
      
      // Remove currency symbol and sign, then handle Colombian number format
      amountStr = amountStr.replaceAll(RegExp(r'[+\-\$]'), '');
      // In Colombian format: dots are thousands separators, comma is decimal separator
      // Convert to standard format: remove dots (thousands separators) and replace comma with dot
      amountStr = amountStr.replaceAll('.', '').replaceAll(',', '.');
      amount = double.parse(amountStr);
      
      // Determine transaction type based on sign
      if (isPositive) {
        type = TransactionType.income;
      } else if (isNegative) {
        type = TransactionType.expense;
      } else {
        // If no explicit sign, treat as expense (default for Nu Bank)
        type = TransactionType.expense;
      }
    } else {
      // Standard parsing for other banks
      amountStr = amountStr.replaceAll(RegExp(r'[^\d.-]'), '');
      amount = double.parse(amountStr);
      
      // Parse type (if provided, otherwise infer from amount)
      type = mapping['type'] != null
          ? fieldMap[mapping['type']]!.toLowerCase().contains('income') ||
                  amount > 0
              ? TransactionType.income
              : TransactionType.expense
          : amount > 0
              ? TransactionType.income
              : TransactionType.expense;
    }

    // Parse category (if provided, otherwise use default)
    String? categoryId;
    if (mapping['category'] != null) {
      final categoryName = fieldMap[mapping['category']]!.toLowerCase();
      categoryId = categoryNameToId[categoryName];
    }
    categoryId ??= categoryNameToId.entries.first.value; // Default to first category if not found

    // Parse date with special handling for Nu Bank Colombia format
    final dateStr = fieldMap[mapping['date']]!;
    DateTime date;
    
    if (bank.name == 'Nu Bank Colombia') {
      // Handle Spanish date format: "dd mmm" (e.g., "01 jun")
      date = _parseSpanishDate(dateStr);
    } else if (bank.dateFormat != null) {
      date = DateFormat(bank.dateFormat).parse(dateStr);
    } else {
      date = DateTime.parse(dateStr);
    }

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

  static DateTime _parseSpanishDate(String dateStr) {
    // Map Spanish month abbreviations to numbers
    final spanishMonths = {
      'ene': 1, 'feb': 2, 'mar': 3, 'abr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'ago': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dic': 12,
    };

    final parts = dateStr.trim().split(' ');
    if (parts.length != 2) {
      throw Exception('Invalid Spanish date format: $dateStr');
    }

    final day = int.parse(parts[0]);
    final monthStr = parts[1].toLowerCase();
    final month = spanishMonths[monthStr];
    
    if (month == null) {
      throw Exception('Unknown Spanish month: $monthStr');
    }

    // Use current year as Nu Bank statements typically show current year transactions
    final year = DateTime.now().year;
    
    return DateTime(year, month, day);
  }
}