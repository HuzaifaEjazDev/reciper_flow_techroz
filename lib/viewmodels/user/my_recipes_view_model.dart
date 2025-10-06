import 'package:flutter/material.dart';
import 'package:recipe_app/models/user_recipe.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyRecipeCardData {
  final String title;
  final String imageAssetPath;
  final int ingredientsCount;
  final int stepsCount;
  final UserRecipe? recipe;
  final String id; // Add ID field
  
  MyRecipeCardData({
    required this.title,
    required this.imageAssetPath,
    required this.ingredientsCount,
    required this.stepsCount,
    this.recipe,
    required this.id, // Add ID parameter
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
  bool _optionsLoading = false;


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
  bool get optionsLoading => _optionsLoading;

  // Load user-created recipes from Firestore
  Future<void> loadFromFirestore({String collection = 'RecipesCreatedByUser'}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    _lastId = null;
    _hasMore = true;
    notifyListeners();
    try {
      final recipes = await _fetchUserCreatedRecipes();
      _allItems
        ..clear()
        ..addAll(recipes);
      _applyFilter();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Fetch user-created recipes from the RecipesCreatedByUser sub-collection
  Future<List<MyRecipeCardData>> _fetchUserCreatedRecipes() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final CollectionReference<Map<String, dynamic>> userRecipesRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid).collection('RecipesCreatedByUser');
      
      final QuerySnapshot<Map<String, dynamic>> snapshot = await userRecipesRef.get();
      
      final List<MyRecipeCardData> recipes = snapshot.docs.map((doc) {
        final data = doc.data();
        final String title = (data['title'] ?? 'Untitled Recipe').toString();
        final String imageUrl = (data['imageUrl'] ?? 'assets/images/vegitables.jpg').toString();
        final List<dynamic> ingredients = data['ingredients'] is List ? data['ingredients'] : [];
        final List<String> steps = data['steps'] is List ? List<String>.from(data['steps']) : [];
        
        return MyRecipeCardData(
          id: doc.id,
          title: title,
          imageAssetPath: imageUrl,
          ingredientsCount: ingredients.length,
          stepsCount: steps.length,
          recipe: null,
        );
      }).toList();
      
      return recipes;
    } catch (e) {
      throw Exception('Error fetching user-created recipes: $e');
    }
  }

  Future<void> loadMore({String collection = 'RecipesCreatedByUser'}) async {
    // For user-created recipes, we load all at once, so no need for pagination
    // This method is kept for compatibility
    await loadFromFirestore(collection: collection);
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
      id: m['id']?.toString() ?? '', // Add ID
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

}