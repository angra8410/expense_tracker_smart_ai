import 'dart:convert';
<<<<<<< HEAD
import 'dart:html' as html;
=======
import 'package:flutter/foundation.dart';
>>>>>>> dd0532278731c5cc55e6d7f669d18270155e542b
import 'package:shared_preferences/shared_preferences.dart';
import 'web_storage_base.dart';

class WebStorageService {
  static WebStorageService? _instance;
  late SharedPreferences _prefs;
  static BuildContext? _context;

  WebStorageService._();

  static Future<void> initialize() async {
    if (_instance == null) {
      _instance = WebStorageService._();
      await _instance!._init();
    }
  }

<<<<<<< HEAD
  // Generic Data Storage Methods
  static Future<String?> getString(String key) async {
    return _prefs?.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  static Future<dynamic> getData(String key) async {
    final jsonString = _prefs?.getString(key);
    if (jsonString == null) return null;
    return json.decode(jsonString);
  }

  static Future<void> saveData(String key, dynamic data) async {
    final jsonString = json.encode(data);
    await _prefs?.setString(key, jsonString);
  }

  // Categories Management
  static Future<List<Category>> getCategories() async {
    final categoriesJson = _prefs?.getString(_categoriesKey);
    if (categoriesJson == null) return [];
    
    final List<dynamic> categoriesList = json.decode(categoriesJson);
    return categoriesList.map((json) => Category.fromJson(json)).toList();
=======
  static void setContext(BuildContext context) {
    _context = context;
>>>>>>> dd0532278731c5cc55e6d7f669d18270155e542b
  }

  static Future<WebStorageService> getInstance() async {
    if (_instance == null) {
      await initialize();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    if (kIsWeb) {
      await _restoreFromLocalStorageIfNeeded();
    }
  }

  Future<void> setValue(String key, dynamic value) async {
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    } else {
      final jsonStr = jsonEncode(value);
      await _prefs.setString(key, jsonStr);
    }

    if (kIsWeb) {
      await _backupAllDataToLocalStorage();
    }
  }

<<<<<<< HEAD
  static Future<void> saveTransactions(List<Transaction> transactions) async {
    final transactionsJson = json.encode(transactions.map((t) => t.toJson()).toList());
    await _prefs?.setString(_transactionsKey, transactionsJson);
  }
  
  static Future<void> addTransaction(Transaction transaction) async {
    try {
      final transactions = await getTransactions();
      transactions.add(transaction);
      await saveTransactions(transactions);
      print('✅ Single transaction added: ${transaction.description}');
    } catch (e) {
      print('❌ Error adding single transaction: $e');
      throw e;
    }
  }

  static Future<void> addTransactions(List<Transaction> newTransactions) async {
    final transactions = await getTransactions();
    transactions.addAll(newTransactions);
    await saveTransactions(transactions);
=======
  Future<void> _backupAllDataToLocalStorage() async {
    if (kIsWeb) {
      final allData = _prefs.getKeys().map((key) {
        return MapEntry(key, _prefs.get(key));
      }).toList();

      final jsonStr = jsonEncode(allData);
      WebStorageBase.setItem('shared_preferences_backup', jsonStr);
    }
>>>>>>> dd0532278731c5cc55e6d7f669d18270155e542b
  }

  Future<void> _restoreFromLocalStorageIfNeeded() async {
    if (kIsWeb) {
      final backupStr = WebStorageBase.getItem('shared_preferences_backup');
      if (backupStr != null) {
        try {
          final List<dynamic> allData = jsonDecode(backupStr);
          for (final entry in allData) {
            final key = entry['key'] as String;
            final value = entry['value'];
            await setValue(key, value);
          }
        } catch (e) {
          print('Error restoring from localStorage: $e');
        }
      }
    }
  }

  dynamic getValue(String key, {dynamic defaultValue}) {
    return _prefs.get(key) ?? defaultValue;
  }

  Future<void> removeValue(String key) async {
    await _prefs.remove(key);
    if (kIsWeb) {
      await _backupAllDataToLocalStorage();
    }
  }

  Future<void> clear() async {
    await _prefs.clear();
    if (kIsWeb) {
      WebStorageBase.setItem('shared_preferences_backup', '[]');
    }
  }

  /// Get a list from storage
  static Future<List<Map<String, dynamic>>> getList(String key) async {
    try {
      final jsonString = html.window.localStorage[key];
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting list from storage: $e');
      return [];
    }
  }

  /// Save a list to storage
  static Future<void> saveList(String key, List<Map<String, dynamic>> data) async {
    try {
      final jsonString = jsonEncode(data);
      html.window.localStorage[key] = jsonString;
    } catch (e) {
      print('Error saving list to storage: $e');
    }
  }

  /// Get a map from storage
  static Future<Map<String, dynamic>> getMap(String key) async {
    try {
      final jsonString = html.window.localStorage[key];
      if (jsonString == null) return {};
      
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error getting map from storage: $e');
      return {};
    }
  }

  /// Save a map to storage
  static Future<void> saveMap(String key, Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      html.window.localStorage[key] = jsonString;
    } catch (e) {
      print('Error saving map to storage: $e');
    }
  }
}