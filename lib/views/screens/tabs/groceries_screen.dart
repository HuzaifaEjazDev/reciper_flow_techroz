import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/viewmodels/user/meal_planner_view_model.dart';
import 'package:recipe_app/models/meal_plan.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';

class GroceriesScreen extends StatefulWidget {
  const GroceriesScreen({super.key});

  @override
  State<GroceriesScreen> createState() => _GroceriesScreenState();
}

class _GroceriesScreenState extends State<GroceriesScreen> {
  final Set<String> _checked = <String>{};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 70),
        children: [
          _buildSearchBar(),
          const SizedBox(height: 16),

          _buildRecipesHeader(context),
          const SizedBox(height: 10),
          _buildRecipeCardsRow(context),

          const SizedBox(height: 20),
          _buildSortRow(),

          const SizedBox(height: 20),
          _buildGroceryItemsFromPlannedMeals(context),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: const [
          Icon(Icons.search, color: Colors.black87, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search Groceries',
              style: TextStyle(color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipesHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Recipes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
        TextButton.icon(
          onPressed: () {},
          style: TextButton.styleFrom(foregroundColor: Colors.black87),
          icon: const Text('All Recipes', style: TextStyle(fontWeight: FontWeight.w600)),
          label: const Icon(CupertinoIcons.chevron_right, color: Colors.black87),
        )
      ],
    );
  }

  Widget _buildRecipeCardsRow(BuildContext context) {
    final mealPlannerVM = context.watch<MealPlannerViewModel>();
    final DayPlan? selectedDay = mealPlannerVM.selectedDay;
    
    if (selectedDay == null || selectedDay.meals.isEmpty) {
      return const Row(
        children: [
          Expanded(
            child: Text(
              'No planned meals for selected day',
              style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      );
    }
    
    // Show up to 2 recipe cards
    final List<MealEntry> mealsToShow = selectedDay.meals.length > 2 
        ? selectedDay.meals.take(2).toList() 
        : selectedDay.meals;
    
    List<Widget> recipeCards = [];
    for (int i = 0; i < mealsToShow.length && i < 2; i++) { // Limit to 2 cards
      if (i > 0) {
        recipeCards.add(const SizedBox(width: 12));
      }
      recipeCards.add(
        Expanded(
          child: _RecipeCard(
            title: mealsToShow[i].title,
            imagePath: mealsToShow[i].imageAssetPath,
            mealEntry: mealsToShow[i],
          ),
        ),
      );
    }
    
    // If we have less than 2 meals, add empty expanded widgets to fill space
    if (mealsToShow.length < 2) {
      for (int i = mealsToShow.length; i < 2; i++) {
        if (i > 0) {
          recipeCards.add(const SizedBox(width: 12));
        }
        recipeCards.add(const Expanded(child: SizedBox()));
      }
    }
    
    return Row(children: recipeCards);
  }

  Widget _buildSortRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('Sort by: ', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: const [
              Text('Filter', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
              SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down, color: Colors.black87),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroceryItemsFromPlannedMeals(BuildContext context) {
    final mealPlannerVM = context.watch<MealPlannerViewModel>();
    final DayPlan? selectedDay = mealPlannerVM.selectedDay;
    
    if (selectedDay == null || selectedDay.meals.isEmpty) {
      return const Center(
        child: Text(
          'No planned meals for selected day.\nAdd meals to see grocery list.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
        ),
      );
    }
    
    // Collect all ingredients from all planned meals
    final Map<String, _GroceryItemWithQuantity> groceryItems = {};
    
    return FutureBuilder<List<_GroceryItemWithQuantity>>(
      future: _fetchGroceryItems(selectedDay.meals),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading grocery items: ${snapshot.error}'),
          );
        }
        
        final List<_GroceryItemWithQuantity> items = snapshot.data ?? [];
        
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'No ingredients found for planned meals.',
              style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
            ),
          );
        }
        
        // Group items by category (this is a simplified version)
        // In a real app, you would have proper categorization
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(icon: Icons.shopping_cart_outlined, text: 'Grocery List'),
            const SizedBox(height: 8),
            ..._buildGroceryTiles(items),
          ],
        );
      },
    );
  }

  Future<List<_GroceryItemWithQuantity>> _fetchGroceryItems(List<MealEntry> meals) async {
    final List<_GroceryItemWithQuantity> items = [];
    final Map<String, double> ingredientQuantities = {}; // ingredient name -> total quantity
    final Map<String, String> ingredientUnits = {}; // ingredient name -> unit
    
    for (final meal in meals) {
      // First, try to get ingredients from the meal entry if they were saved
      List<String>? ingredients = meal.ingredients;
      
      // If not available in the meal entry, we would fetch from Firestore
      // But since we've fixed the saving, we should have them in the meal entry
      if (ingredients == null || ingredients.isEmpty) {
        // Fallback to fetching from Firestore if needed (shouldn't be necessary now)
        final service = FirestoreRecipesService();
        final recipeData = await service.fetchRecipeById(meal.id);
        
        if (recipeData != null && recipeData['ingredients'] is List) {
          ingredients = List<String>.from(recipeData['ingredients']);
        }
      }
      
      if (ingredients != null && ingredients.isNotEmpty) {
        final int persons = meal.people ?? 1; // Default to 1 person
        
        for (final ingredient in ingredients) {
          // Parse ingredient string (simplified parsing)
          // In a real app, you would have structured ingredient data
          final String ingredientName = _parseIngredientName(ingredient);
          final double baseQuantity = _parseIngredientQuantity(ingredient);
          final String unit = _parseIngredientUnit(ingredient);
          
          // Scale quantity based on number of persons
          final double scaledQuantity = baseQuantity * persons;
          
          // Add to totals
          if (ingredientQuantities.containsKey(ingredientName)) {
            ingredientQuantities[ingredientName] = ingredientQuantities[ingredientName]! + scaledQuantity;
          } else {
            ingredientQuantities[ingredientName] = scaledQuantity;
            ingredientUnits[ingredientName] = unit;
          }
        }
      }
    }
    
    // Convert to grocery items
    ingredientQuantities.forEach((name, quantity) {
      final String unit = ingredientUnits[name] ?? 'g';
      final String formattedQuantity = _formatQuantity(quantity, unit);
      items.add(_GroceryItemWithQuantity(name, formattedQuantity, 'assets/images/easymakesnack1.jpg'));
    });
    
    return items;
  }
  
  String _parseIngredientName(String ingredient) {
    // Simplified parsing - in a real app, you would have structured data
    // This is just a basic example
    final RegExp nameRegex = RegExp(r'^[^0-9]*');
    final Match? match = nameRegex.firstMatch(ingredient);
    return match?.group(0)?.trim() ?? ingredient;
  }
  
  double _parseIngredientQuantity(String ingredient) {
    // Simplified parsing - extract quantity from ingredient string
    final RegExp quantityRegex = RegExp(r'([0-9]+(?:\.[0-9]+)?)');
    final Match? match = quantityRegex.firstMatch(ingredient);
    return double.tryParse(match?.group(1) ?? '1') ?? 1.0;
  }
  
  String _parseIngredientUnit(String ingredient) {
    // Simplified parsing - extract unit from ingredient string
    final RegExp unitRegex = RegExp(r'[0-9]+(?:\.[0-9]+)?\s*([a-zA-Z]+)');
    final Match? match = unitRegex.firstMatch(ingredient);
    return match?.group(1)?.toLowerCase() ?? 'g';
  }
  
  String _formatQuantity(double quantity, String unit) {
    // Format quantity nicely
    if (quantity == quantity.toInt()) {
      return '${quantity.toInt()} $unit';
    } else {
      return '${quantity.toStringAsFixed(1)} $unit';
    }
  }

  List<Widget> _buildGroceryTiles(List<_GroceryItemWithQuantity> items) {
    return items
        .map(
          (it) => Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    it.imagePath,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, color: Colors.black26),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(it.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black87)),
                ),
                Text(it.quantity, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_checked.contains(it.name)) {
                        _checked.remove(it.name);
                      } else {
                        _checked.add(it.name);
                      }
                    });
                  },
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _checked.contains(it.name) ? Colors.deepOrange : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _checked.contains(it.name) ? Colors.deepOrange : const Color(0xFFD1D5DB)),
                    ),
                    child: _checked.contains(it.name)
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}

