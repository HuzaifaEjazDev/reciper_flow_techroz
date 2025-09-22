import 'package:flutter/foundation.dart';

enum MealType { breakfast, lunch, dinner }

@immutable
class MealEntry {
  final String id;
  final MealType type;
  final String title;
  final int minutes;
  final String imageAssetPath;

  const MealEntry({
    required this.id,
    required this.type,
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

  MealEntry? mealOfType(MealType type) {
    try {
      return meals.firstWhere((m) => m.type == type);
    } catch (_) {
      return null;
    }
  }
}


