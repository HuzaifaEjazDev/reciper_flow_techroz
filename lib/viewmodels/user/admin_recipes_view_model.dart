import 'package:flutter/foundation.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';

class AdminRecipeCardData {
  final String id;
  final String title;
  final String imageUrl;
  final int minutes;
  final double rating;
  const AdminRecipeCardData({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.minutes,
    required this.rating,
  });
}

class AdminRecipesViewModel extends ChangeNotifier {
  AdminRecipesViewModel({FirestoreRecipesService? service})
      : _service = service ?? FirestoreRecipesService();

  final FirestoreRecipesService _service;

  final List<AdminRecipeCardData> _allItems = <AdminRecipeCardData>[];
  final List<AdminRecipeCardData> _items = <AdminRecipeCardData>[];
  String _query = '';
  String? _lastId;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;

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
    await _loadPage();
  }

  Future<void> loadMore() async {
    if (_loading || !_hasMore) return;
    await _loadPage();
  }

  Future<void> _loadPage() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final page = await _service.fetchRecipesPage(collection: 'recipes', limit: 10, startAfterId: _lastId);
      _lastId = page.lastId;
      _hasMore = page.lastId != null;
      _allItems.addAll(page.items.map(_map));
      _applyFilter();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String q) {
    _query = q;
    _applyFilter();
  }

  void _applyFilter() {
    final String q = _query.trim().toLowerCase();
    _items
      ..clear()
      ..addAll(q.isEmpty
          ? _allItems
          : _allItems.where((e) => e.title.toLowerCase().contains(q)));
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
    return AdminRecipeCardData(
      id: id.isEmpty ? title : id,
      title: title,
      imageUrl: image,
      minutes: minutes,
      rating: rating,
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
}