class _RecipeCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final MealEntry mealEntry;
  const _RecipeCard({required this.title, required this.imagePath, required this.mealEntry});

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 196;
    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Image takes top 65%
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: cardHeight * 0.65,
            child: imagePath.startsWith('http')
                ? Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const ColoredBox(color: Color(0xFFE5E7EB)),
                  )
                : Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const ColoredBox(color: Color(0xFFE5E7EB)),
                  ),
          ),
          // Close chip on image
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 16, color: Colors.black87),
            ),
          ),
          // Bottom white section (35%) with title above and View Recipe below
          Positioned(
            left: 0,
            right: 0,
            bottom: -10,
            height: cardHeight * 0.43,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (mealEntry.people != null)
                    Text(
                      '${mealEntry.people} ${mealEntry.people == 1 ? 'person' : 'persons'}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.deepOrange, padding: EdgeInsets.zero),
                    onPressed: () {},
                    icon: const Text('View Recipe', style: TextStyle(fontWeight: FontWeight.w700)),
                    label: const Icon(CupertinoIcons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon; // ignored (kept for call sites)
  final String text;
  const _SectionTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
    );
  }
}

class _GroceryItemWithQuantity {
  final String name;
  final String quantity;
  final String imagePath;
  const _GroceryItemWithQuantity(this.name, this.quantity, this.imagePath);
}