import 'package:flutter/material.dart';
import 'package:recipe_app/models/user/user_recipe.dart';

class MyRecipeCardData {
  final String title;
  final String imageAssetPath;
  final int ingredientsCount;
  final int stepsCount;
  final UserRecipe? recipe;
  MyRecipeCardData({
    required this.title,
    required this.imageAssetPath,
    required this.ingredientsCount,
    required this.stepsCount,
    this.recipe,
  });
}

class MyRecipesViewModel extends ChangeNotifier {
  final List<MyRecipeCardData> _items = <MyRecipeCardData>[
    MyRecipeCardData(title: 'Spicy Garlic\nNoodles', imageAssetPath: 'assets/images/easymakesnack1.jpg', ingredientsCount: 8, stepsCount: 5),
    MyRecipeCardData(title: 'Healthy Vegan\nBowl', imageAssetPath: 'assets/images/quickweeknightmeals2.jpg', ingredientsCount: 12, stepsCount: 4),
    MyRecipeCardData(title: 'Creamy Chicken\nCurry', imageAssetPath: 'assets/images/quickweeknightmeals1.jpg', ingredientsCount: 10, stepsCount: 6),
    MyRecipeCardData(title: 'Morning Burrito\nBoost', imageAssetPath: 'assets/images/quickweeknightmeals3.jpg', ingredientsCount: 7, stepsCount: 3),
    MyRecipeCardData(title: 'Lemon Herb\nSalmon', imageAssetPath: 'assets/images/easymakesnack2.jpg', ingredientsCount: 6, stepsCount: 4),
    MyRecipeCardData(title: 'Classic Tomato\nSoup', imageAssetPath: 'assets/images/easymakesnack3.jpg', ingredientsCount: 5, stepsCount: 3),
  ];

  List<MyRecipeCardData> get items => List.unmodifiable(_items);

  void add(MyRecipeCardData card) {
    _items.add(card);
    notifyListeners();
  }
}


