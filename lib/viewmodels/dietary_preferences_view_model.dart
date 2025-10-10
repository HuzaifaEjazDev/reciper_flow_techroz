import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';

class DietaryPreferencesViewModel extends ChangeNotifier {
  final FirestoreRecipesService _firestoreService;
  
  List<String> _cuisines = [];
  List<String> _diets = [];
  Set<String> _selectedCuisines = <String>{};
  Set<String> _selectedDiets = <String>{};
  bool _isLoading = false;
  String? _errorMessage;

  DietaryPreferencesViewModel({FirestoreRecipesService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreRecipesService();

  // Getters
  List<String> get cuisines => _cuisines;
  List<String> get diets => _diets;
  Set<String> get selectedCuisines => _selectedCuisines;
  Set<String> get selectedDiets => _selectedDiets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize the view model by fetching data
  Future<void> init() async {
    await fetchPreferencesData();
    await fetchUserPreferences();
  }

  // Fetch available cuisines and diets from Firestore collections
  Future<void> fetchPreferencesData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch cuisines from 'cuisines' collection
      _cuisines = await _firestoreService.fetchCollectionStrings('cuisines');
      
      // Fetch diets from 'diets' collection
      _diets = await _firestoreService.fetchCollectionStrings('diets');
      
      // Add default options if collections are empty
      if (_cuisines.isEmpty) {
        _cuisines = [
          'Italian','Mexican','Indian','Chinese','Japanese','French','Thai','Mediterranean','American',
        ];
      }
      
      if (_diets.isEmpty) {
        _diets = [
          'Vegetarian','Non-Veg','Gluten-Free','Keto ','Paleo','Low-Carb','Diary_Free'
        ];
      }
    } catch (e) {
      _errorMessage = 'Failed to load preferences data';
      print('Error fetching preferences data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch user's current preferences from Firestore
  Future<void> fetchUserPreferences() async {
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
              _selectedCuisines = Set<String>.from(onboardingData['cuisinePreferences']);
            }

            // Fetch diet preferences
            if (onboardingData.containsKey('dietPreferences') &&
                onboardingData['dietPreferences'] is List) {
              _selectedDiets = Set<String>.from(onboardingData['dietPreferences']);
            }
          }
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load user preferences';
      print('Error fetching user preferences: $e');
    } finally {
      notifyListeners();
    }
  }

  // Toggle cuisine selection
  void toggleCuisine(String cuisine) {
    if (_selectedCuisines.contains(cuisine)) {
      _selectedCuisines.remove(cuisine);
    } else {
      _selectedCuisines.add(cuisine);
    }
    notifyListeners();
  }

  // Toggle diet selection
  void toggleDiet(String diet) {
    if (_selectedDiets.contains(diet)) {
      _selectedDiets.remove(diet);
    } else {
      _selectedDiets.add(diet);
    }
    notifyListeners();
  }

  // Save preferences to Firestore
  Future<bool> savePreferences() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'onboardingData': {
          'cuisinePreferences': _selectedCuisines.toList(),
          'dietPreferences': _selectedDiets.toList(),
        }
      }, SetOptions(merge: true));
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save preferences';
      print('Error saving preferences: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}