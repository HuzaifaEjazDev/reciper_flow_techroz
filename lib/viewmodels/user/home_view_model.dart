import 'package:flutter/foundation.dart';
import 'package:recipe_app/models/user/dish.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';

class HomeViewModel extends ChangeNotifier {
  final FirestoreRecipesService _service = FirestoreRecipesService();

  List<Dish> _recommended = const <Dish>[];
  List<Dish> get recommended => _recommended;

  Future<void> loadInitial() async {
    try {
      final page = await _service.fetchRecipesPage(collection: 'recipes', limit: 4);
      final List<Dish> mapped = page.items.map(_mapToDish).toList();
      if (mapped.isNotEmpty) {
        _recommended = mapped;
        notifyListeners();
        return;
      }
    } catch (_) {
      // fall through to static fallback
    }

    _recommended = const <Dish>[
      Dish(
        id: '1',
        title: 'Berry Boost Smoothie Bowl',
        subtitle:
            'A refreshing and nutritious blend of mixed berries, banana, and almond milk, garnished with chia seeds and coconut flakes.',
        imageAssetPath: 'assets/images/dish/dish1.jpg',
        minutes: 10,
        rating: 4.5,
      ),
      Dish(
        id: '2',
        title: 'Mediterranean Quinoa Salad',
        subtitle:
            'Healthy and satisfying quinoa salad packed with fresh vegetables, tangy feta, and a zesty vinaigrette.',
        imageAssetPath: 'assets/images/dish/dish2.jpg',
        minutes: 25,
        rating: 4.9,
      ),
      Dish(
        id: '3',
        title: 'Crispy Honey Garlic Wings',
        subtitle:
            'Oven-baked chicken wings tossed in a sweet and savory honey-garlic sauce, perfect for appetizers.',
        imageAssetPath: 'assets/images/dish/dish3.jpg',
        minutes: 30,
        rating: 4.7,
      ),
    ];
    notifyListeners();
  }

  Dish _mapToDish(Map<String, dynamic> m) {
    final String id = (m['id'] ?? '').toString();
    final String title = (m['title'] ?? 'Untitled').toString();
    final String subtitle = (m['subtitle'] ?? m['description'] ?? '').toString();
    final String image = (m['imageUrl'] ?? m['image'] ?? '').toString();
    final int minutes = _safeInt(m['minutes']) ?? _safeInt(m['time']) ?? 0;
    final double rating = _safeDouble(m['rating']) ?? 0.0;
    return Dish(
      id: id.isEmpty ? title : id,
      title: title,
      subtitle: subtitle,
      imageAssetPath: image,
      minutes: minutes,
      rating: rating,
    );
  }

  int? _safeInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  double? _safeDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}


