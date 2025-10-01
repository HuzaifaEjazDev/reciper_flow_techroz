import 'package:flutter/foundation.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';

class AdminRecipeCardData {
  final String id;
  final String title;
  final String imageUrl;
  final int minutes;
  final double rating;
  final int ingredientsCount;
  final int stepsCount;
  const AdminRecipeCardData({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.minutes,
    required this.rating,
    required this.ingredientsCount,
    required this.stepsCount,
  });
}

class AdminRecipesViewModel extends ChangeNotifier {
  AdminRecipesViewModel({FirestoreRecipesService? service})
      : _service = service ?? FirestoreRecipesService();

  final FirestoreRecipesService _service;

  final List<AdminRecipeCardData> _allItems = <AdminRecipeCardData>[];
  final List<AdminRecipeCardData> _items = <AdminRecipeCardData>[];
  String _query = '';
  String _activeServerQuery = '';
  String? _lastId;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;
  // Paging state
  final Map<int, String?> _pageToCursor = <int, String?>{1: null}; // page -> startAfterId (page 1 starts at null)
  int _currentPage = 1;
  final int _pageSize = 10;
  int _totalCount = 0;

  // Sort/filter options
  List<String> _mealTypes = const [];
  List<String> _diets = const [];
  List<String> _cuisines = const [];
  List<String> _tags = const [];
  String? _selectedMealType;
  String? _selectedDiet;
  String? _selectedCuisine;
  String? _selectedTag;
  bool _optionsLoading = false;

  List<AdminRecipeCardData> get items => List.unmodifiable(_items);
  bool get hasMore => _hasMore;
  bool get loading => _loading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalKnownPages => (_totalCount / _pageSize).ceil().clamp(1, 1000000);
  int get totalCount => _totalCount;
  int get totalPages => (_totalCount / _pageSize).ceil().clamp(1, 1000000);
  List<String> get mealTypes => _mealTypes;
  List<String> get diets => _diets;
  List<String> get cuisines => _cuisines;
  List<String> get tags => _tags;
  String? get selectedMealType => _selectedMealType;
  String? get selectedDiet => _selectedDiet;
  String? get selectedCuisine => _selectedCuisine;
  String? get selectedTag => _selectedTag;
  bool get optionsLoading => _optionsLoading;

  Future<void> loadInitial() async {
    _allItems.clear();
    _items.clear();
    _lastId = null;
    _hasMore = true;
    _pageToCursor
      ..clear()
      ..addAll({1: null});
    _currentPage = 1;
    await _loadTotalCount();
    await _loadPageAtCursor(startAfterId: _pageToCursor[_currentPage]);
  }

  // Backward compatibility (unused in new UI)
  Future<void> loadMore() async {
    if (_loading || !_hasMore) return;
    await goToPage(_currentPage + 1);
  }

