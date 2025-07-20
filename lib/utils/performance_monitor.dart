import 'dart:developer' as developer;

class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  
  static void startTimer(String operation) {
    _startTimes[operation] = DateTime.now();
    print('🚀 Starting: $operation');
  }
  
  static void endTimer(String operation) {
    final startTime = _startTimes[operation];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      print('⏱️ $operation took: ${duration.inMilliseconds}ms');
      
      // Log slow operations
      if (duration.inMilliseconds > 1000) {
        print('⚠️ SLOW OPERATION: $operation took ${duration.inMilliseconds}ms');
      }
      
      _startTimes.remove(operation);
    }
  }
  
  static Future<T> measureAsync<T>(String operation, Future<T> Function() function) async {
    startTimer(operation);
    try {
      final result = await function();
      endTimer(operation);
      return result;
    } catch (e) {
      endTimer(operation);
      rethrow;
    }
  }
}