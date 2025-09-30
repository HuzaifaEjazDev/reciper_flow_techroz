import 'package:flutter/material.dart';
import 'package:recipe_app/models/user/user_recipe.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';

class MyRecipeCardData {
  final String title;
  final String imageAssetPath;
  final int ingredientsCount;
  final int stepsCount;
  final UserRecipe? recipe;
  MyRecipeCardData({
    required this.title,
    required this.imageAssetPath,
    required this.ingredientsCount,
    required this.stepsCount,
    this.recipe,
  });
}

class MyRecipesViewModel extends ChangeNotifier {
  MyRecipesViewModel({FirestoreRecipesService? service})
      : _service = service ?? FirestoreRecipesService();

  final FirestoreRecipesService _service;

  final List<MyRecipeCardData> _allItems = <MyRecipeCardData>[];
  final List<MyRecipeCardData> _items = <MyRecipeCardData>[];
  bool _loading = false;
  String? _error;
  String _query = '';
  String? _lastId;
  bool _hasMore = true;

  // Sort/filter options
  List<String> _mealTypes = const [];
  List<String> _diets = const [];
  List<String> _cuisines = const [];
  List<String> _tags = const [];
  String? _selectedMealType;
  String? _selectedDiet;
  String? _selectedCuisine;
  String? _selectedTag;

  List<MyRecipeCardData> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  List<String> get mealTypes => _mealTypes;
  List<String> get diets => _diets;
  List<String> get cuisines => _cuisines;
  List<String> get tags => _tags;
  String? get selectedMealType => _selectedMealType;
  String? get selectedDiet => _selectedDiet;
  String? get selectedCuisine => _selectedCuisine;
  String? get selectedTag => _selectedTag;

  Future<void> loadFromFirestore({String collection = 'recipes'}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    _lastId = null;
    _hasMore = true;
    notifyListeners();
    try {
      final page = await _service.fetchRecipesPage(collection: collection, limit: 10);
      _lastId = page.lastId;
      _hasMore = page.lastId != null;
      _allItems
        ..clear()
        ..addAll(page.items.map((m) => _mapToCard(m)));
      _applyFilter();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore({String collection = 'recipes'}) async {
    if (_loading || !_hasMore) return;
    _loading = true;
    notifyListeners();
    try {
      final page = await _service.fetchRecipesPage(
        collection: collection,
        limit: 10,
        startAfterId: _lastId,
      );
      _lastId = page.lastId;
      _hasMore = page.lastId != null;
      _allItems.addAll(page.items.map((m) => _mapToCard(m)));
      _applyFilter();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadSortOptions() async {
    try {
      final results = await Future.wait<List<String>>([
        _service.fetchCollectionStrings('meal_types'),
        _service.fetchCollectionStrings('diets'),
        _service.fetchCollectionStrings('cuisines'),
        _service.fetchCollectionStrings('special_tags'),
      ]);
      _mealTypes = results[0];
      _diets = results[1];
      _cuisines = results[2];
      _tags = results[3];
      notifyListeners();
    } catch (_) {}
  }

  MyRecipeCardData _mapToCard(Map<String, dynamic> m) {
    final String title = (m['title'] ?? '').toString();
    final String imageUrl = (m['imageUrl'] ?? m['image'] ?? '').toString();
    final int ingredientsCount = _pickFirstInt(
          m,
          keys: const ['ingredientsTotal', 'ingredients_total', 'ingredientsCount', 'ingredients_count'],
        ) ?? _listLength(m, keys: const ['ingredients', 'ingredientsList']);
    final int stepsCount = _pickFirstInt(
          m,
          keys: const ['instructionsTotal', 'instructions_total', 'stepsTotal', 'steps_total', 'stepsCount', 'steps_count'],
        ) ?? _listLength(m, keys: const ['instructions', 'steps']);

    return MyRecipeCardData(
      title: title.isEmpty ? 'Untitled Recipe' : title,
      imageAssetPath: imageUrl,
      ingredientsCount: ingredientsCount,
      stepsCount: stepsCount,
      recipe: null,
    );
  }

  int? _safeInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  int? _pickFirstInt(Map<String, dynamic> m, {required List<String> keys}) {
    for (final k in keys) {
      final v = _safeInt(m[k]);
      if (v != null) return v;
    }
    return null;
  }

  int _listLength(Map<String, dynamic> m, {required List<String> keys}) {
    for (final k in keys) {
      final v = m[k];
      if (v is List) return v.length;
    }
    return 0;
  }

  void add(MyRecipeCardData card) {
    _allItems.add(card);
    _applyFilter();
  }

  void setSearchQuery(String query) {
    _query = query;
    _applyFilter();
  }

  void _applyFilter() {
    final q = _query.trim().toLowerCase();
    _items
      ..clear()
      ..addAll(q.isEmpty ? _allItems : _allItems.where((e) => e.title.toLowerCase().contains(q)));
    notifyListeners();
  }

  void setSelectedMealType(String? v) { _selectedMealType = v; notifyListeners(); }
  void setSelectedDiet(String? v) { _selectedDiet = v; notifyListeners(); }
  void setSelectedCuisine(String? v) { _selectedCuisine = v; notifyListeners(); }
  void setSelectedTag(String? v) { _selectedTag = v; notifyListeners(); }
}


