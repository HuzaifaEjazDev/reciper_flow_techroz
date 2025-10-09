import 'package:flutter/material.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';

class GroceriesViewModel extends ChangeNotifier {
  final FirestoreRecipesService _service = FirestoreRecipesService();
  final TextEditingController searchController = TextEditingController(); // Add controller
  String _searchQuery = '';
  String _searchQueryTemp = '';
  String _sortBy = 'newest'; // Add sort by field
  
  // Cache for recipes data
  List<Map<String, dynamic>>? _cachedRecipes;
  
  // Local checkbox states
  final Map<String, List<bool?>> _checkboxStates = {};
  
  // Expansion states for recipes
  final Map<String, bool> _expansionStates = {};
  
  List<Map<String, dynamic>>? get cachedRecipes => _cachedRecipes;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy; // Add getter for sort by
  
  // Expose the service for access to its methods
  FirestoreRecipesService get service => _service;
  
  GroceriesViewModel() {
    // Add listener to handle search when text changes
    searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    searchController.dispose(); // Dispose controller
    super.dispose();
  }
  
  void _onSearchChanged() {
    // When search bar is empty, show all data automatically
    if (searchController.text.trim().isEmpty) {
      setSearchQuery('');
    }
  }
  
  // Search methods
  void setSearchQuery([String? query]) {
    _searchQuery = (query ?? _searchQueryTemp).toLowerCase();
    _cachedRecipes = null; // Clear cache when search query changes
    notifyListeners();
  }
  
  void setSearchQueryTemp(String query) {
    _searchQueryTemp = query.toLowerCase();
  }
  
