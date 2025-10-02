import 'package:flutter/foundation.dart';
import 'package:recipe_app/models/user/meal_plan.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class MealPlannerViewModel extends ChangeNotifier {
  final List<DayPlan> _plans = <DayPlan>[];
  int _selectedIndex = 0;
  final FirestoreRecipesService _service;
  List<String> _mealTypes = const [];
  bool _loading = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _mealTypesListener;
  bool _initialized = false; // Add this flag

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
      _plans.add(
        DayPlan(
          date: d,
          meals: [], // Remove the static breakfast recipe
        ),
      );
    }
    
    _initialized = true; // Set the flag
    debugPrint('Generated ${_plans.length} plans');
    notifyListeners();
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
    }, onError: (error) {
      debugPrint('Error listening to meal types: $error');
    });
  }

  void selectIndex(int index) {
    if (index < 0 || index >= _plans.length) return;
    _selectedIndex = index;
    notifyListeners();
  }
  
  // Method to add a meal entry to a specific day
  void addMealToDay(int dayIndex, MealEntry meal) {
    if (dayIndex < 0 || dayIndex >= _plans.length) return;
    
    final DayPlan currentDay = _plans[dayIndex];
    final DayPlan updatedDay = currentDay.copyWithMeal(meal);
    
    _plans[dayIndex] = updatedDay;
    notifyListeners();
  }

  @override
  void dispose() {
    // Cancel the listener when the ViewModel is disposed
    _mealTypesListener?.cancel();
    super.dispose();
  }
}