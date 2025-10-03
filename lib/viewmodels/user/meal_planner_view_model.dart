import 'package:flutter/foundation.dart';
import 'package:recipe_app/models/user/meal_plan.dart';
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
      _plans.add(DayPlan(date: d, meals: []));
    }

    // Hydrate meals from Firestore for the generated days
    await _loadMealsForWeek();
    
    _initialized = true; // Set the flag
    debugPrint('Generated ${_plans.length} plans');
    notifyListeners();
  }

  Future<void> _loadMealsForWeek() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Load meals for each day in the week
      for (int dayIndex = 0; dayIndex < _plans.length; dayIndex++) {
        final DayPlan day = _plans[dayIndex];
        
        // Format date as "D MMM" (e.g., "4 Aug", "6 Aug") to match our Firestore structure
        final String dateKey = '${day.date.day} ${_getMonthName(day.date.month)}';
        
        // Get the document for this date
        final DocumentSnapshot<Map<String, dynamic>> dateDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('PlannedMeals')
            .doc(dateKey)
            .get();

        if (!dateDoc.exists) {
          // No meals planned for this date
          continue;
        }

        // For each meal type, get the meals
        final List<MealEntry> loadedMeals = <MealEntry>[];
        
        // Get all subcollections (meal types) for this date
        final DocumentReference dateDocRef = dateDoc.reference;
        
        // We need to query each meal type collection separately
        for (final String mealType in _mealTypes) {
          try {
            final QuerySnapshot<Map<String, dynamic>> mealTypeSnapshot = await dateDocRef
                .collection(mealType)
                .get();
                
            for (final QueryDocumentSnapshot<Map<String, dynamic>> mealDoc in mealTypeSnapshot.docs) {
              final Map<String, dynamic> data = mealDoc.data();
              
              loadedMeals.add(
                MealEntry(
                  id: data['idOfRecipe']?.toString() ?? mealDoc.id,
                  type: mealType,
                  title: data['recipeTitle']?.toString() ?? 'Recipe',
                  minutes: data['recipeMinutes'] as int? ?? 0,
                  imageAssetPath: data['recipeImage']?.toString() ?? '',
                  time: data['time']?.toString(),
                  people: data['Persons'] as int?,
                  plannedId: mealDoc.id,
                  ingredients: data['recipeIngredients'] is List ? List<String>.from(data['recipeIngredients']) : null,
                  instructions: data['recipeInstructions'] is List ? List<String>.from(data['recipeInstructions']) : null,
                ),
              );
            }
          } catch (e) {
            debugPrint('Error loading meals for type $mealType: $e');
          }
        }

        _plans[dayIndex] = DayPlan(date: day.date, meals: loadedMeals);
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

  void selectIndex(int index) {
    if (index < 0 || index >= _plans.length) return;
    _selectedIndex = index;
    notifyListeners();
  }
  
  // Method to add a meal entry to a specific day and save to Firestore
  void addMealToDay(int dayIndex, MealEntry meal) {
    if (dayIndex < 0 || dayIndex >= _plans.length) return;
    
    final DayPlan currentDay = _plans[dayIndex];
    final DayPlan updatedDay = currentDay.addMeal(meal);
    
    _plans[dayIndex] = updatedDay;
    notifyListeners();
    
    // Save the updated day plan to Firestore under PlannedMeals collection
    _saveMealToFirestore(meal, updatedDay.date, dayIndex);
  }
  
  // Remove a meal entry from a specific day and delete from Firestore
  Future<void> removeMealFromDay(int dayIndex, MealEntry meal) async {
    if (dayIndex < 0 || dayIndex >= _plans.length) return;

    final DayPlan currentDay = _plans[dayIndex];
    final List<MealEntry> updatedMeals = List<MealEntry>.from(currentDay.meals)
      ..removeWhere((m) => m.type == meal.type && m.id == meal.id);

    _plans[dayIndex] = DayPlan(date: currentDay.date, meals: updatedMeals);
    notifyListeners();

    await _deleteMealFromFirestore(meal, currentDay.date);
  }

  // Delete the meal document(s) from Firestore by recipe id under the date/type path
  Future<void> _deleteMealFromFirestore(MealEntry meal, DateTime date) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Format date as "D MMM" (e.g., "4 Aug", "6 Aug") to match our Firestore structure
      final String dateKey = '${date.day} ${_getMonthName(date.month)}';
      
      final CollectionReference<Map<String, dynamic>> plannedMealsRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid).collection('PlannedMeals');

      // Delete all documents in the meal type collection for this date
      final QuerySnapshot<Map<String, dynamic>> snap = await plannedMealsRef
          .doc(dateKey)
          .collection(meal.type)
          .where('idOfRecipe', isEqualTo: meal.id)
          .get();

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting meal from Firestore: $e');
    }
  }

  // Method to save a meal to Firestore under PlannedMeals collection
  Future<void> _saveMealToFirestore(MealEntry meal, DateTime date, int dayIndex) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // Format date as "D MMM" (e.g., "4 Aug", "6 Aug") to match our Firestore structure
      final String dateKey = '${date.day} ${_getMonthName(date.month)}';
      
      // Create a reference to the user's PlannedMeals subcollection
      final CollectionReference<Map<String, dynamic>> plannedMealsRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid).collection('PlannedMeals');
      
      // Fetch full recipe details to save with the meal
      final FirestoreRecipesService service = FirestoreRecipesService();
      final Map<String, dynamic>? recipeData = await service.fetchRecipeById(meal.id);
      
      // Prepare the data to save
      final Map<String, dynamic> mealData = {
        'uid': user.uid,
        'idOfRecipe': meal.id,
        'time': meal.time,
        'date': date.toIso8601String().split('T')[0], // Store only the date part (YYYY-MM-DD)
        'Persons': meal.people,
        'createdAt': FieldValue.serverTimestamp(),
        // Embedded recipe snapshot for faster hydration
        'recipeTitle': meal.title,
        'recipeImage': meal.imageAssetPath,
        'recipeMinutes': meal.minutes,
      };
      
      // Add full recipe details if available
      if (recipeData != null) {
        mealData['recipeIngredients'] = recipeData['ingredients'] is List ? recipeData['ingredients'] : [];
        mealData['recipeInstructions'] = recipeData['steps'] is List ? recipeData['steps'] : [];
        mealData['recipeDescription'] = recipeData['description']?.toString();
      }
      
      // Create or update the document for this date
      final DocumentReference<Map<String, dynamic>> dateDoc = plannedMealsRef.doc(dateKey);
      
      // Save the meal under the date document with meal type as collection name
      await dateDoc.collection(meal.type).add(mealData);
    } catch (e) {
      debugPrint('Error saving meal to Firestore: $e');
    }
  }
  
  // Helper method to get month name abbreviation
  String _getMonthName(int month) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    // Cancel the listener when the ViewModel is disposed
    _mealTypesListener?.cancel();
    super.dispose();
  }
}