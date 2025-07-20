import 'dart:async';

class PerformanceService {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, Timer> _cacheTimers = {};
  
  /// Cache data with expiration
  static void cacheData(String key, dynamic data, {Duration? expiration}) {
    _cache[key] = data;
    
    if (expiration != null) {
      _cacheTimers[key]?.cancel();
      _cacheTimers[key] = Timer(expiration, () {
        _cache.remove(key);
        _cacheTimers.remove(key);
      });
    }
  }
  
  /// Get cached data
  static T? getCachedData<T>(String key) {
    return _cache[key] as T?;
  }
  
  /// Clear cache
  static void clearCache() {
    _cache.clear();
    for (var timer in _cacheTimers.values) {
      timer.cancel();
    }
    _cacheTimers.clear();
  }
  
  /// Debounce function calls
  static Timer? _debounceTimer;
  static void debounce(VoidCallback callback, {Duration delay = const Duration(milliseconds: 500)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }
}