  // Sort methods
  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _cachedRecipes = null; // Clear cache when sort changes
    notifyListeners();
  }
  
  // Toggle expansion state for a recipe
  void toggleExpansionState(String recipeId, bool isExpanded) {
    _expansionStates[recipeId] = isExpanded;
    // Don't notify listeners to avoid rebuilding the entire widget tree
  }
  
  // Get expansion state for a recipe
  bool getExpansionState(String recipeId) {
    return _expansionStates[recipeId] ?? false;
  }
  
  // Fetch all grocery recipes (without date filtering)
  Future<List<Map<String, dynamic>>> fetchAllGroceryRecipes() async {
    // Return cached recipes if available and no search query
    if (_cachedRecipes != null && _searchQuery.isEmpty) {
      return _cachedRecipes!;
    }
    
    final List<Map<String, dynamic>> recipes = await _service.fetchAllGroceryRecipes(sortBy: _sortBy);
    
    // Apply search filter if there's a query
    List<Map<String, dynamic>> filteredRecipes = recipes;
    if (_searchQuery.isNotEmpty) {
      final String queryLower = _searchQuery.toLowerCase();
      filteredRecipes = recipes.where((recipe) {
        final String title = (recipe['title'] as String? ?? '').toLowerCase();
        return title.contains(queryLower);
      }).toList();
    }
    
    _cachedRecipes = filteredRecipes;
    
    // Initialize checkbox states
    for (final recipe in filteredRecipes) {
      final String recipeId = recipe['id'].toString();
      final List<dynamic> ingredients = recipe['ingredients'] as List<dynamic>? ?? <dynamic>[];
      
      if (!_checkboxStates.containsKey(recipeId)) {
        _checkboxStates[recipeId] = List<bool?>.filled(ingredients.length, false);
        for (int i = 0; i < ingredients.length; i++) {
          final dynamic item = ingredients[i];
          if (item is Map && item['isChecked'] == true) {
            _checkboxStates[recipeId]![i] = true;
          }
        }
      }
    }
    
    return filteredRecipes;
  }
  
  // Helper method to update checkbox state locally without notifying listeners
  // This prevents UI rebuilds when we only want to update a single checkbox
  void updateCheckboxStateSilently(String recipeId, int index, bool? value) {
    if (_checkboxStates.containsKey(recipeId) && 
        index < _checkboxStates[recipeId]!.length) {
      _checkboxStates[recipeId]![index] = value;
      // Note: Not calling notifyListeners() here to prevent UI rebuild
    }
  }
  
  // Helper method to update checkbox state and notify listeners (for cases where we want full UI update)
  void updateCheckboxStateWithNotification(String recipeId, int index, bool? value) {
    if (_checkboxStates.containsKey(recipeId) && 
        index < _checkboxStates[recipeId]!.length) {
      _checkboxStates[recipeId]![index] = value;
      notifyListeners();
    }
  }
  
  // Original method kept for backward compatibility
  void updateCheckboxState(String recipeId, int index, bool? value) {
    updateCheckboxStateWithNotification(recipeId, index, value);
  }

  // Get checkbox state
  bool? getCheckboxState(String recipeId, int index) {
    if (_checkboxStates.containsKey(recipeId) && 
        index < _checkboxStates[recipeId]!.length) {
      return _checkboxStates[recipeId]![index];
    }
    return false;
  }
  
  // Toggle ingredient checked state
  Future<void> toggleGroceryIngredientChecked({
    required String groceryId,
    required int ingredientIndex,
    required bool isChecked,
  }) async {
    await _service.toggleGroceryIngredientChecked(
      groceryId: groceryId,
      ingredientIndex: ingredientIndex,
      isChecked: isChecked,
    );
  }

  // Clear all checked ingredients (remove from database)
  Future<void> clearAllCheckedIngredients() async {
    try {
      // Fetch current recipes to get the latest data
      final List<Map<String, dynamic>> recipes = await _service.fetchAllGroceryRecipes();
      
      // Track which recipes should be deleted (all ingredients checked)
      final List<String> recipesToDelete = [];
      
      // Process each recipe
      for (final recipe in recipes) {
        final String recipeId = recipe['id'].toString();
        final List<dynamic> ingredients = recipe['ingredients'] as List<dynamic>? ?? <dynamic>[];
        
        // Check if all ingredients are checked
        bool allIngredientsChecked = true;
        for (int i = 0; i < ingredients.length; i++) {
          final dynamic item = ingredients[i];
          if (item is Map && item['isChecked'] != true) {
            allIngredientsChecked = false;
            break;
          }
        }
        
        if (allIngredientsChecked && ingredients.isNotEmpty) {
          // Mark recipe for deletion if all ingredients are checked
          recipesToDelete.add(recipeId);
        } else {
          // Create a new list without checked ingredients
          final List<Map<String, dynamic>> updatedIngredients = [];
          for (int i = 0; i < ingredients.length; i++) {
            final dynamic item = ingredients[i];
            // Keep ingredients that are not checked
            if (item is Map && item['isChecked'] != true) {
              updatedIngredients.add(Map<String, dynamic>.from(item));
            }
          }
          
          // Update the recipe with the filtered ingredients list
          await _service.updateGroceryRecipeIngredients(recipeId, updatedIngredients);
        }
      }
      
      // Delete recipes that had all ingredients checked
      for (final recipeId in recipesToDelete) {
        await _service.deleteGroceryRecipe(recipeId);
      }
      
      // Clear cache and checkbox states
      _cachedRecipes = null;
      _checkboxStates.clear();
      _expansionStates.clear();
      
      // Notify listeners to refresh the entire UI after clear operation
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Method to refresh recipes when a new one is added or removed
  Future<void> refreshRecipes() async {
    _cachedRecipes = null; // Clear cache to force fetch new data
    _checkboxStates.clear(); // Clear checkbox states
    _expansionStates.clear(); // Clear expansion states
    notifyListeners(); // Notify listeners to rebuild UI
  }

  // Dispose method to clean up
  void disposeViewModel() {
    _checkboxStates.clear();
    _cachedRecipes = null;
    _expansionStates.clear();
  }
}