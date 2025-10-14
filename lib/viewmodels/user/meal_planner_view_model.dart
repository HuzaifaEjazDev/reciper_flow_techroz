import 'package:flutter/foundation.dart';
import 'package:recipe_app/models/meal_plan.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class MealPlannerViewModel extends ChangeNotifier {
  final List<DayPlan> _plans = <DayPlan>[];
  int _selectedIndex = 0;
  final FirestoreRecipesService _service;
  List<String> _mealTypes = const [];
  bool _loading = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _mealTypesListener;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _mealsListener; // Add this line
  bool _initialized = false;

  MealPlannerViewModel({FirestoreRecipesService? service})
      : _service = service ?? FirestoreRecipesService();

  List<DayPlan> get plans => List.unmodifiable(_plans);
  int get selectedIndex => _selectedIndex;
  DayPlan? get selectedDay => _plans.isEmpty ? null : _plans[_selectedIndex];
  List<String> get mealTypes => _mealTypes;
  bool get loading => _loading;

  Future<void> init() async {
    // Check if already initialized to prevent duplication
    if (_initialized) {
      debugPrint('MealPlannerViewModel already initialized, skipping initialization.');
      return;
    }
    
    debugPrint('Initializing MealPlannerViewModel');
    
    // Clear any existing plans to ensure we start fresh
    _plans.clear();
    
    // Fetch meal types from Firestore
    await _fetchMealTypes();
    
    // Set up listener for real-time updates
    _setupMealTypesListener();
    
    final DateTime today = DateTime.now();
    debugPrint('Generating plans for dates from $today');
    
    for (int i = 0; i < 7; i++) {
      final d = DateTime(today.year, today.month, today.day).add(Duration(days: i));
      _plans.add(DayPlan(date: d, meals: []));
    }

    // Hydrate meals from Firestore for the generated days
    await _loadMealsForWeek();
    
    // Set up real-time listener for meal changes
    _setupMealsListener();
    
    _initialized = true; // Set the flag
    debugPrint('Generated ${_plans.length} plans');
    notifyListeners();
  }

  // Add this method to refresh the meal planner data
  Future<void> refreshMeals() async {
    debugPrint('Refreshing meal planner data');
    await _loadMealsForWeek();
    notifyListeners();
  }

  Future<void> _loadMealsForWeek() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Generate date keys for the week
      final List<String> dateKeys = [];
      for (int i = 0; i < _plans.length; i++) {
        final String dateForRecipe = _service.formatDateKey(_plans[i].date);
        dateKeys.add(dateForRecipe);
      }

      // Get all planned meals for the week
      final Map<String, List<PlannedMeal>> weekMeals = await _service.getPlannedMealsForWeek(dateKeys);

      // Convert PlannedMeal objects to MealEntry objects for each day
      for (int dayIndex = 0; dayIndex < _plans.length; dayIndex++) {
        final String dateForRecipe = dateKeys[dayIndex];
        final List<PlannedMeal> plannedMeals = weekMeals[dateForRecipe] ?? [];
        
        final List<MealEntry> mealEntries = plannedMeals.map((plannedMeal) {
          // Convert List<Ingredient> to List<String>
          List<String>? ingredients = null;
          if (plannedMeal.ingredients != null) {
            ingredients = plannedMeal.ingredients.map((ingredient) => ingredient.toString()).toList();
          }
          
          return MealEntry(
            id: plannedMeal.uniqueId,
            type: plannedMeal.mealType,
            title: plannedMeal.recipeTitle,
            minutes: plannedMeal.minutes, // Use minutes from PlannedMeal
            imageAssetPath: plannedMeal.recipeImage,
            time: plannedMeal.timeForRecipe,
            people: plannedMeal.persons,
            plannedId: plannedMeal.uniqueId,
            ingredients: ingredients,
            instructions: plannedMeal.instructions,
          );
        }).toList();

        _plans[dayIndex] = DayPlan(date: _plans[dayIndex].date, meals: mealEntries);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading planned meals for week: $e');
    }
  }

  Future<void> _fetchMealTypes() async {
    _loading = true;
    notifyListeners();
    try {
      // Fetch meal types from the 'meal_types' collection
      _mealTypes = await _service.fetchCollectionStrings('meal_types');
      // Don't provide default meal types if none are found in the database
    } catch (e) {
      // Don't provide default meal types if there's an error
      _mealTypes = const []; // Empty list instead of default values
      debugPrint('Error fetching meal types: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _setupMealTypesListener() {
    // Set up a real-time listener for meal types
    _mealTypesListener = FirebaseFirestore.instance
        .collection('meal_types')
        .snapshots()
        .listen((snapshot) {
      // Update meal types when the collection changes
      _mealTypes = snapshot.docs.map((doc) {
        final data = doc.data();
        final Object? name = data['name'] ?? data['label'] ?? data['title'];
        return (name == null || name.toString().isEmpty) ? doc.id : name.toString();
      }).toList();
      
      // Don't provide default meal types if none are found
      // Keep the list empty if no meal types are found
      
      notifyListeners();
      // Reload meals when meal types change to reflect new categories
      _loadMealsForWeek();
    }, onError: (error) {
      debugPrint('Error listening to meal types: $error');
    });
  }

  // Add this method to set up real-time listener for meal changes
  void _setupMealsListener() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Cancel any existing listener
    _mealsListener?.cancel();
    
    // Set up a real-time listener for planned meals using the user's sub-collection
    _mealsListener = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('PlannedMeals')
        .snapshots()
        .listen((snapshot) async {
      // When meals change, reload the week's meals
      await _loadMealsForWeek();
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error listening to planned meals: $error');
    });
  }

  void selectIndex(int index) {
    if (index < 0 || index >= _plans.length) return;
    _selectedIndex = index;
    notifyListeners();
  }
  
  /// Parse an ingredient string into an Ingredient object
  Ingredient _parseIngredientString(String ingredientString) {
    final String trimmed = ingredientString.trim();
    if (trimmed.isEmpty) {
      return const Ingredient(name: '');
    }
    
    // Split the string into parts
    final List<String> parts = trimmed.split(' ');
    if (parts.length < 2) {
      return Ingredient(name: trimmed);
    }
    
    // Check if first part is an emoji
    final String firstPart = parts[0];
    final bool hasEmoji = firstPart.runes.length == 1 && firstPart.codeUnitAt(0) > 0x1F600;
    final int startIndex = hasEmoji ? 1 : 0;
    
    // If we have enough parts, try to parse quantity and unit
    if (parts.length > startIndex + 1) {
      final String quantity = parts[startIndex];
      final String unit = parts.length > startIndex + 2 ? parts[startIndex + 1] : '';
      final String name = parts.length > startIndex + 2 
          ? parts.sublist(startIndex + 2).join(' ') 
          : parts.sublist(startIndex + 1).join(' ');
      
      return Ingredient(
        name: name,
        quantity: quantity,
        unit: unit.isNotEmpty ? unit : null,
        emoji: hasEmoji ? firstPart : null,
      );
    } else {
      // Just name and possibly emoji
      final String name = hasEmoji ? parts.sublist(1).join(' ') : trimmed;
      return Ingredient(
        name: name,
        emoji: hasEmoji ? firstPart : null,
      );
    }
  }

  // Method to add a meal entry to a specific day and save to Firestore
  Future<void> addMealToDay(int dayIndex, MealEntry meal, {String? time, int? persons}) async {
    if (dayIndex < 0 || dayIndex >= _plans.length) return;
    
    final DayPlan currentDay = _plans[dayIndex];
    final String dateForRecipe = _service.formatDateKey(currentDay.date);
    
    // Debug logging
    debugPrint('Adding meal to day: ${meal.title}');
    debugPrint('Meal ingredients: ${meal.ingredients}');
    debugPrint('Meal instructions: ${meal.instructions}');
    
    try {
      // Convert List<String>? to List<Ingredient> by parsing each ingredient
      List<Ingredient> ingredients = [];
      if (meal.ingredients != null) {
        ingredients = meal.ingredients!.map((ingredientStr) => _parseIngredientString(ingredientStr)).toList();
      }
      
      // Create a PlannedMeal object
      final PlannedMeal plannedMeal = PlannedMeal(
        uniqueId: '', // Will be set by Firestore5
        recipeTitle: meal.title,
        dateForRecipe: dateForRecipe,
        timeForRecipe: time ?? meal.time ?? '12:00',
        persons: persons ?? meal.people ?? 1,
        ingredients: ingredients,
        instructions: meal.instructions ?? [],
        recipeImage: meal.imageAssetPath,
        mealType: meal.type,
        createdAt: DateTime.now(),
        minutes: meal.minutes ?? 0, // Add minutes
      );
      
      debugPrint('Created PlannedMeal with ingredients: ${plannedMeal.ingredients}');
      debugPrint('Created PlannedMeal with instructions: ${plannedMeal.instructions}');

      // Save to Firestore using the new schema
      final String mealId = await _service.savePlannedMeal(plannedMeal);
      
      // Create updated MealEntry with the new ID
      final MealEntry updatedMeal = MealEntry(
        id: mealId,
        type: meal.type,
        title: meal.title,
        minutes: meal.minutes,
        imageAssetPath: meal.imageAssetPath,
        time: time ?? meal.time,
        people: persons ?? meal.people,
        plannedId: mealId,
        ingredients: meal.ingredients,
        instructions: meal.instructions,
      );

      // Update local state
      final DayPlan updatedDay = currentDay.addMeal(updatedMeal);
      _plans[dayIndex] = updatedDay;
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding meal to day: $e');
    }
  }
  
  // Remove a meal entry from a specific day and delete from Firestore
  Future<void> removeMealFromDay(int dayIndex, MealEntry meal) async {
    if (dayIndex < 0 || dayIndex >= _plans.length) return;

    final DayPlan currentDay = _plans[dayIndex];
    
    try {
      // Delete from Firestore using the new schema
      if (meal.plannedId != null) {
        await _service.deletePlannedMeal(meal.plannedId!);
      }

      // Update local state
      final List<MealEntry> updatedMeals = List<MealEntry>.from(currentDay.meals)
        ..removeWhere((m) => m.plannedId == meal.plannedId);

      _plans[dayIndex] = DayPlan(date: currentDay.date, meals: updatedMeals);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing meal from day: $e');
    }
  }


  @override
  void dispose() {
    // Cancel the listeners when the ViewModel is disposed
    _mealTypesListener?.cancel();
    _mealsListener?.cancel(); // Cancel the meals listener
    super.dispose();
  }
}