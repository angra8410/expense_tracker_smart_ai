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
      
      // Debug: Print first few characters to understand the content
      print('🔍 CSV content preview (first 200 chars): ${csvContent.length > 200 ? csvContent.substring(0, 200) : csvContent}');
      
      final lines = const LineSplitter().convert(csvContent);
      print('📄 CSV has ${lines.length} lines');
      
      if (lines.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Debug: Print first few lines
      print('🔍 First line: "${lines.first}"');
      if (lines.length > 1) {
        print('🔍 Second line: "${lines[1]}"');
      }

      print('🏦 Found bank: ${bank.name}');

      // Parse CSV headers and clean them
      List<String> header = _parseCsvLine(lines.first).map((field) => field.trim()).toList();
      print('📋 Original headers: $header');
      
      // Check if we have a single field that might be space-separated (but not comma-separated)
      // Only apply this logic if the first line has NO commas at all
      if (header.length == 1 && header[0].contains(' ') && !lines.first.contains(',')) {
        print('🔧 Detected space-separated values (no commas), attempting to split by spaces');
        header = lines.first.trim().split(RegExp(r'\s+'));
        print('📋 Space-split headers: $header');
      }
      
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

        List<String> values = _parseCsvLine(line);
        
        // Only apply space-splitting logic for truly space-separated files
        // (where header was also space-separated and line has no commas)
        if (values.length == 1 && values[0].contains(' ') && !line.contains(',') && header.length > 3) {
          print('🔧 Line ${i + 1}: Detected space-separated values (no commas), splitting by spaces');
          values = line.trim().split(RegExp(r'\s+'));
        }
        
        if (values.length != header.length) {
          print('Warning: Line ${i + 1} has ${values.length} fields, expected ${header.length}');
          print('Line content: "$line"');
          print('Parsed values: $values');
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
    // Check if this looks like a space-separated Bancolombia format
    // (contains spaces but amounts have commas as thousands separators)
    if (!line.contains('"') && line.contains(' ') && RegExp(r'\d+,\d+\.\d+').hasMatch(line)) {
      return _parseSpaceSeparatedBancolombiaLine(line);
    }
    
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

  static List<String> _parseSpaceSeparatedBancolombiaLine(String line) {
    // For Bancolombia space-separated format: FECHA DESCRIPCIÓN SUCURSAL DCTO VALOR SALDO
    // Where VALOR and SALDO can contain commas as thousands separators
    
    List<String> parts = line.trim().split(RegExp(r'\s+'));
    List<String> result = [];
    
    if (parts.length < 6) {
      // If we have fewer than 6 parts, try to parse differently
      // Look for patterns like: date description amount amount
      RegExp pattern = RegExp(r'^(\d{1,2}/\d{1,2})\s+(.+?)\s+([-]?\d{1,3}(?:,\d{3})*\.\d{2})\s+([-]?\d{1,3}(?:,\d{3})*\.\d{2})$');
      Match? match = pattern.firstMatch(line.trim());
      
      if (match != null) {
        result.add(match.group(1)!); // FECHA
        result.add(match.group(2)!); // DESCRIPCIÓN (everything in between)
        result.add(''); // SUCURSAL (empty)
        result.add(''); // DCTO (empty)
        result.add(match.group(3)!); // VALOR
        result.add(match.group(4)!); // SALDO
        return result;
      }
    }
    
    // Standard 6-field parsing
    if (parts.length >= 6) {
      result.add(parts[0]); // FECHA
      
      // Find where the amounts start (look for patterns like -123,456.78)
      int valorIndex = -1;
      int saldoIndex = -1;
      
      for (int i = parts.length - 1; i >= 0; i--) {
        if (RegExp(r'^[-]?\d{1,3}(?:,\d{3})*\.\d{2}$').hasMatch(parts[i])) {
          if (saldoIndex == -1) {
            saldoIndex = i;
          } else if (valorIndex == -1) {
            valorIndex = i;
            break;
          }
        }
      }
      
      if (valorIndex > 0 && saldoIndex > valorIndex) {
        // Build DESCRIPCIÓN from parts between FECHA and VALOR
        List<String> descParts = [];
        for (int i = 1; i < valorIndex; i++) {
          descParts.add(parts[i]);
        }
        
        result.add(descParts.join(' ')); // DESCRIPCIÓN
        result.add(''); // SUCURSAL (empty for this format)
        result.add(''); // DCTO (empty for this format)
        result.add(parts[valorIndex]); // VALOR
        result.add(parts[saldoIndex]); // SALDO
      } else {
        // Fallback: assume first 6 parts
        result.addAll(parts.take(6));
      }
    } else {
      // Not enough parts, return as-is
      result.addAll(parts);
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
    // Create case-insensitive field map
    final fieldMap = <String, String>{};
    for (int i = 0; i < header.length && i < values.length; i++) {
      fieldMap[header[i].toLowerCase()] = values[i];
    }
    final mapping = bank.csvFieldMapping;

    print('🔍 Debug - Header: $header');
    print('🔍 Debug - Values: $values');
    print('🔍 Debug - Field map: $fieldMap');
    print('🔍 Debug - Bank mapping: $mapping');

    // Parse amount with special handling for Nu Bank Colombia format
    String amountStr = fieldMap[mapping['amount']!.toLowerCase()]!;
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
    } else if (bank.name.contains('Bancolombia')) {
      // Handle Bancolombia format: amounts can be positive or negative
      // Format: 123,456.78 (comma as thousands separator, dot as decimal separator)
      // Remove quotes if present
      amountStr = amountStr.replaceAll('"', '');
      
      // Check if amount is negative
      final isNegative = amountStr.startsWith('-');
      
      // Remove negative sign for parsing
      if (isNegative) {
        amountStr = amountStr.substring(1);
      }
      
      // Handle Bancolombia number format: comma as thousands separator, dot as decimal separator
      // This is the standard US/international format, not Colombian format
      // Just remove commas (thousands separators) and keep dots as decimal separators
      amountStr = amountStr.replaceAll(',', '');
      amount = double.parse(amountStr);
      
      print('🔍 Debug - Bancolombia amount parsed: $amount (original: ${fieldMap[mapping['amount']!.toLowerCase()]!})');
      
      // Determine transaction type based on sign
      if (isNegative) {
        type = TransactionType.expense;
      } else {
        type = TransactionType.income;
      }
    } else if (bank.name == 'Banco de Occidente') {
      // Handle Banco de Occidente format: "X,XXX.XX" (comma as thousands separator, dot as decimal)
      // Remove quotes if present
      amountStr = amountStr.replaceAll('"', '');
      
      // In this CSV format: comma is thousands separator, dot is decimal separator
      // Convert to standard format: remove commas (thousands separators) and keep dot as decimal
      amountStr = amountStr.replaceAll(',', '');
      amount = double.parse(amountStr);
      
      // For Banco de Occidente, all amounts are expenses (credit card transactions)
      // Negative amounts in "CARGOS Y ABONOS" column indicate payments/credits (income)
      // Positive amounts indicate charges/purchases (expenses)
      if (amount < 0) {
        type = TransactionType.income;
        amount = amount.abs(); // Store as positive
      } else {
        type = TransactionType.expense;
      }
    } else {
      // Standard parsing for other banks
      amountStr = amountStr.replaceAll(RegExp(r'[^\d.-]'), '');
      amount = double.parse(amountStr);
      
      // Parse type (if provided, otherwise infer from amount)
      type = mapping['type'] != null
          ? fieldMap[mapping['type']!.toLowerCase()]!.toLowerCase().contains('income') ||
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
      final categoryName = fieldMap[mapping['category']!.toLowerCase()]!.toLowerCase();
      categoryId = categoryNameToId[categoryName];
    }
    categoryId ??= categoryNameToId.entries.first.value; // Default to first category if not found

    // Parse date with special handling for Nu Bank Colombia format
    final dateStr = fieldMap[mapping['date']!.toLowerCase()]!;
    DateTime date;
    
    if (bank.name == 'Nu Bank Colombia') {
      // Handle Spanish date format: "dd mmm" (e.g., "01 jun")
      date = _parseSpanishDate(dateStr);
    } else if (bank.name == 'Bancolombia' || bank.name == 'Banco de Occidente') {
      // Handle DD/MM format (e.g., "26/06" or "1/04")
      date = _parseDayMonthDate(dateStr);
    } else if (bank.dateFormat != null) {
      date = DateFormat(bank.dateFormat).parse(dateStr);
    } else {
      date = DateTime.parse(dateStr);
    }

    return Transaction(
      id: _uuid.v4(),
      description: fieldMap[mapping['description']!.toLowerCase()]!,
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

  static DateTime _parseDayMonthDate(String dateStr) {
    // Handle DD/MM format (e.g., "26/06")
    final parts = dateStr.trim().split('/');
    if (parts.length != 2) {
      throw Exception('Invalid DD/MM date format: $dateStr');
    }

    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    
    // Use current year as Banco de Occidente statements typically show current year transactions
    final year = DateTime.now().year;
    
    return DateTime(year, month, day);
  }
}