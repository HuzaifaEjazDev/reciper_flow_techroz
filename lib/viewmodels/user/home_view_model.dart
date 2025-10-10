import 'package:flutter/foundation.dart';
import 'package:recipe_app/models/dish.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class HomeViewModel extends ChangeNotifier {
  List<Dish> _recommendedRecipes = const <Dish>[];
  List<Dish> _easyMakeSnacks = const <Dish>[];
  List<Dish> _quickWeeknightMeals = const <Dish>[];
  List<String> _userCuisinePreferences = [];
  String? _userDietPreference;
  double _userRandomValue = 0.0; // Random value between 0-0.4

  List<Dish> get recommendedRecipes => _recommendedRecipes;
  List<Dish> get easyMakeSnacks => _easyMakeSnacks;
  List<Dish> get quickWeeknightMeals => _quickWeeknightMeals;

  // Method to refresh recommended recipes with a new random value
  Future<void> refreshRecommendedRecipes({double? forcedRandomValue}) async {
    // Use the forced random value if provided, otherwise generate a new one
    if (forcedRandomValue != null) {
      _userRandomValue = forcedRandomValue;
      print('Using forced user random value: $_userRandomValue');
    } else {
      // Generate a new random value between 0 and 0.4
      _userRandomValue = Random().nextDouble() * 0.4;
      print('Generated new user random value: $_userRandomValue');
    }
    
    // Fetch recommended recipes based on the new random value
    await _fetchRecommendedRecipes();
  }

  // Public method to refresh all data except recommended recipes
  Future<void> refreshOtherData() async {
    // Fetch user preferences
    await _fetchUserPreferences();
    
    // Fetch dishes for Easy Make Snack and Quick Weeknight Meals sections
    await _fetchEasyMakeSnacks();
    await _fetchQuickWeeknightMeals();
  }

  Future<void> loadInitial() async {
    // Generate random value between 0 and 0.4
    _userRandomValue = Random().nextDouble() * 0.4;
    print('Generated user random value: $_userRandomValue');
    
    // Fetch user preferences first
    await _fetchUserPreferences();
    
    // Fetch recommended recipes based on random value algorithm
    await _fetchRecommendedRecipes();
    
    // Fetch dishes for Easy Make Snack and Quick Weeknight Meals sections
    await _fetchEasyMakeSnacks();
    await _fetchQuickWeeknightMeals();
  }

  Future<void> _fetchUserPreferences() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('onboardingData')) {
          final onboardingData = data['onboardingData'] as Map<String, dynamic>?;
          if (onboardingData != null) {
            // Fetch cuisine preferences
            if (onboardingData.containsKey('cuisinePreferences') &&
                onboardingData['cuisinePreferences'] is List) {
              _userCuisinePreferences = List<String>.from(onboardingData['cuisinePreferences']);
              print('User cuisine preferences: $_userCuisinePreferences');
            }

            // Fetch diet preference
            if (onboardingData.containsKey('dietPreference')) {
              _userDietPreference = onboardingData['dietPreference'] as String?;
              print('User diet preference: $_userDietPreference');
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching user preferences: $e');
    }
  }

  Future<void> _fetchRecommendedRecipes() async {
    try {
      // For recommended recipes, we only filter by random value, not by cuisine or diet preferences
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('recipes').limit(20);
      
      final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      print('Fetched ${snapshot.docs.length} recipes from Firestore for recommended section');
      
      if (snapshot.docs.isNotEmpty) {
        // Filter recipes where randomValue > userRandomValue
        List<Dish> filteredRecipes = snapshot.docs.map((doc) {
          final data = doc.data();
          final double recipeRandomValue = (data['randomValue'] as num?)?.toDouble() ?? 0.0;
          print('Recipe ${data['title']} has randomValue: $recipeRandomValue, user randomValue: $_userRandomValue');
          return Dish(
            id: doc.id,
            title: data['title'] as String? ?? 'Untitled Recipe',
            subtitle: data['description'] as String? ?? 'Delicious recipe',
            imageAssetPath: data['imageUrl'] as String? ?? 'assets/images/dish/dish1.jpg',
            minutes: (data['totalMinutes'] as num?)?.toInt() ?? 0,
            randomValue: recipeRandomValue,
          );
        }).where((dish) => dish.randomValue != null && dish.randomValue! > _userRandomValue).toList();
        
        print('Filtered to ${filteredRecipes.length} recipes based on random value');
        
        // Shuffle the filtered recipes and take first 3
        if (filteredRecipes.isNotEmpty) {
          filteredRecipes.shuffle();
          _recommendedRecipes = filteredRecipes.take(3).toList();
          print('Selected 3 random recipes: ${_recommendedRecipes.map((d) => d.title).toList()}');
        } else {
          // If no recipes match the strict filter, try a more lenient approach
          print('No recipes matched strict filter, using all fetched recipes');
          List<Dish> allRecipes = snapshot.docs.map((doc) {
            final data = doc.data();
            final double recipeRandomValue = (data['randomValue'] as num?)?.toDouble() ?? 0.0;
            return Dish(
              id: doc.id,
              title: data['title'] as String? ?? 'Untitled Recipe',
              subtitle: data['description'] as String? ?? 'Delicious recipe',
              imageAssetPath: data['imageUrl'] as String? ?? 'assets/images/dish/dish1.jpg',
              minutes: (data['totalMinutes'] as num?)?.toInt() ?? 0,
              randomValue: recipeRandomValue,
            );
          }).toList();
          
          // Shuffle all recipes and take first 3
          allRecipes.shuffle();
          _recommendedRecipes = allRecipes.take(3).toList();
          print('Selected 3 random recipes from all fetched: ${_recommendedRecipes.map((d) => d.title).toList()}');
        }
      } 
      
      // If we still don't have recommended recipes, fallback to default logic
      if (_recommendedRecipes.isEmpty) {
        print('No recipes found, using fallback static recipes');
        _recommendedRecipes = const <Dish>[
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
      } else {
        print('Successfully loaded ${_recommendedRecipes.length} recommended recipes from database');
      }
    } catch (e) {
      print('Error fetching recommended recipes: $e');
      // Fallback to default recipes if there's an error
      _recommendedRecipes = const <Dish>[
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
    }
    
    notifyListeners();
  }

  Future<void> _fetchEasyMakeSnacks() async {
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('recipes');
      
      // Filter for easy make snacks (cooking time <= 15 minutes)
      query = query.where('totalMinutes', isLessThanOrEqualTo: 15);
      
      // Apply diet filter if user has a diet preference
      if (_userDietPreference != null && _userDietPreference!.isNotEmpty) {
        query = query.where('diet', isEqualTo: _userDietPreference);
      }
      
      // Apply cuisine filter if user has cuisine preferences
      if (_userCuisinePreferences.isNotEmpty) {
        query = query.where('cuisine', arrayContainsAny: _userCuisinePreferences);
      }
      
      // Limit to 5 snacks
      query = query.limit(5);
      
      final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        _easyMakeSnacks = snapshot.docs.map((doc) {
          final data = doc.data();
          return Dish(
            id: doc.id,
            title: data['title'] as String? ?? 'Untitled Recipe',
            subtitle: data['description'] as String? ?? 'Quick snack',
            imageAssetPath: data['imageUrl'] as String? ?? 'assets/images/easymakesnack1.jpg',
            minutes: (data['totalMinutes'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      } else {
        // Fallback to default snacks if no personalized ones found
        _easyMakeSnacks = const <Dish>[
          Dish(
            id: 'snack1',
            title: 'Crispy Bites',
            subtitle: 'Quick and delicious snack',
            imageAssetPath: 'assets/images/easymakesnack1.jpg',
            minutes: 8,
          ),
          Dish(
            id: 'snack2',
            title: 'Fruit Delight',
            subtitle: 'Healthy fruit snack',
            imageAssetPath: 'assets/images/easymakesnack2.jpg',
            minutes: 6,
          ),
          Dish(
            id: 'snack3',
            title: 'Cheesy Toast',
            subtitle: 'Simple cheesy toast',
            imageAssetPath: 'assets/images/easymakesnack3.jpg',
            minutes: 10,
          ),
        ];
      }
    } catch (e) {
      print('Error fetching easy make snacks: $e');
      // Fallback to default snacks if there's an error
      _easyMakeSnacks = const <Dish>[
        Dish(
          id: 'snack1',
          title: 'Crispy Bites',
          subtitle: 'Quick and delicious snack',
          imageAssetPath: 'assets/images/easymakesnack1.jpg',
          minutes: 8,
        ),
        Dish(
          id: 'snack2',
          title: 'Fruit Delight',
          subtitle: 'Healthy fruit snack',
          imageAssetPath: 'assets/images/easymakesnack2.jpg',
          minutes: 6,
        ),
        Dish(
          id: 'snack3',
          title: 'Cheesy Toast',
          subtitle: 'Simple cheesy toast',
          imageAssetPath: 'assets/images/easymakesnack3.jpg',
          minutes: 10,
        ),
      ];
    }
    
    notifyListeners();
  }

  Future<void> _fetchQuickWeeknightMeals() async {
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('recipes');
      
      // Filter for quick weeknight meals (cooking time between 15-30 minutes)
      query = query
          .where('totalMinutes', isGreaterThanOrEqualTo: 15)
          .where('totalMinutes', isLessThanOrEqualTo: 30);
      
      // Apply diet filter if user has a diet preference
      if (_userDietPreference != null && _userDietPreference!.isNotEmpty) {
        query = query.where('diet', isEqualTo: _userDietPreference);
      }
      
      // Apply cuisine filter if user has cuisine preferences
      if (_userCuisinePreferences.isNotEmpty) {
        query = query.where('cuisine', arrayContainsAny: _userCuisinePreferences);
      }
      
      // Limit to 5 meals
      query = query.limit(5);
      
      final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        _quickWeeknightMeals = snapshot.docs.map((doc) {
          final data = doc.data();
          return Dish(
            id: doc.id,
            title: data['title'] as String? ?? 'Untitled Recipe',
            subtitle: data['description'] as String? ?? 'Quick weeknight meal',
            imageAssetPath: data['imageUrl'] as String? ?? 'assets/images/quickweeknightmeals1.jpg',
            minutes: (data['totalMinutes'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      } else {
        // Fallback to default meals if no personalized ones found
        _quickWeeknightMeals = const <Dish>[
          Dish(
            id: 'meal1',
            title: 'Pasta Bowl',
            subtitle: 'Quick pasta meal',
            imageAssetPath: 'assets/images/quickweeknightmeals1.jpg',
            minutes: 20,
          ),
          Dish(
            id: 'meal2',
            title: 'Veggie Stir-fry',
            subtitle: 'Healthy vegetable stir-fry',
            imageAssetPath: 'assets/images/quickweeknightmeals2.jpg',
            minutes: 15,
          ),
          Dish(
            id: 'meal3',
            title: 'Grilled Wraps',
            subtitle: 'Delicious grilled wraps',
            imageAssetPath: 'assets/images/quickweeknightmeals3.jpg',
            minutes: 18,
          ),
        ];
      }
    } catch (e) {
      print('Error fetching quick weeknight meals: $e');
      // Fallback to default meals if there's an error
      _quickWeeknightMeals = const <Dish>[
        Dish(
          id: 'meal1',
          title: 'Pasta Bowl',
          subtitle: 'Quick pasta meal',
          imageAssetPath: 'assets/images/quickweeknightmeals1.jpg',
          minutes: 20,
        ),
        Dish(
          id: 'meal2',
          title: 'Veggie Stir-fry',
          subtitle: 'Healthy vegetable stir-fry',
          imageAssetPath: 'assets/images/quickweeknightmeals2.jpg',
          minutes: 15,
        ),
        Dish(
          id: 'meal3',
          title: 'Grilled Wraps',
          subtitle: 'Delicious grilled wraps',
          imageAssetPath: 'assets/images/quickweeknightmeals3.jpg',
          minutes: 18,
        ),
      ];
    }
    
    notifyListeners();
  }
}