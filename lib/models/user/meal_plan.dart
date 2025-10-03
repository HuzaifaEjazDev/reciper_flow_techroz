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
  final String? time; // Add time field
  final int? people; // Add people field
  final String? plannedId; // Firestore PlannedMeals doc id
  final List<String>? ingredients; // Add ingredients
  final List<String>? instructions; // Add instructions

  const MealEntry({
    required this.id,
    required this.type, // Change from MealType to String
    required this.title,
    required this.minutes,
    required this.imageAssetPath,
    this.time, // Add time parameter
    this.people, // Add people parameter
    this.plannedId,
    this.ingredients, // Add ingredients parameter
    this.instructions, // Add instructions parameter
  });
}

@immutable
class DayPlan {
  final DateTime date;
  final List<MealEntry> meals;

  const DayPlan({required this.date, required this.meals});

  List<MealEntry> mealsOfType(String type) {
    return meals.where((m) => m.type == type).toList(growable: false);
  }
  
  // Method to add a meal to the day plan
  DayPlan copyWithMeal(MealEntry meal) {
    final List<MealEntry> updatedMeals = List.from(meals)..add(meal);
    return DayPlan(date: date, meals: updatedMeals);
  }

  // Explicit method to append a meal without removing existing ones
  DayPlan addMeal(MealEntry meal) {
    final List<MealEntry> updatedMeals = List<MealEntry>.from(meals)..add(meal);
    return DayPlan(date: date, meals: updatedMeals);
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