import 'dart:convert';
import 'dart:html' as html;
import '../models/transaction.dart';
import '../services/web_storage_service.dart';

class ExportService {
  static Future<void> exportToJson() async {
    try {
      final transactions = await WebStorageService.getTransactions(includeTestData: false);
      final categories = await WebStorageService.getCategories();
      
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'transactions': transactions.map((tx) => tx.toJson()).toList(),
        'categories': categories.map((cat) => cat.toJson()).toList(),
        'summary': {
          'totalTransactions': transactions.length,
          'totalIncome': transactions
              .where((tx) => tx.type == TransactionType.income)
              .fold(0.0, (sum, tx) => sum + tx.amount),
          'totalExpenses': transactions
              .where((tx) => tx.type == TransactionType.expense)
              .fold(0.0, (sum, tx) => sum + tx.amount.abs()),
        }
      };
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      _downloadFile(jsonString, 'expense_tracker_export.json', 'application/json');
    } catch (e) {
      throw Exception('Failed to export to JSON: $e');
    }
  }

  static Future<void> exportToCsv() async {
    try {
      final transactions = await WebStorageService.getTransactions(includeTestData: false);
      final categories = await WebStorageService.getCategories();
      
      // Create category lookup map
      final categoryMap = {for (var cat in categories) cat.id: cat.name};
      
      final csvLines = <String>[];
      
      // Add header
      csvLines.add('ID,Description,Amount,Type,Category,Date');
      
      // Add transaction data
      for (final tx in transactions) {
        final categoryName = categoryMap[tx.categoryId] ?? 'Unknown';
        final csvLine = [
          '"${tx.id}"',
          '"${tx.description.replaceAll('"', '""')}"', // Escape quotes
          tx.amount.toString(),
          tx.type.toString().split('.').last,
          '"${categoryName.replaceAll('"', '""')}"',
          tx.date.toIso8601String().split('T')[0], // Date only
        ].join(',');
        csvLines.add(csvLine);
      }
      
      final csvContent = csvLines.join('\n');
      _downloadFile(csvContent, 'expense_tracker_export.csv', 'text/csv');
    } catch (e) {
      throw Exception('Failed to export to CSV: $e');
    }
  }

  static Future<void> exportToExcel() async {
    try {
      final transactions = await WebStorageService.getTransactions(includeTestData: false);
      final categories = await WebStorageService.getCategories();
      
      // Create category lookup map
      final categoryMap = {for (var cat in categories) cat.id: cat.name};
      
      // Create a simple XML-based Excel file (SpreadsheetML)
      final xmlContent = _createExcelXml(transactions, categoryMap);
      
      _downloadFile(xmlContent, 'expense_tracker_export.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    } catch (e) {
      throw Exception('Failed to export to Excel: $e');
    }
  }

  static String _createExcelXml(List<Transaction> transactions, Map<String, String> categoryMap) {
    final buffer = StringBuffer();
    
    // Excel XML header
    buffer.writeln('<?xml version="1.0"?>');
    buffer.writeln('<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"');
    buffer.writeln('  xmlns:o="urn:schemas-microsoft-com:office:office"');
    buffer.writeln('  xmlns:x="urn:schemas-microsoft-com:office:excel"');
    buffer.writeln('  xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"');
    buffer.writeln('  xmlns:html="http://www.w3.org/TR/REC-html40">');
    
    // Styles
    buffer.writeln('<Styles>');
    buffer.writeln('<Style ss:ID="Header">');
    buffer.writeln('<Font ss:Bold="1"/>');
    buffer.writeln('<Interior ss:Color="#CCCCCC" ss:Pattern="Solid"/>');
    buffer.writeln('</Style>');
    buffer.writeln('<Style ss:ID="Income">');
    buffer.writeln('<Font ss:Color="#008000"/>');
    buffer.writeln('</Style>');
    buffer.writeln('<Style ss:ID="Expense">');
    buffer.writeln('<Font ss:Color="#FF0000"/>');
    buffer.writeln('</Style>');
    buffer.writeln('</Styles>');
    
    // Worksheet
    buffer.writeln('<Worksheet ss:Name="Transactions">');
    buffer.writeln('<Table>');
    
    // Header row
    buffer.writeln('<Row>');
    buffer.writeln('<Cell ss:StyleID="Header"><Data ss:Type="String">ID</Data></Cell>');
    buffer.writeln('<Cell ss:StyleID="Header"><Data ss:Type="String">Description</Data></Cell>');
    buffer.writeln('<Cell ss:StyleID="Header"><Data ss:Type="String">Amount</Data></Cell>');
    buffer.writeln('<Cell ss:StyleID="Header"><Data ss:Type="String">Type</Data></Cell>');
    buffer.writeln('<Cell ss:StyleID="Header"><Data ss:Type="String">Category</Data></Cell>');
    buffer.writeln('<Cell ss:StyleID="Header"><Data ss:Type="String">Date</Data></Cell>');
    buffer.writeln('</Row>');
    
    // Data rows
    for (final tx in transactions) {
      final categoryName = categoryMap[tx.categoryId] ?? 'Unknown';
      final styleId = tx.type == TransactionType.income ? 'Income' : 'Expense';
      
      buffer.writeln('<Row>');
      buffer.writeln('<Cell><Data ss:Type="String">${_escapeXml(tx.id)}</Data></Cell>');
      buffer.writeln('<Cell><Data ss:Type="String">${_escapeXml(tx.description)}</Data></Cell>');
      buffer.writeln('<Cell ss:StyleID="$styleId"><Data ss:Type="Number">${tx.amount}</Data></Cell>');
      buffer.writeln('<Cell><Data ss:Type="String">${tx.type.toString().split('.').last}</Data></Cell>');
      buffer.writeln('<Cell><Data ss:Type="String">${_escapeXml(categoryName)}</Data></Cell>');
      buffer.writeln('<Cell><Data ss:Type="String">${tx.date.toIso8601String().split('T')[0]}</Data></Cell>');
      buffer.writeln('</Row>');
    }
    
    buffer.writeln('</Table>');
    buffer.writeln('</Worksheet>');
    buffer.writeln('</Workbook>');
    
    return buffer.toString();
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static void _downloadFile(String content, String filename, String mimeType) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  static Future<Map<String, dynamic>> getExportSummary() async {
    try {
      final transactions = await WebStorageService.getTransactions(includeTestData: false);
      final categories = await WebStorageService.getCategories();
      
      final totalIncome = transactions
          .where((tx) => tx.type == TransactionType.income)
          .fold(0.0, (sum, tx) => sum + tx.amount);
      
      final totalExpenses = transactions
          .where((tx) => tx.type == TransactionType.expense)
          .fold(0.0, (sum, tx) => sum + tx.amount.abs());
      
      return {
        'totalTransactions': transactions.length,
        'totalCategories': categories.length,
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'netBalance': totalIncome - totalExpenses,
        'dateRange': transactions.isNotEmpty ? {
          'earliest': transactions.map((tx) => tx.date).reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String().split('T')[0],
          'latest': transactions.map((tx) => tx.date).reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String().split('T')[0],
        } : null,
      };
    } catch (e) {
      throw Exception('Failed to get export summary: $e');
    }
  }
}