  Future<void> _loadPageAtCursor({required String? startAfterId}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (_activeServerQuery.isNotEmpty) {
        final page = await _service.fetchRecipesPageByTitlePrefix(
          collection: 'recipes',
          prefix: _activeServerQuery,
          limit: _pageSize,
          startAfterTitle: startAfterId, // we store title cursor in this mode
        );
        _lastId = null; // not used in title paging
        _hasMore = page.lastTitle != null;
        _allItems
          ..clear()
          ..addAll(page.items.map(_map));
        _applyFilter(force: true);
        if (_currentPage >= 1) {
          _pageToCursor[_currentPage + 1] = page.lastTitle;
        }
      } else {
        final page = await _service.fetchRecipesPage(
          collection: 'recipes',
          limit: _pageSize,
          startAfterId: startAfterId,
        );
        _lastId = page.lastId;
        _hasMore = page.lastId != null;
        _allItems
          ..clear()
          ..addAll(page.items.map(_map));
        _applyFilter(force: true);
        if (_currentPage >= 1) {
          _pageToCursor[_currentPage + 1] = _lastId;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> goToPage(int pageNumber) async {
    if (pageNumber < 1) return;
    // Find nearest known page <= requested
    int anchorPage = pageNumber;
    while (anchorPage > 1 && !_pageToCursor.containsKey(anchorPage)) {
      anchorPage--;
    }
    // Step forward to compute cursor for requested page
    for (int p = anchorPage; p < pageNumber; p++) {
      final String? startAfterKey = _pageToCursor[p];
      if (_activeServerQuery.isNotEmpty) {
        final page = await _service.fetchRecipesPageByTitlePrefix(
          collection: 'recipes',
          prefix: _activeServerQuery,
          limit: _pageSize,
          startAfterTitle: startAfterKey,
        );
        _pageToCursor[p + 1] = page.lastTitle;
        if (page.lastTitle == null) break;
      } else {
        final page = await _service.fetchRecipesPage(
          collection: 'recipes',
          limit: _pageSize,
          startAfterId: startAfterKey,
        );
        _pageToCursor[p + 1] = page.lastId;
        if (page.lastId == null) break;
      }
    }
    _currentPage = pageNumber;
    await _loadPageAtCursor(startAfterId: _pageToCursor[pageNumber]);
  }

  Future<void> _loadTotalCount() async {
    try {
      _totalCount = _activeServerQuery.isNotEmpty
          ? await _service.fetchCollectionCountByTitlePrefix('recipes', _activeServerQuery)
          : await _service.fetchCollectionCount('recipes');
    } catch (_) {
      _totalCount = ((_pageToCursor.length - 1) * _pageSize) + _allItems.length;
    }
    notifyListeners();
  }

  Future<void> setSearchQuery(String q) async {
    _query = q;
    // Server-side search pagination when user types something meaningful
    final String trimmed = q.trim();
    _activeServerQuery = trimmed.isEmpty ? '' : trimmed;
    _currentPage = 1;
    _pageToCursor
      ..clear()
      ..addAll({1: null});
    await _loadTotalCount();
    await _loadPageAtCursor(startAfterId: _pageToCursor[_currentPage]);
  }

  void _applyFilter({bool force = false}) {
    final String q = _query.trim().toLowerCase();
    if (_activeServerQuery.isNotEmpty || force) {
      _items
        ..clear()
        ..addAll(_allItems);
    } else {
      _items
        ..clear()
        ..addAll(q.isEmpty ? _allItems : _allItems.where((e) => e.title.toLowerCase().contains(q)));
    }
    notifyListeners();
  }

  // Load sort options from Firestore
  Future<void> loadSortOptions() async {
    if (_optionsLoading) return;
    _optionsLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _loadCategory('meal_types'),
        _loadCategory('diets'),
        _loadCategory('cuisines'),
        _loadCategory('special_tags'),
      ]);

      _mealTypes = results[0];
      _diets = results[1];
      _cuisines = results[2];
      _tags = results[3];

      debugPrint('Loaded sort options:');
      debugPrint('  Meal Types: ${_mealTypes.length}');
      debugPrint('  Diets: ${_diets.length}');
      debugPrint('  Cuisines: ${_cuisines.length}');
      debugPrint('  Tags: ${_tags.length}');
    } catch (e) {
      debugPrint('Error loading sort options: $e');
    } finally {
      _optionsLoading = false;
      notifyListeners();
    }
  }

  Future<List<String>> _loadCategory(String name) async {
    // Strategy 1: Try common container collections with a single document named <name> that holds an array
    for (final container in const ['filters', 'categories', 'meta', 'app_meta', 'config', 'app']) {
      final arr = await _service.fetchDocumentArray(container, name);
      if (arr.isNotEmpty) return arr;
    }
    
    // Strategy 2: Try treating the name as a collection of docs
    return await _service.fetchCollectionStrings(name);
  }

  // Setter methods for sort options
  void setSelectedMealType(String? v) { _selectedMealType = v; notifyListeners(); }
  void setSelectedDiet(String? v) { _selectedDiet = v; notifyListeners(); }
  void setSelectedCuisine(String? v) { _selectedCuisine = v; notifyListeners(); }
  void setSelectedTag(String? v) { _selectedTag = v; notifyListeners(); }

  AdminRecipeCardData _map(Map<String, dynamic> m) {
    final String id = (m['id'] ?? '').toString();
    final String title = (m['title'] ?? 'Untitled').toString();
    final String image = (m['imageUrl'] ?? m['image'] ?? '').toString();
    final int minutes = _safeInt(m['minutes']) ?? _safeInt(m['time']) ?? 0;
    final double rating = _safeDouble(m['rating']) ?? 0.0;
    final int ingredientsCount = _pickFirstInt(
          m,
          keys: const ['ingredientsTotal', 'ingredients_total', 'ingredientsCount', 'ingredients_count'],
        ) ?? _listLength(m, keys: const ['ingredients', 'ingredientsList']);
    final int stepsCount = _pickFirstInt(
          m,
          keys: const ['instructionsTotal', 'instructions_total', 'stepsTotal', 'steps_total', 'stepsCount', 'steps_count'],
        ) ?? _listLength(m, keys: const ['instructions', 'steps']);
    return AdminRecipeCardData(
      id: id.isEmpty ? title : id,
      title: title,
      imageUrl: image,
      minutes: minutes,
      rating: rating,
      ingredientsCount: ingredientsCount,
      stepsCount: stepsCount,
    );
  }

  int? _safeInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  double? _safeDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
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
}




