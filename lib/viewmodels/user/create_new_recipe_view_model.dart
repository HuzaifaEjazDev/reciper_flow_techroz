import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/models/user/user_recipe.dart';
import 'package:image_picker/image_picker.dart';

class CreateNewRecipeViewModel extends ChangeNotifier {
  String? imagePath;
  final TextEditingController titleController = TextEditingController();

  final List<TextEditingController> qtyControllers = <TextEditingController>[];
  final List<TextEditingController> nameControllers = <TextEditingController>[];

  final List<TextEditingController> stepControllers = <TextEditingController>[];

  CreateNewRecipeViewModel() {
    addIngredient();
    addStep();
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        imagePath = picked.path;
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
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    for (final c in qtyControllers) c.dispose();
    for (final c in nameControllers) c.dispose();
    for (final c in stepControllers) c.dispose();
    super.dispose();
  }
}


