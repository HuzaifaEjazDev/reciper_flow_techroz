import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/core/constants/app_colors.dart';
import 'package:recipe_app/models/user_created_recipe.dart';
import 'package:recipe_app/viewmodels/user/user_recipe_details_view_model.dart';
import 'package:recipe_app/views/screens/add_recipe_by_user/create_new_recipe_screen.dart';

class UserRecipeDetailsScreen extends StatelessWidget {
  final String recipeId;
  
  const UserRecipeDetailsScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserRecipeDetailsViewModel>(
      create: (_) => UserRecipeDetailsViewModel(recipeId),
      child: const _UserRecipeDetailsView(),
    );
  }
}

class _UserRecipeDetailsView extends StatefulWidget {
  const _UserRecipeDetailsView();

  @override
  State<_UserRecipeDetailsView> createState() => _UserRecipeDetailsViewState();
}

class _UserRecipeDetailsViewState extends State<_UserRecipeDetailsView> {
  // Show delete confirmation dialog
  void _showDeleteConfirmationDialog(UserRecipeDetailsViewModel vm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Delete Recipe'),
          content: const Text('Are you sure you want to delete this recipe? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _deleteRecipe(vm); // Delete the recipe
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Delete the recipe
  Future<void> _deleteRecipe(UserRecipeDetailsViewModel vm) async {
    try {
      final bool success = await vm.deleteRecipe();
      
      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipe deleted successfully!')),
          );
          
          // Navigate back to the previous screen
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete recipe. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserRecipeDetailsViewModel>(
      builder: (context, vm, child) {
        // Handle the case when recipe is deleted (real-time listener detects it's gone)
        if (vm.recipe == null && !vm.loading) {
          // Recipe was deleted, automatically pop the screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
          
          // Show a temporary message while popping
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text('Recipe deleted. Returning to list...')),
          );
        }

        // Handle loading state
        if (vm.loading && vm.recipe == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Handle error state
        if (vm.error != null && vm.recipe == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Text('Error loading recipe: ${vm.error}'),
            ),
          );
        }

        // Handle recipe not found
        if (vm.recipe == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Text('Recipe not found'),
            ),
          );
        }

        final recipe = vm.recipe!;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text('User Recipe Details', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            iconTheme: const IconThemeData(color: Colors.black87),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  // Show delete confirmation dialog
                  _showDeleteConfirmationDialog(vm);
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // Navigate to edit screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateNewRecipeScreen(
                        isEdit: true,
                        recipeId: vm.recipeId,
                      ),
                    ),
                  );
                },
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroImage(title: recipe.title, imageAssetPath: recipe.imageUrl),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.black87),
                          const SizedBox(width: 10),
                          const Text('Estimate Time:', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
                          const SizedBox(width: 8),
                          // Display cooking time
                          Text(
                            recipe.minutes > 0 ? '${recipe.minutes} min' : 'Not available',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle(text: 'Ingredients'),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: recipe.ingredients.isEmpty
                          ? [
                              const _IngredientTile(name: 'No ingredients available', note: ''),
                            ]
                          : recipe.ingredients
                              .asMap()
                              .entries
                              .map((entry) => _IngredientTile(
                                    name: '${entry.key + 1}. ${entry.value['quantity']} ${entry.value['name']}',
                                    note: '',
                                  ))
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle(text: 'Cooking Steps'),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: recipe.steps.isEmpty
                          ? [
                              const _StepCard(step: 1, text: 'No steps available'),
                            ]
                          : List<Widget>.generate(
                              recipe.steps.length,
                              (i) => _StepCard(step: i + 1, text: recipe.steps[i]),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String title;
  final String imageAssetPath;
  const _HeroImage({required this.title, required this.imageAssetPath});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.zero,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(imageAssetPath, fit: BoxFit.cover),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xAA000000)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.25,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
      ),
    );
  }
}

class _IngredientTile extends StatelessWidget {
  final String name;
  final String note;
  const _IngredientTile({required this.name, required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF7F4F4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            note,
            style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int step;
  final String text;
  const _StepCard({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary500,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$step',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}