import 'package:flutter/foundation.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';

class GroceriesViewModel extends ChangeNotifier {
  final FirestoreRecipesService _service = FirestoreRecipesService();
  bool _showAll = false;
  String _selectedDateKey = '';
  
  // Cache for recipes data
  List<Map<String, dynamic>>? _cachedRecipes;
  
  // Local checkbox states
  final Map<String, List<bool?>> _checkboxStates = {};
  
  // Expansion states for recipes
  final Map<String, bool> _expansionStates = {};
  
  bool get showAll => _showAll;
  String get selectedDateKey => _selectedDateKey;
  List<Map<String, dynamic>>? get cachedRecipes => _cachedRecipes;
  
  // Expose the service for access to its methods
  FirestoreRecipesService get service => _service;
  
  GroceriesViewModel() {
    // Default to today's date key
    _selectedDateKey = _service.formatDateKey(DateTime.now());
  }
  
  void toggleShowAll(bool value) {
    _showAll = value;
    _cachedRecipes = null; // Clear cache when switching views
    _checkboxStates.clear(); // Clear checkbox states
    _expansionStates.clear(); // Clear expansion states
    notifyListeners();
  }
  
  void setSelectedDateKey(String dateKey) {
    _selectedDateKey = dateKey;
    _cachedRecipes = null; // Clear cache when date changes
    _checkboxStates.clear(); // Clear checkbox states
    _expansionStates.clear(); // Clear expansion states
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
  
  // Fetch recipes with caching
  Future<List<Map<String, dynamic>>> fetchRecipes() async {
    if (_cachedRecipes != null) {
      return _cachedRecipes!;
    }
    
    final List<Map<String, dynamic>> recipes = _showAll 
      ? await _service.fetchAllGroceryRecipes()
      : await _service.fetchGroceryRecipesByDate(_selectedDateKey);
      
    _cachedRecipes = recipes;
    
    // Initialize checkbox states
    for (final recipe in recipes) {
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
    
    return recipes;
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
      final List<Map<String, dynamic>> recipes = _showAll 
        ? await _service.fetchAllGroceryRecipes()
        : await _service.fetchGroceryRecipesByDate(_selectedDateKey);
      
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
  
  // Dispose method to clean up
  void disposeViewModel() {
    _checkboxStates.clear();
    _cachedRecipes = null;
    _expansionStates.clear();
  }
}