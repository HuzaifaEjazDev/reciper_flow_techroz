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
  final List<String>? ingredients;
  final List<String>? steps;
  final List<String>? labels; // Add labels field to store meal type information
  const AdminRecipeCardData({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.minutes,
    required this.rating,
    required this.ingredientsCount,
    required this.stepsCount,
    this.ingredients,
    this.steps,
    this.labels, // Add labels parameter
  });
}

class AdminRecipesViewModel extends ChangeNotifier {
  AdminRecipesViewModel({FirestoreRecipesService? service})
      : _service = service ?? FirestoreRecipesService();

  final FirestoreRecipesService _service;
  bool _disposed = false;
  String? _filterMealType;

  final List<AdminRecipeCardData> _allItems = <AdminRecipeCardData>[];
  final List<AdminRecipeCardData> _items = <AdminRecipeCardData>[];
  String _query = '';
  String _queryTemp = ''; // Temporary storage for search text
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
  
  // Filter state
  bool _filtersApplied = false;

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
  bool get filtersApplied => _filtersApplied;
  String get queryTemp => _queryTemp; // Getter for temporary query
  bool get disposed => _disposed;
  String? get filterMealType => _filterMealType;
  String get activeServerQuery => _activeServerQuery; // Add this getter

  // Set filter meal type
  void setFilterMealType(String? mealType, {bool autoApply = false}) {
    if (_disposed) return;
    _filterMealType = mealType;
    if (mealType != null) {
      _selectedMealType = mealType; // Also set the selected meal type for the sort bottom sheet
      // Mark filters as applied so the UI knows to show filtered state
      _filtersApplied = true;
    } else {
      // If mealType is null, clear the filters
      _selectedMealType = null;
      // Don't set _filtersApplied to false here, let the user explicitly clear filters
    }
    notifyListeners();
    
    // If autoApply is true, apply the filters immediately
    if (autoApply) {
      applyFilters();
    }
  }

  // Set temporary query without triggering search
  void setQueryTemp(String q) {
    if (_disposed) return;
    _queryTemp = q;
    notifyListeners();
  }

  // Apply filters
  void applyFilters() {
    if (_disposed) return;
    _filtersApplied = true;
    notifyListeners();
    loadInitial();
  }

  // Clear filters
  void clearFilters() {
    if (_disposed) return;
    _selectedMealType = null;
    _selectedDiet = null;
    _selectedCuisine = null;
    _selectedTag = null;
    _filterMealType = null; // Also clear the filter meal type
    _filtersApplied = false;
    notifyListeners();
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (_disposed) return;
    
    // Clear existing data
    _allItems.clear();
    _items.clear();
    _lastId = null;
    _hasMore = true;
    _pageToCursor
      ..clear()
      ..addAll({1: null});
    _currentPage = 1;
    
    // Load data if filters have been applied or if we have a filter meal type set
    if (_filtersApplied || _filterMealType != null || _selectedMealType != null || _selectedDiet != null || 
        _selectedCuisine != null || _selectedTag != null) {
      await _loadTotalCount();
      await _loadPageAtCursor(startAfterId: _pageToCursor[_currentPage]);
    } else {
      // When no filters are applied, load all recipes
      await _loadTotalCount();
      await _loadPageAtCursor(startAfterId: _pageToCursor[_currentPage]);
    }
  }

  // Backward compatibility (unused in new UI)
  Future<void> loadMore() async {
    if (_disposed || _loading || !_hasMore) return;
    await goToPage(_currentPage + 1);
  }

