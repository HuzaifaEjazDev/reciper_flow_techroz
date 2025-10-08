import 'package:flutter/material.dart';
import 'package:recipe_app/models/meal_plan.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';

class PlannedMealsViewModel extends ChangeNotifier {
  final FirestoreRecipesService _service = FirestoreRecipesService();
  
  Map<String, List<PlannedMeal>> _groupedMeals = {};
  Map<String, List<PlannedMeal>> get groupedMeals => _groupedMeals;
  
  bool _loading = false;
  bool get loading => _loading;
  
  String? _error;
  String? get error => _error;

  Future<void> loadPlannedMeals() async {
    if (_loading) return;
    
    _loading = true;
    _error = null;
    notifyListeners();
    
    try {
      final List<PlannedMeal> allMeals = await _service.getAllPlannedMeals();
      
      // Group meals by date
      final Map<String, List<PlannedMeal>> groupedMeals = {};
      for (final meal in allMeals) {
        if (!groupedMeals.containsKey(meal.dateForRecipe)) {
          groupedMeals[meal.dateForRecipe] = [];
        }
        groupedMeals[meal.dateForRecipe]!.add(meal);
      }
      
      // Sort dates chronologically
      final List<String> sortedDates = groupedMeals.keys.toList()
        ..sort((a, b) {
          // Parse date strings to DateTime for comparison
          final DateTime dateA = _parseDateKey(a);
          final DateTime dateB = _parseDateKey(b);
          return dateA.compareTo(dateB);
        });
      
      // Create a new map with sorted dates
      final Map<String, List<PlannedMeal>> sortedGroupedMeals = {};
      for (final date in sortedDates) {
        sortedGroupedMeals[date] = groupedMeals[date]!;
      }
      
      _groupedMeals = sortedGroupedMeals;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Helper method to parse date key back to DateTime
  DateTime _parseDateKey(String dateKey) {
    final RegExp regex = RegExp(r'^(\d+) ([A-Za-z]+)$');
    final Match? match = regex.firstMatch(dateKey);
    
    if (match == null) {
      return DateTime.now(); // fallback
    }
    
    final int day = int.parse(match.group(1)!);
    final String monthStr = match.group(2)!;
    
    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final int month = months.indexOf(monthStr) + 1;
    final int year = DateTime.now().year;
    
    // Handle year transition (if month is in the past, it's probably next year)
    final DateTime now = DateTime.now();
    if (month < now.month && (now.month - month) > 6) {
      return DateTime(year + 1, month, day);
    }
    
    return DateTime(year, month, day);
  }
}