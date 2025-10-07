import 'package:flutter/foundation.dart';
import 'package:recipe_app/models/dish.dart';

class HomeViewModel extends ChangeNotifier {
  List<Dish> _recommended = const <Dish>[];

  List<Dish> get recommended => _recommended;

  void loadInitial() {
    _recommended = const <Dish>[
      Dish(
        id: '1',
        title: 'Berry Boost Smoothie Bowl',
        subtitle:
            'A refreshing and nutritious blend of mixed berries, banana, and almond milk, garnished with chia seeds and coconut flakes.',
        imageAssetPath: 'assets/images/dish/dish1.jpg',
        minutes: 10,
      ),
      Dish(
        id: '2',
        title: 'Mediterranean Quinoa Salad',
        subtitle:
            'Healthy and satisfying quinoa salad packed with fresh vegetables, tangy feta, and a zesty vinaigrette.',
        imageAssetPath: 'assets/images/dish/dish2.jpg',
        minutes: 25,
      ),
      Dish(
        id: '3',
        title: 'Crispy Honey Garlic Wings',
        subtitle:
            'Oven-baked chicken wings tossed in a sweet and savory honey-garlic sauce, perfect for appetizers.',
        imageAssetPath: 'assets/images/dish/dish3.jpg',
        minutes: 30,
      ),
    ];
    notifyListeners();
  }
}