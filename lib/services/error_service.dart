import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum ErrorSeverity { low, medium, high, critical }

class ErrorService {
  static final List<AppError> _errorLog = [];
  static BuildContext? _context;
  
  static void initialize(BuildContext context) {
    _context = context;
  }
  
  static void logError(
    String message, 
    dynamic error, 
    StackTrace? stackTrace, {
    ErrorSeverity severity = ErrorSeverity.medium,
    String? source,
  }) {
    final appError = AppError(
      message: message,
      error: error,
      stackTrace: stackTrace,
      severity: severity,
      source: source ?? 'Unknown',
      timestamp: DateTime.now(),
    );
    
    _errorLog.add(appError);
    
    // Log to console in debug mode
    if (kDebugMode) {
      print('🚨 [${severity.name.toUpperCase()}] $source: $message');
      if (error != null) print('Error: $error');
      if (stackTrace != null) print('Stack: ${stackTrace.toString().substring(0, 200)}...');
    }
    
    // Show user-friendly message for critical errors
    if (severity == ErrorSeverity.critical && _context != null) {
      _showErrorDialog(message);
    }
  }
  
  static void _showErrorDialog(String message) {
    if (_context == null) return;
    
    showDialog(
      context: _context!,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  static List<AppError> getErrorLog() => List.unmodifiable(_errorLog);
  
  static void clearErrorLog() => _errorLog.clear();
}

class AppError {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  final ErrorSeverity severity;
  final String source;
  final DateTime timestamp;
  
  AppError({
    required this.message,
    required this.error,
    required this.stackTrace,
    required this.severity,
    required this.source,
    required this.timestamp,
  });
}