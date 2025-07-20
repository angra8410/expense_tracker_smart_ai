import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/category.dart';

class CategoryLocalization {
  static String getLocalizedCategoryName(BuildContext context, String categoryId) {
    final l10n = AppLocalizations.of(context)!;
    
    switch (categoryId) {
      case 'food':
        return l10n.categoryFood;
      case 'transport':
        return l10n.categoryTransport;
      case 'shopping':
        return l10n.categoryShopping;
      case 'entertainment':
        return l10n.categoryEntertainment;
      case 'bills':
        return l10n.categoryBills;
      case 'health':
        return l10n.categoryHealth;
      case 'salary':
        return l10n.categorySalary;
      case 'investment':
        return l10n.categoryInvestment;
      case 'education':
        return l10n.categoryEducation;
      case 'gift':
        return l10n.categoryGift;
      case 'other':
        return l10n.categoryOther;
      default:
        // Fallback to the original category name if no translation is found
        return categoryId;
    }
  }

  static String getLocalizedCategoryNameFromCategory(BuildContext context, Category category) {
    return getLocalizedCategoryName(context, category.id);
  }
}