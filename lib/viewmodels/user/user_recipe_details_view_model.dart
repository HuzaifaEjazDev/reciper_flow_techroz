import 'package:flutter/material.dart';
import 'package:recipe_app/models/user_created_recipe.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class UserRecipeDetailsViewModel extends ChangeNotifier {
  final String recipeId;
  final FirestoreRecipesService _service = FirestoreRecipesService();
  
  UserCreatedRecipe? _recipe;
  UserCreatedRecipe? get recipe => _recipe;
  
  bool _loading = false;
  bool get loading => _loading;
  
  String? _error;
  String? get error => _error;
  
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _recipeListener;

  UserRecipeDetailsViewModel(this.recipeId) {
    // Fetch initial data
    fetchRecipeDetails();
    
    // Set up real-time listener after a brief delay to avoid build phase issues
    Future.microtask(() {
      _setupRecipeListener();
    });
  }

  void _setupRecipeListener() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final DocumentReference<Map<String, dynamic>> recipeRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('RecipesCreatedByUser')
        .doc(recipeId);

    _recipeListener = recipeRef.snapshots().listen(
      (snapshot) {
        if (snapshot.exists) {
          _recipe = UserCreatedRecipe.fromFirestore(snapshot.data()!, snapshot.id);
          notifyListeners();
        } else {
          // Recipe was deleted, notify listeners
          _recipe = null;
          notifyListeners();
        }
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  Future<UserCreatedRecipe?> fetchRecipeDetails() async {
    if (_loading) return null;
    
    _loading = true;
    _error = null;
    
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('RecipesCreatedByUser')
          .doc(recipeId)
          .get();

      if (!doc.exists) {
        throw Exception('Recipe not found');
      }

      _recipe = UserCreatedRecipe.fromFirestore(doc.data()!, doc.id);
      return _recipe;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteRecipe() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('RecipesCreatedByUser')
          .doc(recipeId)
          .delete();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _recipeListener?.cancel();
    super.dispose();
  }
}