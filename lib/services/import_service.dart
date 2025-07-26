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

  static Future<List<Transaction>> importFromCsv(String csvContent, Bank bank) async {
    try {
      print('🔄 Starting CSV import for bank: ${bank.name}');
      
      // Clean the CSV content to handle potential encoding issues
      csvContent = csvContent.trim();
      // Remove BOM if present
      if (csvContent.startsWith('\uFEFF')) {
        csvContent = csvContent.substring(1);
        print('🔧 Removed BOM from CSV content');
      }
      
      final lines = const LineSplitter().convert(csvContent);
      print('📄 CSV has ${lines.length} lines');
      
      if (lines.isEmpty) {
        throw Exception('CSV file is empty');
      }

      print('🏦 Found bank: ${bank.name}');

      // Parse CSV headers and clean them
      List<String> header = _parseCsvLine(lines.first).map((field) => field.trim()).toList();
      print('📋 Original headers: $header');
      
      // Validate headers before any normalization
      print('🔍 Validating headers against mapping: ${bank.csvFieldMapping}');
      _validateCsvHeader(header, bank.csvFieldMapping);
      
      int startLine = 1; // Skip header line

      // Get categories for mapping
      final categories = await CategoryService.getCategories();
      final categoryNameToId = _createCategoryNameToIdMap(categories);
      print('📂 Found ${categories.length} categories');

      final transactions = <Transaction>[];

      // Process data lines
      print('🔄 Processing ${lines.length - startLine} data lines...');
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
          print('✅ Processed transaction ${transactions.length}: ${transaction.description} - ${transaction.amount}');
        } catch (e) {
          print('Warning: Failed to parse line ${i + 1}: $e');
          continue; // Skip problematic lines
        }
      }

      if (transactions.isEmpty) {
        throw Exception('No valid transactions found in CSV file');
      }

      print('🎉 Successfully imported ${transactions.length} transactions');
      return transactions;
    } catch (e) {
      throw Exception('Failed to import CSV: $e');
    }
  }

  static List<String> _parseCsvLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    String currentField = '';
    
    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(currentField.trim());
        currentField = '';
      } else {
        currentField += char;
      }
    }
    
    // Add the last field
    result.add(currentField.trim());
    
    // Special handling for Nu Bank Colombia amount format
    // Check if we have exactly 4 parts and the last two might be amount components
    if (result.length == 4) {
      String thirdPart = result[2].trim();
      String fourthPart = result[3].trim();
      
      // Check if third part looks like Colombian amount format and fourth part is decimal
      if (RegExp(r'^[+\-]?\$[\d.]+$').hasMatch(thirdPart) && 
          RegExp(r'^\d{2}$').hasMatch(fourthPart)) {
        // Merge the amount parts
        result[2] = '$thirdPart,$fourthPart';
        result.removeAt(3);
        print('🔧 Nu Bank Colombia: Merged amount ${result[2]}');
      }
    }
    
    return result;
  }

  static void _validateCsvHeader(List<String> header, Map<String, String> fieldMapping) {
    final headerFields = header.map((field) => field.toLowerCase()).toSet();
    final requiredMappedFields = fieldMapping.values.map((field) => field.toLowerCase()).toSet();
    
    print('🔍 Raw header: $header');
    print('🔍 Header fields (lowercase): $headerFields');
    print('🔍 Required mapped fields (lowercase): $requiredMappedFields');
    
    // Debug: Print each header field with its character codes
    for (int i = 0; i < header.length; i++) {
      final field = header[i];
      final codes = field.codeUnits;
      print('🔍 Header[$i]: "$field" (length: ${field.length}, codes: $codes)');
    }
    
    // Check if all required mapped fields are present in the CSV headers
    final missingFields = <String>[];
    for (String requiredField in requiredMappedFields) {
      if (!headerFields.contains(requiredField)) {
        missingFields.add(requiredField);
      }
    }

    print('🔍 Missing fields: $missingFields');

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

    print('🔍 Debug - Header: $header');
    print('🔍 Debug - Values: $values');
    print('🔍 Debug - Field map: $fieldMap');
    print('🔍 Debug - Bank mapping: $mapping');

    // Parse amount with special handling for Nu Bank Colombia format
    String amountStr = fieldMap[mapping['amount']]!;
    print('🔍 Debug - Amount string: $amountStr');
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