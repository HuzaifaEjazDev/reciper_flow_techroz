import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
// removed unused imports after switching to service helpers
import 'package:recipe_app/viewmodels/user/meal_planner_view_model.dart';
import 'package:recipe_app/models/meal_plan.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';
import 'package:recipe_app/views/screens/recipe_details_screen.dart';
import 'package:recipe_app/views/screens/add_recipe_by_user/planned_meals_screen.dart';

// Helper class to hold parsed ingredient information
class ParsedIngredient {
  final String name;
  final double quantity;
  final String unit;
  
  ParsedIngredient(this.name, this.quantity, this.unit);
}

class GroceriesScreen extends StatefulWidget {
  const GroceriesScreen({super.key});

  @override
  State<GroceriesScreen> createState() => _GroceriesScreenState();
}

class _GroceriesScreenState extends State<GroceriesScreen> {
  bool _showAll = false; // Track if "Show All" is selected
  final Set<String> _hiddenRecipes = <String>{}; // Track recipes hidden from grocery list

  @override
  void initState() {
    super.initState();
    // Initialize the MealPlannerViewModel to ensure it's ready when needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<MealPlannerViewModel>();
      // Only initialize if not already initialized
      vm.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 70),
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),

            _buildRecipesHeader(context),
            const SizedBox(height: 10),
            _showAll 
              ? _buildAllRecipeCardsRow(context) 
              : _buildRecipeCardsRow(context),

            const SizedBox(height: 20),
            _buildSortRow(),

            const SizedBox(height: 10),
            _showAll 
              ? _buildAllGroceryItems(context) 
              : _buildGroceryItemsFromPlannedMeals(context),
            const SizedBox(height: 10),
          ],
        ),
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
          onPressed: () {
            // Navigate to the new planned meals screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PlannedMealsScreen(),
              ),
            );
          },
          style: TextButton.styleFrom(foregroundColor: Colors.black87),
          icon: const Text('All Groceries', style: TextStyle(fontWeight: FontWeight.w600)),
          label: const Icon(CupertinoIcons.chevron_right, color: Colors.black87),
        )
      ],
    );
  }

  Widget _buildRecipeCardsRow(BuildContext context) {
    final vm = context.watch<MealPlannerViewModel>();
    final DayPlan? selectedDay = vm.selectedDay;

    if (selectedDay == null) {
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

    final service = FirestoreRecipesService();
    final String dateKey = service.formatDateKey(selectedDay.date);

    return FutureBuilder<List<PlannedMeal>>(
      future: service.getPlannedMealsForDate(dateKey),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Row(
            children: [
              Expanded(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red))),
            ],
          );
        }
        final List<PlannedMeal> recipes = snapshot.data ?? const [];
        // Filter out hidden recipes
        final List<PlannedMeal> visibleRecipes = recipes.where((recipe) => !_hiddenRecipes.contains(recipe.uniqueId)).toList();
        
        if (visibleRecipes.isEmpty) {
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

        return SizedBox(
          height: 196, // card height
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: visibleRecipes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final meal = visibleRecipes[i];
              return SizedBox(
                width: 150,
               
                child: _RecipeCard(
                  title: meal.recipeTitle,
                  imagePath: meal.recipeImage,
                  mealEntry: MealEntry(
                    id: meal.uniqueId,
                    type: meal.mealType,
                    title: meal.recipeTitle,
                    minutes: meal.minutes, // Use minutes from PlannedMeal
                    imageAssetPath: meal.recipeImage,
                    people: meal.persons,
                    time: meal.timeForRecipe,
                    ingredients: meal.ingredients,
                    instructions: meal.instructions, // Add instructions
                  ),
                  onRemove: () => _hideRecipe(meal.uniqueId), // Add onRemove callback
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Method to hide a recipe from the grocery list display
  void _hideRecipe(String recipeId) {
    setState(() {
      _hiddenRecipes.add(recipeId);
    });
    
    // Also remove the recipe from Firestore
    _removeRecipeFromFirestore(recipeId);
  }
  
  // Method to remove a recipe from Firestore
  Future<void> _removeRecipeFromFirestore(String recipeId) async {
    try {
      final service = FirestoreRecipesService();
      await service.deletePlannedMeal(recipeId);
      debugPrint('Successfully removed recipe $recipeId from Firestore');
    } catch (e) {
      debugPrint('Error removing recipe $recipeId from Firestore: $e');
      // If there's an error, remove it from the hidden recipes set so it shows again
      setState(() {
        _hiddenRecipes.remove(recipeId);
      });
      // Show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error removing recipe. Please try again.')),
      );
    }
  }

  // Old subcollection-based fetch removed in favor of new schema methods

  Widget _buildSortRow() {
    final vm = context.read<MealPlannerViewModel>();
    final List<DateTime> nextSeven = List<DateTime>.generate(7, (i) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day).add(Duration(days: i));
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('Sort by: ', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        PopupMenuButton<Object>(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          onSelected: (value) {
            if (value is DateTime) {
              setState(() {
                _showAll = false; // Disable "Show All" mode
              });
              final matchIndex = vm.plans.indexWhere((p) => _isSameDate(p.date, value));
              if (matchIndex != -1) {
                vm.selectIndex(matchIndex);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(duration: Duration(seconds: 2), content: Text('No plan for selected date')),
                );
              }
            } else if (value is String && value == 'show_all') {
              setState(() {
                _showAll = true; // Enable "Show All" mode
              });
            }
          },
          itemBuilder: (ctx) => [
            // Show All option
            const PopupMenuItem<Object>(
              value: 'show_all',
              child: Text('Show All', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            // Divider
            const PopupMenuDivider(),
            // Date options
            ...nextSeven.map((day) {
              final weekday = _weekdayShort(day.weekday);
              final dateNum = day.day.toString();
              return PopupMenuItem<DateTime>(
                value: day,
                child: Row(
                  children: [
                    Text(weekday, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(dateNum, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            }),
          ],
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Text(
                  _showAll 
                    ? 'Show All' 
                    : vm.selectedDay != null
                      ? '${_weekdayShort(vm.selectedDay!.date.weekday)} ${vm.selectedDay!.date.day}'
                      : 'Dates', 
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _weekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
      default:
        return 'Sun';
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildGroceryItemsFromPlannedMeals(BuildContext context) {
    final vm = context.watch<MealPlannerViewModel>();
    final DayPlan? selectedDay = vm.selectedDay;
    
    if (selectedDay == null) {
      return const Center(
        child: Text(
          'No planned meals for selected day.\nAdd meals to see grocery list.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
        ),
      );
    }
    
    final service = FirestoreRecipesService();
    final String dateKey = service.formatDateKey(selectedDay.date);
    
    // Collect all ingredients from all planned meals for the selected date (new schema)
    return FutureBuilder<List<_GroceryItemWithQuantity>>(
      future: _fetchGroceryItemsForDate(dateKey),
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

  Future<List<_GroceryItemWithQuantity>> _fetchGroceryItemsForDate(String dateKey) async {
    final service = FirestoreRecipesService();
    final List<PlannedMeal> meals = await service.getPlannedMealsForDate(dateKey);
    final Map<String, double> ingredientQuantities = <String, double>{};
    
    for (final pm in meals) {
      // For default recipe ingredients for 1 person
      final int persons = 1;
      for (final ingredient in pm.ingredients) {
        // Parse ingredient to get name and quantity
        final ParsedIngredient parsed = _parseIngredient(ingredient);
        final String name = parsed.name;
        final double baseQty = parsed.quantity;
        final double scaled = baseQty * persons;
        
        // Accumulate quantities for the same ingredient
        ingredientQuantities[name] = (ingredientQuantities[name] ?? 0) + scaled;
      }
    }
    
    final List<_GroceryItemWithQuantity> items = <_GroceryItemWithQuantity>[];
    ingredientQuantities.forEach((name, qty) {
      items.add(_GroceryItemWithQuantity(
        name: name,
        quantity: _formatQuantity(qty, ''),
        imagePath: 'assets/images/easymakesnack1.jpg',
      ));
    });
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }
  
  ParsedIngredient _parseIngredient(String ingredient) {
    // Split by the first space to separate quantity from ingredient name
    // Examples: "2 tomatoes" -> quantity: "2", name: "tomatoes"
    //           "1 cup flour" -> quantity: "1", name: "cup flour"
    
    final String trimmed = ingredient.trim();
    if (trimmed.isEmpty) {
      return ParsedIngredient('Unknown', 1.0, '');
    }
    
    // Find the first space
    final int firstSpaceIndex = trimmed.indexOf(' ');
    
    // If no space, treat entire string as name with quantity 1
    if (firstSpaceIndex == -1) {
      return ParsedIngredient(trimmed, 1.0, '');
    }
    
    // Split into quantity part and name part
    final String quantityPart = trimmed.substring(0, firstSpaceIndex);
    final String namePart = trimmed.substring(firstSpaceIndex + 1);
    
    // Parse quantity
    final double quantity = double.tryParse(quantityPart) ?? 1.0;
    
    return ParsedIngredient(namePart, quantity, '');
  }
  
  String _formatQuantity(double quantity, String unit) {
    // Format quantity nicely
    String qtyStr;
    if (quantity == quantity.toInt()) {
      qtyStr = quantity.toInt().toString();
    } else {
      // Round to 1 decimal place
      qtyStr = quantity.toStringAsFixed(1);
      // Remove trailing zero if it's .0
      if (qtyStr.endsWith('.0')) {
        qtyStr = qtyStr.substring(0, qtyStr.length - 2);
      }
    }
    
    // Return just the quantity string since units are not being used in this implementation
    return qtyStr;
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
                Expanded(
                  child: Text(it.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
                Text(it.quantity, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _buildAllRecipeCardsRow(BuildContext context) {
    final service = FirestoreRecipesService();
    
    return FutureBuilder<List<PlannedMeal>>(
      future: service.getAllPlannedMeals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Row(
            children: [
              Expanded(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red))),
            ],
          );
        }
        final List<PlannedMeal> recipes = snapshot.data ?? const [];
        // Filter out hidden recipes
        final List<PlannedMeal> visibleRecipes = recipes.where((recipe) => !_hiddenRecipes.contains(recipe.uniqueId)).toList();
        
        if (visibleRecipes.isEmpty) {
          return const Row(
            children: [
              Expanded(
                child: Text(
                  'No planned meals',
                  style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          );
        }

        return SizedBox(
          height: 196, // card height
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: visibleRecipes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final meal = visibleRecipes[i];
              return SizedBox(
                width: 150,
                child: _RecipeCard(
                  title: meal.recipeTitle,
                  imagePath: meal.recipeImage,
                  mealEntry: MealEntry(
                    id: meal.uniqueId,
                    type: meal.mealType,
                    title: meal.recipeTitle,
                    minutes: meal.minutes, // Use minutes from PlannedMeal
                    imageAssetPath: meal.recipeImage,
                    people: meal.persons,
                    time: meal.timeForRecipe,
                    ingredients: meal.ingredients,
                    instructions: meal.instructions, // Add instructions
                  ),
                  onRemove: () => _hideRecipe(meal.uniqueId), // Add onRemove callback
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAllGroceryItems(BuildContext context) {
    final service = FirestoreRecipesService();
    
    // Collect all ingredients from all planned meals
    return FutureBuilder<List<_GroceryItemWithQuantity>>(
      future: _fetchAllGroceryItems(),
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
              'No ingredients found.',
              style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
            ),
          );
        }
        
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

  Future<List<_GroceryItemWithQuantity>> _fetchAllGroceryItems() async {
    final service = FirestoreRecipesService();
    final List<PlannedMeal> allMeals = await service.getAllPlannedMeals();
    final Map<String, double> ingredientQuantities = <String, double>{};
    
    for (final pm in allMeals) {
      // For default recipe ingredients for 1 person
      final int persons = 1;
      for (final ingredient in pm.ingredients) {
        // Parse ingredient to get name and quantity
        final ParsedIngredient parsed = _parseIngredient(ingredient);
        final String name = parsed.name;
        final double baseQty = parsed.quantity;
        final double scaled = baseQty * persons;
        
        // Accumulate quantities for the same ingredient
        ingredientQuantities[name] = (ingredientQuantities[name] ?? 0) + scaled;
      }
    }
    
    final List<_GroceryItemWithQuantity> items = <_GroceryItemWithQuantity>[];
    ingredientQuantities.forEach((name, qty) {
      items.add(_GroceryItemWithQuantity(
        name: name,
        quantity: _formatQuantity(qty, ''),
        imagePath: 'assets/images/easymakesnack1.jpg',
      ));
    });
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }
}

class _GroceryItemWithQuantity {
  final String name;
  final String quantity;
  final String imagePath;
  
  const _GroceryItemWithQuantity({
    required this.name,
    required this.quantity,
    required this.imagePath,
  });
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

class _RecipeCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final MealEntry mealEntry;
  final VoidCallback? onRemove; // Add onRemove callback
  
  const _RecipeCard({
    required this.title, 
    required this.imagePath, 
    required this.mealEntry,
    this.onRemove, // Add onRemove parameter
  });

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 240;
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
            child: GestureDetector(
              onTap: onRemove, // Add onTap handler
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 16, color: Colors.black87),
              ),
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
                    onPressed: () {
                      // Navigate to recipe details screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailsScreen(
                            title: mealEntry.title,
                            imageAssetPath: mealEntry.imageAssetPath,
                            minutes: mealEntry.minutes,
                            ingredients: mealEntry.ingredients,
                            steps: mealEntry.instructions, // Using instructions as steps
                            fromAdminScreen: false,
                            recipeId: mealEntry.id,
                          ),
                        ),
                      );
                    },
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