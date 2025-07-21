import 'dart:convert';
import 'dart:html' as html;
import '../models/transaction.dart';
import '../models/category.dart';
import 'web_storage_service.dart';

class ExportService {
  static Future<void> exportToJson() async {
    try {
      final transactions = await WebStorageService.getTransactions();
      final categories = await WebStorageService.getCategories();
      
      final data = {
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
      };
      
      final jsonString = json.encode(data);
      _downloadFile(jsonString, 'expense_tracker_data.json', 'application/json');
    } catch (e) {
      print('Error exporting to JSON: $e');
      throw e;
    }
  }

  static Future<void> exportToCsv() async {
    try {
      final transactions = await WebStorageService.getTransactions();
      final categories = await WebStorageService.getCategories();
      
      final categoryMap = {for (var c in categories) c.id: c.name};
      
      final csvContent = StringBuffer();
      csvContent.writeln('Date,Description,Amount,Type,Category');
      
      for (final transaction in transactions) {
        final categoryName = categoryMap[transaction.categoryId] ?? 'Unknown';
        final type = transaction.type.toString().split('.').last;
        
        csvContent.writeln(
          '${transaction.date.toIso8601String().split('T')[0]},'
          '"${transaction.description}",'
          '${transaction.amount},'
          '$type,'
          '"$categoryName"'
        );
      }
      
      _downloadFile(csvContent.toString(), 'expense_tracker_data.csv', 'text/csv');
    } catch (e) {
      print('Error exporting to CSV: $e');
      throw e;
    }
  }

  static Future<void> exportToExcel() async {
    try {
      final transactions = await WebStorageService.getTransactions();
      final categories = await WebStorageService.getCategories();
      
      final categoryMap = {for (var c in categories) c.id: c.name};
      
      final csvContent = StringBuffer();
      csvContent.writeln('Date\tDescription\tAmount\tType\tCategory');
      
      for (final transaction in transactions) {
        final categoryName = categoryMap[transaction.categoryId] ?? 'Unknown';
        final type = transaction.type.toString().split('.').last;
        
        csvContent.writeln(
          '${transaction.date.toIso8601String().split('T')[0]}\t'
          '${transaction.description}\t'
          '${transaction.amount}\t'
          '$type\t'
          '$categoryName'
        );
      }
      
      _downloadFile(csvContent.toString(), 'expense_tracker_data.xlsx', 'application/vnd.ms-excel');
    } catch (e) {
      print('Error exporting to Excel: $e');
      throw e;
    }
  }

  static void _downloadFile(String content, String filename, String mimeType) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    
    html.Url.revokeObjectUrl(url);
  }

  static Future<Map<String, dynamic>> getExportSummary() async {
    try {
      final transactions = await WebStorageService.getTransactions();
      final categories = await WebStorageService.getCategories();
      
      return {
        'totalTransactions': transactions.length,
        'totalCategories': categories.length,
        'dateRange': transactions.isNotEmpty ? {
          'from': transactions.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String(),
          'to': transactions.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String(),
        } : null,
      };
    } catch (e) {
      print('Error getting export summary: $e');
      return {};
    }
  }
}