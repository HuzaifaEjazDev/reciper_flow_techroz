class UserRecipeIngredient {
  final String quantity;
  final String name;

  UserRecipeIngredient({required this.quantity, required this.name});
}

class UserRecipeStep {
  final String text;
  UserRecipeStep({required this.text});
}

class UserRecipe {
  final String? imagePath; // Local path or asset path
  final String title;
  final List<UserRecipeIngredient> ingredients;
  final List<UserRecipeStep> steps;
  final int minutes; // Add minutes field

  UserRecipe({
    required this.imagePath,
    required this.title,
    required this.ingredients,
    required this.steps,
    this.minutes = 0, // Add minutes parameter with default value
  });
}