import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';
import 'package:recipe_app/models/meal_plan.dart';
import 'package:recipe_app/views/screens/recipe_details_screen.dart';

// Helper class to hold parsed ingredient information
// Removed ingredient parsing and meal planner coupling

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
    // No coupling with Meal Planner
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
        const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildRecipeCardsRow(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'Groceries are managed separately from Meal Planner.',
            style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
          ),
        ),
      ],
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(duration: Duration(seconds: 2), content: Text('No groceries filtering by date')),
              );
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
                  _showAll ? 'Show All' : 'Dates', 
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
    return const Center(
      child: Text(
        'No groceries yet. Use the Groceries feature (separate from Meal Planner).',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildAllRecipeCardsRow(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'Groceries are managed separately from Meal Planner.',
            style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  Widget _buildAllGroceryItems(BuildContext context) {
    return const Center(
      child: Text(
        'No groceries yet. Use the Groceries feature (separate from Meal Planner).',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
      ),
    );
  }

  // Removed fetchAllGroceryItems
}

// Removed grocery item aggregation model

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