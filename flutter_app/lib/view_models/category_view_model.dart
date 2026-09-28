import 'package:flutter/material.dart';
import '../models/category_info.dart';
import '../services/storage_service.dart';

class CategoryViewModel extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<CategoryInfo> categories = [];

  Future<void> init() async {
    final loaded = await _storageService.loadCategories();
    if (loaded != null) {
      categories = loaded;
    } else {
      categories = [...kExpenseCategories, ...kIncomeCategories];
      await _storageService.saveCategories(categories);
    }
    notifyListeners();
  }

  CategoryInfo getCategoryInfo(String name) {
    for (final c in categories) {
      if (c.name == name) return c;
    }
    return const CategoryInfo(name: '기타', emoji: '📌', color: Color(0xFF94A3B8), type: 'expense');
  }

  void addCategory(CategoryInfo cat) {
    categories.add(cat);
    _storageService.saveCategories(categories);
    notifyListeners();
  }

  void updateCategory(CategoryInfo cat, String oldName) {
    final idx = categories.indexWhere((e) => e.name == oldName);
    if (idx != -1) {
      categories[idx] = cat;
      _storageService.saveCategories(categories);
      notifyListeners();
    }
  }

  void deleteCategory(String name) {
    categories.removeWhere((e) => e.name == name);
    _storageService.saveCategories(categories);
    notifyListeners();
  }
}