  Future<void> _loadPageAtCursor({required String? startAfterId}) async {
    if (_disposed || _loading) return;
    
    // Check if any filters are actually applied
    final bool hasFilters = _selectedMealType != null || _selectedDiet != null || 
                           _selectedCuisine != null || _selectedTag != null;
    
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
        if (_disposed) return;
        _lastId = null; // not used in title paging
        _hasMore = page.lastTitle != null;
        _allItems
          ..clear()
          ..addAll(page.items.map(_map));
        _applyFilter(force: true);
        if (_currentPage >= 1) {
          _pageToCursor[_currentPage + 1] = page.lastTitle;
        }
      } else if (hasFilters) {
        // Use filtered fetching when filters are applied
        final page = await _service.fetchRecipesPageWithFilters(
          collection: 'recipes',
          limit: _pageSize,
          startAfterId: startAfterId,
          mealType: _selectedMealType,
          diet: _selectedDiet,
          cuisine: _selectedCuisine,
          tag: _selectedTag,
        );
        if (_disposed) return;
        _lastId = page.lastId;
        _hasMore = page.lastId != null;
        _allItems
          ..clear()
          ..addAll(page.items.map(_map));
        _items
          ..clear()
          ..addAll(_allItems);
        if (_currentPage >= 1) {
          _pageToCursor[_currentPage + 1] = _lastId;
        }
      } else {
        // Load all recipes when no filters are applied
        final page = await _service.fetchRecipesPage(
          collection: 'recipes',
          limit: _pageSize,
          startAfterId: startAfterId,
        );
        if (_disposed) return;
        _lastId = page.lastId;
        _hasMore = page.lastId != null;
        _allItems
          ..clear()
          ..addAll(page.items.map(_map));
        _items
          ..clear()
          ..addAll(_allItems);
        if (_currentPage >= 1) {
          _pageToCursor[_currentPage + 1] = _lastId;
        }
      }
    } catch (e) {
      if (_disposed) return;
      _error = e.toString();
    } finally {
      if (_disposed) return;
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> goToPage(int pageNumber) async {
    if (_disposed) return;
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
        if (_disposed) return;
        _pageToCursor[p + 1] = page.lastTitle;
        if (page.lastTitle == null) break;
      } else {
        final page = await _service.fetchRecipesPage(
          collection: 'recipes',
          limit: _pageSize,
          startAfterId: startAfterKey,
        );
        if (_disposed) return;
        _pageToCursor[p + 1] = page.lastId;
        if (page.lastId == null) break;
      }
    }
    _currentPage = pageNumber;
    await _loadPageAtCursor(startAfterId: _pageToCursor[pageNumber]);
  }

  Future<void> _loadTotalCount() async {
    if (_disposed) return;
    try {
      if (_activeServerQuery.isNotEmpty) {
        _totalCount = await _service.fetchCollectionCountByTitlePrefix('recipes', _activeServerQuery);
      } else if (_filtersApplied) {
        // Use filtered count when filters are applied
        _totalCount = await _service.fetchCollectionCountWithFilters(
          collection: 'recipes',
          mealType: _selectedMealType,
          diet: _selectedDiet,
          cuisine: _selectedCuisine,
          tag: _selectedTag,
        );
      } else {
        _totalCount = await _service.fetchCollectionCount('recipes');
      }
    } catch (_) {
      if (_disposed) return;
      _totalCount = ((_pageToCursor.length - 1) * _pageSize) + _allItems.length;
    }
    if (_disposed) return;
    notifyListeners();
  }

  // Modified setSearchQuery to accept optional parameter
  Future<void> setSearchQuery([String? q]) async {
    if (_disposed) return;
    _query = q ?? _queryTemp; // Use provided query or temp query
    // Server-side search pagination when user types something meaningful
    final String trimmed = _query.trim();
    _activeServerQuery = trimmed.isEmpty ? '' : trimmed;
    _currentPage = 1;
    _pageToCursor
      ..clear()
      ..addAll({1: null});
    await _loadTotalCount();
    await _loadPageAtCursor(startAfterId: _pageToCursor[_currentPage]);
  }

  void _applyFilter({bool force = false}) {
    if (_disposed) return;
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
    if (_disposed || _optionsLoading) return;
    _optionsLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _loadCategory('meal_types'),
        _loadCategory('diets'),
        _loadCategory('cuisines'),
        _loadCategory('special_tags'),
      ]);
      
      if (_disposed) return;

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
      if (_disposed) return;
      debugPrint('Error loading sort options: $e');
    } finally {
      if (_disposed) return;
      _optionsLoading = false;
      notifyListeners();
    }
  }

  Future<List<String>> _loadCategory(String name) async {
    if (_disposed) return const [];
    // Strategy 1: Try common container collections with a single document named <name> that holds an array
    for (final container in const ['filters', 'categories', 'meta', 'app_meta', 'config', 'app']) {
      final arr = await _service.fetchDocumentArray(container, name);
      if (_disposed) return const [];
      if (arr.isNotEmpty) return arr;
    }
    
    // Strategy 2: Try treating the name as a collection of docs
    return await _service.fetchCollectionStrings(name);
  }

  // Setter methods for sort options
  void setSelectedMealType(String? v) { 
    if (_disposed) return;
    _selectedMealType = v; 
    notifyListeners(); 
  }
  
  void setSelectedDiet(String? v) { 
    if (_disposed) return;
    _selectedDiet = v; 
    notifyListeners(); 
  }
  
  void setSelectedCuisine(String? v) { 
    if (_disposed) return;
    _selectedCuisine = v; 
    notifyListeners(); 
  }
  
  void setSelectedTag(String? v) { 
    if (_disposed) return;
    _selectedTag = v; 
    notifyListeners(); 
  }

  AdminRecipeCardData _map(Map<String, dynamic> m) {
    final String id = (m['id'] ?? '').toString();
    final String title = (m['title'] ?? 'Untitled').toString();
    final String image = (m['imageUrl'] ?? m['image'] ?? '').toString();
    final int minutes =
        _safeInt(m['totalMinutes']) ?? 0;
    final double rating = _safeDouble(m['rating']) ?? 0.0;
    final int ingredientsCount = _pickFirstInt(
          m,
          keys: const ['ingredientsTotal', 'ingredients_total', 'ingredientsCount', 'ingredients_count'],
        ) ?? _listLength(m, keys: const ['ingredients', 'ingredientsList']);
    final int stepsCount = _pickFirstInt(
          m,
          keys: const ['instructionsTotal', 'instructions_total', 'stepsTotal', 'steps_total', 'stepsCount', 'steps_count'],
        ) ?? _listLength(m, keys: const ['instructions', 'steps']);

    final List<String>? ingredients = _extractStringList(m, keys: const ['ingredients', 'ingredientsList']);
    final List<String>? steps = _extractStringList(m, keys: const ['instructions', 'steps']);
    final List<String>? labels = _extractStringList(m, keys: const ['labels', 'mealTypes', 'categories']); // Extract labels
    
    debugPrint('Mapping recipe data - ID: $id, Title: $title, Labels: $labels');
    
    return AdminRecipeCardData(
      id: id.isEmpty ? title : id,
      title: title,
      imageUrl: image,
      minutes: minutes,
      rating: rating,
      ingredientsCount: ingredientsCount,
      stepsCount: stepsCount,
      ingredients: ingredients,
      steps: steps,
      labels: labels, // Add labels to the AdminRecipeCardData
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

  List<String>? _extractStringList(Map<String, dynamic> m, {required List<String> keys}) {
    for (final k in keys) {
      final v = m[k];
      if (v is List) {
        // handle list of strings
        if (v.isNotEmpty && v.first is String) {
          return v.cast<String>();
        }
        // handle list of maps {text: ..., name/quantity: ...}
        if (v.isNotEmpty && v.first is Map) {
          final List<String> out = <String>[];
          for (final e in v) {
            if (e is Map) {
              final text = e['text'] ?? e['name'] ?? e['title'];
              final qty = e['quantity'];
              if (text != null) {
                out.add(qty != null ? '$qty $text' : text.toString());
              }
            }
          }
          return out.isEmpty ? null : out;
        }
      }
    }
    return null;
  }
  
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}