import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

// New model for ingredients with unit information
@immutable
class Ingredient {
  final String name;
  final String? emoji;
  final String? quantity;

  const Ingredient({
    required this.name,
    this.emoji,
    this.quantity,
  });

  factory Ingredient.fromMap(Map<String, dynamic> data) {
    return Ingredient(
      name: data['name']?.toString() ?? '',
      emoji: data['emoji']?.toString(),
      quantity: data['quantity']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (emoji != null) 'emoji': emoji,
      if (quantity != null) 'quantity': quantity,
    };
  }

  @override
  String toString() {
    final List<String> parts = <String>[];
    if (emoji != null && emoji!.isNotEmpty) parts.add(emoji!);
    if (quantity != null && quantity!.isNotEmpty) parts.add(quantity!);
    parts.add(name);
    return parts.join(' ');
  }
}

@immutable
class PlannedMeal {
  final String uniqueId; // Auto-generated unique ID for recipe data
  final String recipeTitle;
  final String dateForRecipe; // Date in format "D MMM" (e.g., "2 Oct", "7 Oct") - stored as field
  final String timeForRecipe; // User set time from dialog box
  final int persons; // User set persons from dialog box
  final List<Ingredient> ingredients; // Updated to use Ingredient model with unit information
  final List<String> instructions; // Uploaded from admin app
  final String recipeImage; // Static image for all recipe data
  final String mealType; // breakfast, lunch, dinner, etc. - stored as field
  final DateTime createdAt;
  final int minutes; // Add minutes field

  const PlannedMeal({
    required this.uniqueId,
    required this.recipeTitle,
    required this.dateForRecipe,
    required this.timeForRecipe,
    required this.persons,
    required this.ingredients,
    required this.instructions,
    required this.recipeImage,
    required this.mealType,
    required this.createdAt,
    required this.minutes, // Add minutes parameter
  });

  factory PlannedMeal.fromFirestore(Map<String, dynamic> data, String documentId) {
    return PlannedMeal(
      uniqueId: documentId,
      recipeTitle: data['recipeTitle']?.toString() ?? '',
      dateForRecipe: data['dateForRecipe']?.toString() ?? '',
      timeForRecipe: data['timeForRecipe']?.toString() ?? '',
      persons: data['persons'] as int? ?? 1,
      ingredients: data['ingredients'] is List 
          ? (data['ingredients'] as List).map((item) {
              if (item is Map<String, dynamic>) {
                return Ingredient.fromMap(item);
              } else {
                // Handle legacy string format
                return Ingredient(name: item.toString());
              }
            }).toList() 
          : [],
      instructions: data['instructions'] is List ? List<String>.from(data['instructions']) : [],
      recipeImage: data['recipeImage']?.toString() ?? 'assets/images/dish/dish1.jpg',
      mealType: data['mealType']?.toString() ?? '',
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      minutes: data['minutes'] as int? ?? 0, // Add minutes from Firestore
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipeTitle': recipeTitle,
      'dateForRecipe': dateForRecipe,
      'timeForRecipe': timeForRecipe,
      'persons': persons,
      'ingredients': ingredients.map((ingredient) => ingredient.toMap()).toList(),
      'instructions': instructions,
      'recipeImage': recipeImage,
      'mealType': mealType,
      'createdAt': Timestamp.fromDate(createdAt),
      'minutes': minutes, // Add minutes to Firestore
    };
  }

  PlannedMeal copyWith({
    String? uniqueId,
    String? recipeTitle,
    String? dateForRecipe,
    String? timeForRecipe,
    int? persons,
    List<Ingredient>? ingredients,
    List<String>? instructions,
    String? recipeImage,
    String? mealType,
    DateTime? createdAt,
    int? minutes, // Add minutes parameter
  }) {
    return PlannedMeal(
      uniqueId: uniqueId ?? this.uniqueId,
      recipeTitle: recipeTitle ?? this.recipeTitle,
      dateForRecipe: dateForRecipe ?? this.dateForRecipe,
      timeForRecipe: timeForRecipe ?? this.timeForRecipe,
      persons: persons ?? this.persons,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      recipeImage: recipeImage ?? this.recipeImage,
      mealType: mealType ?? this.mealType,
      createdAt: createdAt ?? this.createdAt,
      minutes: minutes ?? this.minutes, // Add minutes parameter
    );
  }
}
