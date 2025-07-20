// ignore: avoid_web_libraries_in_flutter
import 'dart:html' if (dart.library.io) 'web_storage_stub.dart' show window;
import 'package:flutter/foundation.dart';

class WebStorageBase {
  static void setItem(String key, String value) {
    if (kIsWeb && window != null) {
      window.localStorage[key] = value;
    }
  }

  static String? getItem(String key) {
    if (kIsWeb && window != null) {
      return window.localStorage[key];
    }
    return null;
  }
}