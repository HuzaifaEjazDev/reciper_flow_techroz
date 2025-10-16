import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/models/user_recipe.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipe_app/services/imgbb_service.dart';

class CreateNewRecipeViewModel extends ChangeNotifier {
  String? imagePath;
  String? _imageUrl; // To store the uploaded image URL
  String? _editingImageUrl; // To store the image URL when editing
  final TextEditingController titleController = TextEditingController();
  final TextEditingController minutesController = TextEditingController(); // Add minutes controller
  String? _recipeId;

  final List<TextEditingController> qtyControllers = <TextEditingController>[];
  final List<TextEditingController> nameControllers = <TextEditingController>[];

  final List<TextEditingController> stepControllers = <TextEditingController>[];
  final FirestoreRecipesService _firestoreService = FirestoreRecipesService();

  CreateNewRecipeViewModel() {
    addIngredient();
    addStep();
  }

  // Method to set recipe ID for editing
  void setRecipeId(String recipeId) {
    _recipeId = recipeId;
  }

  // Method to set image URL when editing
  void setImageUrlForEditing(String imageUrl) {
    _editingImageUrl = imageUrl;
    notifyListeners();
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        imagePath = picked.path;
        // Clear the editing image URL when a new image is picked
        _editingImageUrl = null;
        notifyListeners();
      }
    } catch (e) {
      // ignore errors for now (UI can show a snackbar if needed)
    }
  }

  void prefillFrom(UserRecipe? recipe) {
    if (recipe == null) return;
    imagePath = recipe.imagePath;
    titleController.text = recipe.title;
    minutesController.text = recipe.minutes.toString(); // Prefill minutes
    // Clear existing
    for (final c in qtyControllers) c.dispose();
    for (final c in nameControllers) c.dispose();
    for (final c in stepControllers) c.dispose();
    qtyControllers.clear();
    nameControllers.clear();
    stepControllers.clear();
    // Fill ingredients
    for (final ing in recipe.ingredients) {
      qtyControllers.add(TextEditingController(text: ing.quantity));
      nameControllers.add(TextEditingController(text: ing.name));
    }
    // Ensure at least one row exists
    if (qtyControllers.isEmpty) {
      addIngredient();
    }
    // Steps
    for (final st in recipe.steps) {
      stepControllers.add(TextEditingController(text: st.text));
    }
    if (stepControllers.isEmpty) {
      addStep();
    }
    notifyListeners();
  }

  void setImagePath(String? path) {
    imagePath = path;
    notifyListeners();
  }

  void addIngredient({String quantity = '', String name = ''}) {
    qtyControllers.add(TextEditingController(text: quantity));
    nameControllers.add(TextEditingController(text: name));
    notifyListeners();
  }

  void removeIngredient(int index) {
    if (index < 0 || index >= qtyControllers.length) return;
    qtyControllers.removeAt(index).dispose();
    nameControllers.removeAt(index).dispose();
    notifyListeners();
  }

  void addStep({String text = ''}) {
    stepControllers.add(TextEditingController(text: text));
    notifyListeners();
  }

  void removeStep(int index) {
    if (index < 0 || index >= stepControllers.length) return;
    stepControllers.removeAt(index).dispose();
    notifyListeners();
  }

  UserRecipe buildRecipe() {
    return UserRecipe(
      imagePath: imagePath,
      title: titleController.text.trim(),
      ingredients: List<UserRecipeIngredient>.generate(qtyControllers.length, (int i) {
        return UserRecipeIngredient(
          quantity: qtyControllers[i].text.trim(),
          name: nameControllers[i].text.trim(),
        );
      }),
      steps: stepControllers
          .map((c) => UserRecipeStep(text: c.text.trim()))
          .where((s) => s.text.isNotEmpty)
          .toList(),
      minutes: int.tryParse(minutesController.text) ?? 0, // Add minutes to recipe
    );
  }

  // Get the image URL to display (either the editing URL or the uploaded URL)
  String? get displayImageUrl => _editingImageUrl ?? _imageUrl;

  // Save the recipe to Firestore
  Future<bool> saveRecipeToFirestore() async {
    // Validate title
    final String title = titleController.text.trim();
    if (title.isEmpty) {
      debugPrint('Validation failed: empty title');
      throw Exception('Please enter recipe name');
    }

    // Validate at least one ingredient name
    final bool hasAtLeastOneIngredient = nameControllers.any((c) => c.text.trim().isNotEmpty);
    if (!hasAtLeastOneIngredient) {
      debugPrint('Validation failed: no ingredients');
      throw Exception('Please add at least 1 ingredient');
    }

    try {
      // Upload image to imgbb if an image was selected
      if (imagePath != null && imagePath!.isNotEmpty) {
        try {
          _imageUrl = await ImgbbService.uploadImage(imagePath!);
          debugPrint('Image uploaded successfully. URL: $_imageUrl');
        } catch (e) {
          debugPrint('Error uploading image: $e');
          // If image upload fails, we'll use the default image
          _imageUrl = 'assets/images/vegitables.jpg';
        }
      } else if (_editingImageUrl != null) {
        // If we're editing and no new image was selected, keep the existing image URL
        _imageUrl = _editingImageUrl;
      } else {
        // If no image was selected, use the default image
        _imageUrl = 'assets/images/vegitables.jpg';
      }

      // Prepare ingredients as list of maps, filtering out empty entries
      final List<Map<String, dynamic>> ingredients = [];
      for (int i = 0; i < qtyControllers.length; i++) {
        final String quantity = qtyControllers[i].text.trim();
        final String name = nameControllers[i].text.trim();
        // Only add ingredient if either quantity or name is not empty
        if (quantity.isNotEmpty || name.isNotEmpty) {
          ingredients.add({
            'quantity': quantity,
            'name': name,
          });
        }
      }

      // Prepare steps as list of strings
      final List<String> steps = stepControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      // Parse minutes
      final int minutes = int.tryParse(minutesController.text) ?? 0;

      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // If we have a recipe ID, we're updating an existing recipe
      if (_recipeId != null) {
        // Update existing recipe
        await _firestoreService.updateUserCreatedRecipe(
          recipeId: _recipeId!,
          title: titleController.text.trim(),
          ingredients: ingredients,
          steps: steps,
          minutes: minutes,
          imageUrl: _imageUrl!, // Use the uploaded image URL or default
        );
      } else {
        // Create new recipe
        await _firestoreService.saveUserCreatedRecipe(
          title: titleController.text.trim(),
          ingredients: ingredients,
          steps: steps,
          minutes: minutes, // Add minutes to create
          imageUrl: _imageUrl!, // Pass the image URL
        );
      }
      
      return true;
    } catch (e) {
      debugPrint('Error saving recipe to Firestore: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    minutesController.dispose(); // Dispose minutes controller
    for (final c in qtyControllers) c.dispose();
    for (final c in nameControllers) c.dispose();
    for (final c in stepControllers) c.dispose();
    super.dispose();
  }
}