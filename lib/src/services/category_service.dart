import 'package:flutter/material.dart';
import '../models/models.dart';

class CategoryService extends ChangeNotifier {
  final List<Category> _categories = [];
  final List<MediaItem> _allMediaItems = [];

  List<Category> get categories => List.unmodifiable(_categories);
  List<MediaItem> get allMediaItems => List.unmodifiable(_allMediaItems);

  CategoryService() {
    _initializeDefaultCategories();
  }

  void _initializeDefaultCategories() {
    _categories.addAll([
      Category(
        id: 'default_video',
        name: '默认分类',
        type: MediaType.video,
        createdAt: DateTime.now(),
      ),
      Category(
        id: 'default_audio',
        name: '默认分类',
        type: MediaType.audio,
        createdAt: DateTime.now(),
      ),
    ]);
  }

  List<Category> getCategoriesByType(MediaType type) {
    return _categories.where((cat) => cat.type == type).toList();
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  Category? getDefaultCategory(MediaType type) {
    final defaultId =
        type == MediaType.video ? 'default_video' : 'default_audio';
    return getCategoryById(defaultId);
  }

  Category createCategory({
    required String name,
    required MediaType type,
  }) {
    final id = '${type.name}_${DateTime.now().millisecondsSinceEpoch}';
    final category = Category(
      id: id,
      name: name,
      type: type,
      createdAt: DateTime.now(),
    );
    _categories.add(category);
    notifyListeners();
    return category;
  }

  Category updateCategory({
    required String id,
    required String name,
  }) {
    final index = _categories.indexWhere((cat) => cat.id == id);
    if (index == -1) {
      throw Exception('Category not found');
    }

    final existingCategory = _categories[index];
    final updatedCategory = existingCategory.copyWith(
      name: name,
      updatedAt: DateTime.now(),
    );

    _categories[index] = updatedCategory;
    notifyListeners();
    return updatedCategory;
  }

  void deleteCategory(String id) {
    final category = getCategoryById(id);
    if (category == null) return;

    final isDefault = id == 'default_video' || id == 'default_audio';
    if (isDefault) {
      throw Exception('Cannot delete default category');
    }

    final defaultCategory = getDefaultCategory(category.type);
    if (defaultCategory != null) {
      for (var item in _allMediaItems) {
        if (item.categoryId == id) {
          final index = _allMediaItems.indexOf(item);
          _allMediaItems[index] = item.copyWith(categoryId: defaultCategory.id);
        }
      }
    }

    _categories.removeWhere((cat) => cat.id == id);
    notifyListeners();
  }

  List<MediaItem> getMediaItemsByCategory(String categoryId) {
    return _allMediaItems
        .where((item) => item.categoryId == categoryId)
        .toList();
  }

  void addMediaItem(MediaItem item, {String? categoryId}) {
    final type = item.type;
    final targetCategoryId = categoryId ?? getDefaultCategory(type)?.id;

    if (targetCategoryId == null) {
      throw Exception('No category available for media type');
    }

    final category = getCategoryById(targetCategoryId);
    if (category == null) {
      throw Exception('Category not found');
    }

    if (category.type != type) {
      throw Exception('Media type does not match category type');
    }

    final existingIndex = _allMediaItems.indexWhere((i) => i.id == item.id);
    if (existingIndex != -1) {
      _allMediaItems[existingIndex] =
          item.copyWith(categoryId: targetCategoryId);
    } else {
      _allMediaItems.add(item.copyWith(categoryId: targetCategoryId));
    }
    notifyListeners();
  }

  void addMediaItems(List<MediaItem> items, {String? categoryId}) {
    for (var item in items) {
      addMediaItem(item, categoryId: categoryId);
    }
  }

  void removeMediaItem(String itemId) {
    _allMediaItems.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void moveMediaItemToCategory(String itemId, String targetCategoryId) {
    final itemIndex = _allMediaItems.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;

    final item = _allMediaItems[itemIndex];
    final targetCategory = getCategoryById(targetCategoryId);
    if (targetCategory == null) return;

    if (targetCategory.type != item.type) {
      throw Exception('Media type does not match category type');
    }

    _allMediaItems[itemIndex] = item.copyWith(categoryId: targetCategoryId);
    notifyListeners();
  }

  void clearCategory(String categoryId) {
    _allMediaItems.removeWhere((item) => item.categoryId == categoryId);
    notifyListeners();
  }

  int getMediaItemCount(String categoryId) {
    return _allMediaItems.where((item) => item.categoryId == categoryId).length;
  }
}
