import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/bank_service.dart';

class AppInitializationService {
  static Future<void> initialize() async {
    // Initialize default banks
    await BankService.initializeDefaultBanks();
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
        name: 'Comida y Restaurantes',
        iconCodePoint: Icons.restaurant.codePoint,
        iconFontFamily: Icons.restaurant.fontFamily,
        colorValue: Colors.deepOrange.value,
      ),
      Category(
        id: 'transport',
        name: 'Transporte',
        iconCodePoint: Icons.directions_car.codePoint,
        iconFontFamily: Icons.directions_car.fontFamily,
        colorValue: Colors.blue.value,
      ),
      Category(
        id: 'shopping',
        name: 'Compras',
        iconCodePoint: Icons.shopping_bag.codePoint,
        iconFontFamily: Icons.shopping_bag.fontFamily,
        colorValue: Colors.purple.value,
      ),
      Category(
        id: 'entertainment',
        name: 'Entretenimiento',
        iconCodePoint: Icons.movie.codePoint,
        iconFontFamily: Icons.movie.fontFamily,
        colorValue: Colors.redAccent.value,
      ),
      Category(
        id: 'bills',
        name: 'Facturas y Servicios',
        iconCodePoint: Icons.receipt.codePoint,
        iconFontFamily: Icons.receipt.fontFamily,
        colorValue: Colors.teal.value,
      ),
      Category(
        id: 'health',
        name: 'Salud y Fitness',
        iconCodePoint: Icons.favorite.codePoint,
        iconFontFamily: Icons.favorite.fontFamily,
        colorValue: Colors.pink.value,
      ),
      Category(
        id: 'salary',
        name: 'Salario',
        iconCodePoint: Icons.attach_money.codePoint,
        iconFontFamily: Icons.attach_money.fontFamily,
        colorValue: Colors.green.value,
      ),
      Category(
        id: 'investment',
        name: 'Inversiones',
        iconCodePoint: Icons.trending_up.codePoint,
        iconFontFamily: Icons.trending_up.fontFamily,
        colorValue: Colors.amber.value,
      ),
      Category(
        id: 'education',
        name: 'Educación',
        iconCodePoint: Icons.school.codePoint,
        iconFontFamily: Icons.school.fontFamily,
        colorValue: Colors.indigo.value,
      ),
      Category(
        id: 'gift',
        name: 'Regalos y Donaciones',
        iconCodePoint: Icons.card_giftcard.codePoint,
        iconFontFamily: Icons.card_giftcard.fontFamily,
        colorValue: Colors.brown.value,
      ),
      Category(
        id: 'other',
        name: 'Otros',
        iconCodePoint: Icons.category.codePoint,
        iconFontFamily: Icons.category.fontFamily,
        colorValue: Colors.grey.value,
      ),
    ];
  }
}