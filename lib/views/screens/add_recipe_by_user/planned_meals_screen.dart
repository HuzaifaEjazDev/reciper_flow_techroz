import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/models/meal_plan.dart'; // Make sure this import is correct
import 'package:recipe_app/viewmodels/user/planned_meals_view_model.dart';
import 'package:recipe_app/views/screens/add_recipe_by_user/my_recipes_screen.dart';
import 'package:recipe_app/views/screens/recipe_details_screen.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';

class PlannedMealsScreen extends StatelessWidget {
  const PlannedMealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PlannedMealsViewModel>(
      create: (_) => PlannedMealsViewModel()..loadPlannedMeals(),
      child: const _PlannedMealsView(),
    );
  }
}

class _PlannedMealsView extends StatelessWidget {
  const _PlannedMealsView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlannedMealsViewModel>();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Groceries', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: SafeArea(
        child: vm.loading && vm.groupedMeals.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : vm.error != null
                ? Center(
                    child: Text('Error loading planned meals: ${vm.error}'),
                  )
                : vm.groupedMeals.isEmpty
                    ? _EmptyStateView()
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...vm.groupedMeals.entries.map((entry) {
                                final String dateKey = entry.key;
                                final List<PlannedMeal> meals = entry.value;
                                return _DateSection(dateKey: dateKey, meals: meals);
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No groceries found',
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
          const SizedBox(height: 20),
          const Text(
            'Create your own recipes and add to groceries!',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyRecipesScreen()),
              );
            },
            child: const Text('View My Recipes'),
          ),
        ],
      ),
    );
  }
}

class _DateSection extends StatelessWidget {
  final String dateKey;
  final List<PlannedMeal> meals;
  
  const _DateSection({required this.dateKey, required this.meals});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: Text(
            dateKey,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Grid of meals for this date
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: meals.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) => _PlannedMealCard(meal: meals[index]),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PlannedMealCard extends StatelessWidget {
  final PlannedMeal meal;
  
  const _PlannedMealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Navigate to recipe details screen on card tap
        final service = FirestoreRecipesService();
        final recipeData = await service.fetchPlannedMealById(meal.uniqueId);
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeDetailsScreen(
              title: meal.recipeTitle,
              imageAssetPath: meal.recipeImage,
              minutes: meal.minutes,
              ingredients: _extractIngredientsStrings(meal.ingredients),
              steps: meal.instructions,
              recipeId: meal.uniqueId,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Recipe image
            SizedBox(
              height: 105,
              child: meal.recipeImage.startsWith('http')
                  ? Image.network(
                      meal.recipeImage,
                      fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                      const ColoredBox(color: Color(0xFFE5E7EB)),
                  )
                  : Image.asset(
                      meal.recipeImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          const ColoredBox(color: Color(0xFFE5E7EB)),
                  ),
            ),
            // Recipe details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe title
                    Text(
                      meal.recipeTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Meal type
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        meal.mealType,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Time and persons
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          meal.timeForRecipe,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.person, size: 16, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          '${meal.persons}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<String> _extractIngredientsStrings(List<Ingredient> ingredients) {
    return ingredients.map((ingredient) {
      final List<String> parts = <String>[];
      if (ingredient.emoji != null && ingredient.emoji!.isNotEmpty) {
        parts.add(ingredient.emoji!);
      }
      if (ingredient.quantity != null && ingredient.quantity!.isNotEmpty) {
        parts.add(ingredient.quantity!);
      }
      if (ingredient.unit != null && ingredient.unit!.isNotEmpty) {
        parts.add(ingredient.unit!);
      }
      if (ingredient.name.isNotEmpty) {
        parts.add(ingredient.name);
      }
      return parts.join(' ');
    }).toList();
  }
}