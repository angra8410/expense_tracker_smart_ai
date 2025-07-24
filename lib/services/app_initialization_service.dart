import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/bank_service.dart';
import '../services/country_bank_service.dart';

class AppInitializationService {
  static Future<void> initialize() async {
    // Initialize default banks
    await BankService.initializeDefaultBanks();
    
    // Initialize country-based banks
    await CountryBankService.initializeCountryBanks();
  }

  static Future<List<Category>> getCategories() async {
    // Replace with your persistent storage logic if needed.
    // This returns the default set for demonstration.
    return getDefaultCategories();
  }

  static List<Category> getDefaultCategories() {
    return [
      Category(
        id: 'food',
        name: 'Food & Dining', // Use English as base - will be localized in UI
        iconCodePoint: Icons.restaurant.codePoint,
        iconFontFamily: Icons.restaurant.fontFamily,
        colorValue: Colors.deepOrange.value,
      ),
      Category(
        id: 'transport',
        name: 'Transportation',
        iconCodePoint: Icons.directions_car.codePoint,
        iconFontFamily: Icons.directions_car.fontFamily,
        colorValue: Colors.blue.value,
      ),
      Category(
        id: 'shopping',
        name: 'Shopping',
        iconCodePoint: Icons.shopping_bag.codePoint,
        iconFontFamily: Icons.shopping_bag.fontFamily,
        colorValue: Colors.purple.value,
      ),
      Category(
        id: 'entertainment',
        name: 'Entertainment',
        iconCodePoint: Icons.movie.codePoint,
        iconFontFamily: Icons.movie.fontFamily,
        colorValue: Colors.redAccent.value,
      ),
      Category(
        id: 'bills',
        name: 'Bills & Utilities',
        iconCodePoint: Icons.receipt.codePoint,
        iconFontFamily: Icons.receipt.fontFamily,
        colorValue: Colors.teal.value,
      ),
      Category(
        id: 'health',
        name: 'Health & Fitness',
        iconCodePoint: Icons.favorite.codePoint,
        iconFontFamily: Icons.favorite.fontFamily,
        colorValue: Colors.pink.value,
      ),
      Category(
        id: 'salary',
        name: 'Salary',
        iconCodePoint: Icons.attach_money.codePoint,
        iconFontFamily: Icons.attach_money.fontFamily,
        colorValue: Colors.green.value,
      ),
      Category(
        id: 'investment',
        name: 'Investments',
        iconCodePoint: Icons.trending_up.codePoint,
        iconFontFamily: Icons.trending_up.fontFamily,
        colorValue: Colors.amber.value,
      ),
      Category(
        id: 'education',
        name: 'Education',
        iconCodePoint: Icons.school.codePoint,
        iconFontFamily: Icons.school.fontFamily,
        colorValue: Colors.indigo.value,
      ),
      Category(
        id: 'gift',
        name: 'Gifts & Donations',
        iconCodePoint: Icons.card_giftcard.codePoint,
        iconFontFamily: Icons.card_giftcard.fontFamily,
        colorValue: Colors.brown.value,
      ),
      Category(
        id: 'other',
        name: 'Other',
        iconCodePoint: Icons.category.codePoint,
        iconFontFamily: Icons.category.fontFamily,
        colorValue: Colors.grey.value,
      ),
    ];
  }
}