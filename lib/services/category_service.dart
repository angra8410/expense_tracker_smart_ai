import '../models/category.dart';
import 'web_storage_service.dart';
import 'app_initialization_service.dart';

class CategoryService {
  static Future<List<Category>> getCategories() async {
    // First try to get categories from storage
    List<Category> categories = await WebStorageService.getCategories();
    
    // If no categories exist, initialize with default categories
    if (categories.isEmpty) {
      categories = AppInitializationService.getDefaultCategories();
      await saveCategories(categories);
    }
    
    return categories;
  }

  static Future<void> addCategory(Category category) async {
    await WebStorageService.addCategory(category);
  }

  static Future<void> saveCategories(List<Category> categories) async {
    await WebStorageService.saveCategories(categories);
  }

  static Future<Category?> getCategoryById(String id) async {
    final categories = await getCategories();
    try {
      return categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }
}