import 'package:flutter/foundation.dart';

// Remove the MealType enum since we'll use string meal types
// enum MealType { breakfast, lunch, dinner }

@immutable
class MealEntry {
  final String id;
  final String type; // Change from MealType to String
  final String title;
  final int minutes;
  final String imageAssetPath;

  const MealEntry({
    required this.id,
    required this.type, // Change from MealType to String
    required this.title,
    required this.minutes,
    required this.imageAssetPath,
  });
}

@immutable
class DayPlan {
  final DateTime date;
  final List<MealEntry> meals;

  const DayPlan({required this.date, required this.meals});

  MealEntry? mealOfType(String type) { // Change parameter from MealType to String
    try {
      return meals.firstWhere((m) => m.type == type);
    } catch (_) {
      return null;
    }
  }
  
  // Method to add a meal to the day plan
  DayPlan copyWithMeal(MealEntry meal) {
    final List<MealEntry> updatedMeals = List.from(meals);
    
    // Remove existing meal of the same type if it exists
    updatedMeals.removeWhere((m) => m.type == meal.type);
    
    // Add the new meal
    updatedMeals.add(meal);
    
    return DayPlan(
      date: date,
      meals: updatedMeals,
    );
  }
}

// New model for storing recipe data that can be added to meal planner
@immutable
class RecipeData {
  final String id;
  final String title;
  final String imageAssetPath;
  final int minutes;
  
  const RecipeData({
    required this.id,
    required this.title,
    required this.imageAssetPath,
    required this.minutes,
  });
}