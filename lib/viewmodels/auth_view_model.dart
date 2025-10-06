import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipe_app/services/auth_service.dart';
import 'package:recipe_app/models/meal_plan.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _authService.currentUser;

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmailAndPassword(email, password);
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Register with email and password
  Future<bool> signUp(String email, String password, {String? name}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.createUserWithEmailAndPassword(email, password, name: name);
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Save a meal plan for the current user under PlannedMeals subcollection
  Future<bool> saveMealPlan(DayPlan dayPlan) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.saveMealPlan(dayPlan);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get meal plans for the current user from PlannedMeals subcollection
  Future<List<DayPlan>?> getUserMealPlans() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final mealPlans = await _authService.getUserMealPlans();
      _isLoading = false;
      notifyListeners();
      return mealPlans;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    notifyListeners();
  }

  Future<void> updateDisplayName(String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.updateDisplayName(name);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.deleteAccount();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}