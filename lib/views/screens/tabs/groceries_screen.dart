import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/viewmodels/groceries_viewmodel.dart';
import 'package:recipe_app/models/meal_plan.dart';
import 'package:recipe_app/views/screens/recipe_details_screen.dart';

class GroceriesScreen extends StatefulWidget {
  const GroceriesScreen({super.key});

  @override
  State<GroceriesScreen> createState() => _GroceriesScreenState();
}

class _GroceriesScreenState extends State<GroceriesScreen> {
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
            Consumer<GroceriesViewModel>(
              builder: (context, viewModel, child) {
                return viewModel.showAll 
                  ? _buildAllRecipeCardsRow(context) 
                  : _buildRecipeCardsRow(context);
              }
            ),

            const SizedBox(height: 20),
            _buildSortRow(),

            const SizedBox(height: 10),
            Consumer<GroceriesViewModel>(
              builder: (context, viewModel, child) {
                return viewModel.showAll 
                  ? _buildAllGroceryItems(context) 
                  : _buildGroceryItemsFromPlannedMeals(context);
              }
            ),
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
            final viewModel = Provider.of<GroceriesViewModel>(context, listen: false);
            viewModel.toggleShowAll(true);
          },
          style: TextButton.styleFrom(foregroundColor: Colors.black87),
          icon: const Text('All Groceries', style: TextStyle(fontWeight: FontWeight.w600)),
          label: const Icon(CupertinoIcons.chevron_right, color: Colors.black87),
        )
      ],
    );
  }

  Widget _buildRecipeCardsRow(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Provider.of<GroceriesViewModel>(context, listen: false).fetchRecipes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Row(children: [Expanded(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)))]);
        }
        final List<Map<String, dynamic>> recipes = snapshot.data ?? const [];
        if (recipes.isEmpty) {
          return const Row(
            children: [
              Expanded(child: Text('No groceries for selected date', style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic))),
            ],
          );
        }
        return SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recipes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final r = recipes[i];
              final String title = (r['title'] ?? '').toString();
              final String image = (r['imageUrl'] ?? '').toString();
              final int minutes = r['minutes'] is int ? r['minutes'] as int : 0;
              return SizedBox(
                width: 160,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 108,
                        child: image.startsWith('http')
                            ? Image.network(image, fit: BoxFit.cover)
                            : Image.asset(image.isEmpty ? 'assets/images/easymakesnack1.jpg' : image, fit: BoxFit.cover),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Row(children: [
                                const Icon(Icons.access_time, size: 14, color: Colors.black54),
                                const SizedBox(width: 6),
                                Text(minutes == 0 ? '—' : '$minutes min', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSortRow() {
    final List<DateTime> nextSeven = List<DateTime>.generate(7, (i) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day).add(Duration(days: i));
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Clear All button at start position
        TextButton(
          onPressed: () {
            _showClearAllDialog(context);
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        const Text('Sort by: ', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        PopupMenuButton<Object>(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          onSelected: (value) {
            final viewModel = Provider.of<GroceriesViewModel>(context, listen: false);
            if (value is DateTime) {
              viewModel.toggleShowAll(false); // Disable "Show All" mode
              viewModel.setSelectedDateKey(viewModel.service.formatDateKey(value));
            } else if (value is String && value == 'show_all') {
              viewModel.toggleShowAll(true); // Enable "Show All" mode
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
          child: Consumer<GroceriesViewModel>(
            builder: (context, viewModel, child) {
              return Container(
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
                      viewModel.showAll ? 'Show All' : viewModel.selectedDateKey, 
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
                  ],
                ),
              );
            },
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

  /// Scales ingredient quantity based on servings
  /// If quantity is a number, multiply it by servings
  /// If quantity contains fractions or mixed numbers, parse and scale accordingly
  String _scaleIngredientQuantity(String quantity, int servings) {
    if (quantity.isEmpty || servings <= 1) return quantity;
    
    // Try to parse the quantity as a number
    final double? qty = _parseQuantity(quantity);
    if (qty == null) return quantity;
    
    // Scale the quantity
    final double scaled = qty * servings;
    
    // Format the result nicely
    if (scaled == scaled.toInt()) {
      return scaled.toInt().toString();
    } else {
      // Round to 1 decimal place
      final String result = scaled.toStringAsFixed(1);
      // Remove trailing zero if it's .0
      if (result.endsWith('.0')) {
        return result.substring(0, result.length - 2);
      }
      return result;
    }
  }
  
  /// Parses quantity string to extract numeric value
  /// Handles simple numbers, fractions, and mixed numbers
  double? _parseQuantity(String quantity) {
    final String trimmed = quantity.trim();
    if (trimmed.isEmpty) return null;
    
    // Handle simple decimal or integer
    final double? simple = double.tryParse(trimmed);
    if (simple != null) return simple;
    
    // Handle fractions (e.g., "1/2")
    if (trimmed.contains('/')) {
      final List<String> parts = trimmed.split('/');
      if (parts.length == 2) {
        final double? numerator = double.tryParse(parts[0]);
        final double? denominator = double.tryParse(parts[1]);
        if (numerator != null && denominator != null && denominator != 0) {
          return numerator / denominator;
        }
      }
    }
    
    // Handle mixed numbers (e.g., "1 1/2")
    if (trimmed.contains(' ')) {
      final List<String> parts = trimmed.split(' ');
      if (parts.length == 2) {
        final double? whole = double.tryParse(parts[0]);
        if (whole != null) {
          final double? fraction = _parseQuantity(parts[1]);
          if (fraction != null) {
            return whole + fraction;
          }
        }
      }
    }
    
    return null;
  }

  Widget _buildGroceryItemsFromPlannedMeals(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Provider.of<GroceriesViewModel>(context, listen: false).fetchRecipes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final List<Map<String, dynamic>> recipes = snapshot.data ?? const [];
        if (recipes.isEmpty) {
          return const Center(
            child: Text('No groceries for selected date', style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic)),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: recipes.map((r) {
            final String recipeId = (r['id'] ?? '').toString();
            final String title = (r['title'] ?? '').toString();
            final List<dynamic> ingredients = (r['ingredients'] as List<dynamic>? ?? <dynamic>[]);
            final int servings = r['servings'] is int ? r['servings'] as int : 1;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: ExpansionTile(
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                children: [
                  ...List<Widget>.generate(ingredients.length, (i) {
                    final dynamic item = ingredients[i];
                    final String name = (item is Map && item['name'] != null) ? item['name'].toString() : '';
                    final String qty = (item is Map && item['quantity'] != null) ? item['quantity'].toString() : '';
                    final String scaledQty = _scaleIngredientQuantity(qty, servings);
                    // Use ViewModel to get checkbox state
                    final viewModel = Provider.of<GroceriesViewModel>(context, listen: false);
                    final bool checked = viewModel.getCheckboxState(recipeId, i) ?? false;
                    return InkWell(
                      onTap: () async {
                        final newValue = !checked;
                        // Update local state immediately for instant UI feedback
                        viewModel.updateCheckboxState(recipeId, i, newValue);
                        // Update database in background
                        await viewModel.toggleGroceryIngredientChecked(
                          groceryId: recipeId, 
                          ingredientIndex: i, 
                          isChecked: newValue
                        );
                      },
                      child: Container(
                        color: checked ? Colors.grey.shade100 : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Checkbox(
                              value: checked,
                              onChanged: (v) async {
                                final newValue = v ?? false;
                                // Update local state immediately for instant UI feedback
                                viewModel.updateCheckboxState(recipeId, i, newValue);
                                // Update database in background
                                await viewModel.toggleGroceryIngredientChecked(
                                  groceryId: recipeId, 
                                  ingredientIndex: i, 
                                  isChecked: newValue
                                );
                              },
                            ),
                            Expanded(
                              child: Text(
                                scaledQty.isEmpty ? name : '$scaledQty $name',
                                style: TextStyle(
                                  color: Colors.black87,
                                  decoration: checked ? TextDecoration.lineThrough : TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAllRecipeCardsRow(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Provider.of<GroceriesViewModel>(context, listen: false).fetchRecipes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Row(children: [Expanded(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)))]);
        }
        final List<Map<String, dynamic>> recipes = snapshot.data ?? const [];
        if (recipes.isEmpty) {
          return const Row(
            children: [
              Expanded(child: Text('No groceries yet', style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic))),
            ],
          );
        }
        return SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recipes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final r = recipes[i];
              final String title = (r['title'] ?? '').toString();
              final String image = (r['imageUrl'] ?? '').toString();
              final int minutes = r['minutes'] is int ? r['minutes'] as int : 0;
              return SizedBox(
                width: 160,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 108,
                        child: image.startsWith('http')
                            ? Image.network(image, fit: BoxFit.cover)
                            : Image.asset(image.isEmpty ? 'assets/images/easymakesnack1.jpg' : image, fit: BoxFit.cover),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Row(children: [
                                const Icon(Icons.access_time, size: 14, color: Colors.black54),
                                const SizedBox(width: 6),
                                Text(minutes == 0 ? '—' : '$minutes min', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAllGroceryItems(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Provider.of<GroceriesViewModel>(context, listen: false).fetchRecipes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final List<Map<String, dynamic>> recipes = snapshot.data ?? const [];
        if (recipes.isEmpty) {
          return const Center(
            child: Text('No groceries yet. Use the Groceries feature (separate from Meal Planner).', style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic)),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: recipes.map((r) {
            final String recipeId = (r['id'] ?? '').toString();
            final String title = (r['title'] ?? '').toString();
            final List<dynamic> ingredients = (r['ingredients'] as List<dynamic>? ?? <dynamic>[]);
            final int servings = r['servings'] is int ? r['servings'] as int : 1;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: ExpansionTile(
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                children: [
                  ...List<Widget>.generate(ingredients.length, (i) {
                    final dynamic item = ingredients[i];
                    final String name = (item is Map && item['name'] != null) ? item['name'].toString() : '';
                    final String qty = (item is Map && item['quantity'] != null) ? item['quantity'].toString() : '';
                    final String scaledQty = _scaleIngredientQuantity(qty, servings);
                    // Use ViewModel to get checkbox state
                    final viewModel = Provider.of<GroceriesViewModel>(context, listen: false);
                    final bool checked = viewModel.getCheckboxState(recipeId, i) ?? false;
                    return InkWell(
                      onTap: () async {
                        final newValue = !checked;
                        // Update local state immediately for instant UI feedback
                        viewModel.updateCheckboxState(recipeId, i, newValue);
                        // Update database in background
                        await viewModel.toggleGroceryIngredientChecked(
                          groceryId: recipeId, 
                          ingredientIndex: i, 
                          isChecked: newValue
                        );
                      },
                      child: Container(
                        color: checked ? Colors.grey.shade100 : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Checkbox(
                              value: checked,
                              onChanged: (v) async {
                                final newValue = v ?? false;
                                // Update local state immediately for instant UI feedback
                                viewModel.updateCheckboxState(recipeId, i, newValue);
                                // Update database in background
                                await viewModel.toggleGroceryIngredientChecked(
                                  groceryId: recipeId, 
                                  ingredientIndex: i, 
                                  isChecked: newValue
                                );
                              },
                            ),
                            Expanded(
                              child: Text(
                                scaledQty.isEmpty ? name : '$scaledQty $name',
                                style: TextStyle(
                                  color: Colors.black87,
                                  decoration: checked ? TextDecoration.lineThrough : TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Show confirmation dialog for Clear All
  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Ingredients'),
          content: const Text('Are you sure you want to clear all checked ingredients? This action cannot be undone.'),
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
                final viewModel = Provider.of<GroceriesViewModel>(context, listen: false);
                try {
                  await viewModel.clearAllCheckedIngredients();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All checked ingredients have been removed')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error removing ingredients')),
                    );
                  }
                }
              },
              child: const Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}