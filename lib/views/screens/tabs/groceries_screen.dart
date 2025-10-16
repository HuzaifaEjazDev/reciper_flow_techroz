import 'dart:async'; // Add this import for Timer
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/viewmodels/groceries_viewmodel.dart';
import 'package:recipe_app/views/screens/recipe_details_screen.dart';

class GroceriesScreen extends StatefulWidget {
  const GroceriesScreen({super.key});

  @override
  State<GroceriesScreen> createState() => _GroceriesScreenState();
}

class _GroceriesScreenState extends State<GroceriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer; // Add debounce timer for search
  
  @override
  void initState() {
    super.initState();
    // Add listener to handle search when text changes
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel(); // Cancel timer on dispose
    super.dispose();
  }
  
  void _onSearchChanged() {
    // Debounce search to avoid too many requests
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch();
    });
  }
  
  void _performSearch() {
    final viewModel = context.read<GroceriesViewModel>();
    viewModel.setSearchQuery(_searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Search groceries...',
                                hintStyle: TextStyle(color: Colors.black54, fontSize: 15),
                              ),
                              onChanged: (v) {
                                // Update search query as user types
                                context.read<GroceriesViewModel>().setSearchQueryTemp(v);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _performSearch,
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7F00),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Center(
                        child: Icon(Icons.search, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 70),
                children: [
                  _buildRecipesHeader(context),
                  const SizedBox(height: 10),
                  _buildAllRecipeCardsRow(context),
                  const SizedBox(height: 20),
                  _buildSortAndClearRow(context), // Add this line
                  const SizedBox(height: 10),
                  _buildAllGroceryItems(context),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
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
      ],
    );
  }

  Widget _buildSortAndClearRow(BuildContext context) {
    return Row(
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
        // Spacer to push sort button to the end
        const Spacer(),
        const Text('Sort by: ', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          onSelected: (value) {
            // Set the sort option in the view model
            context.read<GroceriesViewModel>().setSortBy(value);
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem<String>(
              value: 'newest',
              child: Text('Newest', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            PopupMenuItem<String>(
              value: 'oldest',
              child: Text('Oldest', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            PopupMenuItem<String>(
              value: 'a-z',
              child: Text('A-Z', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
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
                // Display the current sort option
                Consumer<GroceriesViewModel>(
                  builder: (context, viewModel, child) {
                    String sortText = 'Newest';
                    switch (viewModel.sortBy) {
                      case 'newest':
                        sortText = 'Newest';
                        break;
                      case 'oldest':
                        sortText = 'Oldest';
                        break;
                      case 'a-z':
                        sortText = 'A-Z';
                        break;
                    }
                    return Text(sortText, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700));
                  },
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

  // Removed unused _weekdayShort helper

  /// Scales ingredient quantity based on servings
  /// If quantity is a number, multiply it by servings
  /// If quantity contains fractions or mixed numbers, parse and scale accordingly
  static String _scaleIngredientQuantity(String quantity, int servings) {
    if (quantity.isEmpty || servings <= 1) return quantity;
    
    // Try to parse the quantity as a number
    final double? qty = _GroceriesScreenState._parseQuantity(quantity);
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
  static double? _parseQuantity(String quantity) {
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
          final double? fraction = _GroceriesScreenState._parseQuantity(parts[1]);
          if (fraction != null) {
            return whole + fraction;
          }
        }
      }
    }
    
    return null;
  }

  /// Parse ingredient name to extract emoji, unit, and actual name
  /// Format: "emoji name" or "name" -> returns map with 'emoji', 'actualName', 'firstNamePart'
  static Map<String, String> _parseIngredientName(String fullName) {
    final String trimmed = fullName.trim();
    if (trimmed.isEmpty) return {'emoji': '', 'actualName': '', 'firstNamePart': ''};
    
    // Split the string into parts
    final List<String> parts = trimmed.split(' ');
    if (parts.isEmpty) return {'emoji': '', 'actualName': '', 'firstNamePart': ''};
    
    // Check if first part is an emoji
    final String firstPart = parts[0];
    final bool hasEmoji = firstPart.runes.length == 1 && firstPart.codeUnitAt(0) > 0x1F600;
    
    String emoji = '';
    String nameWithUnit = '';
    
    if (hasEmoji && parts.length > 1) {
      // Has emoji and more parts - emoji is first part, rest is name with potential unit
      emoji = firstPart;
      nameWithUnit = parts.sublist(1).join(' ');
    } else if (hasEmoji) {
      // Only has emoji
      emoji = firstPart;
      nameWithUnit = '';
    } else {
      // No emoji, just name with potential unit
      nameWithUnit = trimmed;
    }
    
    // Split nameWithUnit to get both the first part and the rest
    String actualName = nameWithUnit;
    String firstNamePart = '';
    if (nameWithUnit.isNotEmpty) {
      final List<String> nameParts = nameWithUnit.split(' ');
      firstNamePart = nameParts[0]; // Text before the first space
      if (nameParts.length > 1) {
        // Show the remaining text after the first space
        actualName = nameParts.sublist(1).join(' ');
      } else {
        // No space found, so the whole thing is the name
        actualName = nameWithUnit;
      }
    }
    
    return {'emoji': emoji, 'actualName': actualName, 'firstNamePart': firstNamePart};
  }

  /// Build a row with emoji, name, quantity, and unit in the correct order
  /// Format: Qty: [quantity] [emoji] [unit] [firstNamePart]
  static Widget _buildIngredientRow(String fullName, String scaledQty, String unit, bool checked) {
    // Parse the full name to extract emoji, actual name, and first name part
    final Map<String, String> parsedName = _parseIngredientName(fullName);
    final String emoji = parsedName['emoji'] ?? '';
    final String actualName = parsedName['actualName'] ?? '';
    final String firstNamePart = parsedName['firstNamePart'] ?? ''; // Text before first space
    
    // Format the quantity display
    String quantityDisplay = '';
    if (scaledQty.isNotEmpty) {
      quantityDisplay = scaledQty;
    }
    
    return Row(
      children: [
            Text(
            '$actualName',
            style: TextStyle(
              color: Colors.black87,
              decoration: checked ? TextDecoration.lineThrough : TextDecoration.none,
              fontWeight: FontWeight.w500,
            ),
          ),
        
        Spacer(),
        // Show quantity first
        if (quantityDisplay.isNotEmpty)
          Text(
            'Qty: $unit',
            style: TextStyle(
              color: Colors.black87,
              decoration: checked ? TextDecoration.lineThrough : TextDecoration.none,
              fontWeight: FontWeight.w500,
            ),
          ),
        // Show emoji after quantity
        // if (emoji.isNotEmpty)
        //   Text(
        //     ' $emoji',
        //     style: TextStyle(
        //       color: Colors.black87,
        //       decoration: checked ? TextDecoration.lineThrough : TextDecoration.none,
        //     ),
        //   ),
        // Show unit after emoji
        // if (unit.isNotEmpty)
        //   Text(
        //     ' $unit',
        //     style: TextStyle(
        //       color: Colors.black87,
        //       decoration: checked ? TextDecoration.lineThrough : TextDecoration.none,
        //       fontWeight: FontWeight.w500,
        //     ),
        //   ),
        // Show the first name part (text before first space)
        if (firstNamePart.isNotEmpty)
          Text(
            ' $firstNamePart',
            style: TextStyle(
              color: Colors.black87,
              decoration: checked ? TextDecoration.lineThrough : TextDecoration.none,
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAllRecipeCardsRow(BuildContext context) {
    return Consumer<GroceriesViewModel>(
      builder: (context, viewModel, child) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: viewModel.fetchAllGroceryRecipes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show a simple loading indicator instead of skeleton
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return Row(children: [Expanded(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)))]);
            }
            final List<Map<String, dynamic>> recipes = snapshot.data ?? const [];
            if (recipes.isEmpty) {
              return const Row(
                children: [
                  Expanded(child: Text('No groceries yet', style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic))),
                ],
              );
            }
            return SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recipes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final r = recipes[i];
                  final String title = (r['title'] ?? '').toString();
                  final String image = (r['imageUrl'] ?? '').toString();
                  final int minutes = r['minutes'] is int ? r['minutes'] as int : 0;
                  final int servings = r['servings'] is int ? r['servings'] as int : 1;
                  return SizedBox(
                    width: 160,
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to recipe details screen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RecipeDetailsScreen(
                              title: title,
                              imageAssetPath: image,
                              minutes: minutes,
                              recipeId: r['id']?.toString() ?? '',
                              fromAdminScreen: false,
                              fromGroceriesScreen: true, // Set this to true when navigating from groceries screen
                              // Pass ingredients in "qty unit name" format if available to use as fallback
                              ingredients: ((r['ingredients'] as List<dynamic>?) ?? <dynamic>[])
                                  .map((item) {
                                    if (item is Map<String, dynamic>) {
                                      final String qty = (item['quantity'] ?? '').toString();
                                      final String unit = (item['unit'] ?? '').toString();
                                      final String name = (item['name'] ?? '').toString();
                                      final String emoji = (item['emoji'] ?? '').toString();
                                      final List<String> parts = <String>[];
                                      if (emoji.isNotEmpty) parts.add(emoji);
                                      if (qty.isNotEmpty) parts.add(qty);
                                      if (unit.isNotEmpty) parts.add(unit);
                                      if (name.isNotEmpty) parts.add(name);
                                      return parts.join(' ');
                                    }
                                    return item.toString();
                                  })
                                  .cast<String>()
                                  .toList(),
                              steps: const [],
                            ),
                          ),
                        );
                      },
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
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.person, size: 14, color: Colors.black54),
                                    const SizedBox(width: 6),
                                    Text('$servings', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    )
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAllGroceryItems(BuildContext context) {
    return Consumer<GroceriesViewModel>(
      builder: (context, viewModel, child) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: viewModel.fetchAllGroceryRecipes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final List<Map<String, dynamic>> recipes = snapshot.data ?? const [];
            if (recipes.isEmpty) {
              return const Center(
                child: Text('No groceries yet. Use the Groceries feature (separate from Meal Planner).', style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic)),
              );
            }
            return _GroceryItemsList(recipes: recipes);
          },
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                final viewModel = Provider.of<GroceriesViewModel>(context, listen: false);
                try {
                  await viewModel.clearAllCheckedIngredients();
                  // Force a rebuild of the widget tree
                  setState(() {});
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// StatefulWidget to manage grocery items with better performance
class _GroceryItemsList extends StatefulWidget {
  final List<Map<String, dynamic>> recipes;

  const _GroceryItemsList({Key? key, required this.recipes}) : super(key: key);

  @override
  State<_GroceryItemsList> createState() => _GroceryItemsListState();
}

class _GroceryItemsListState extends State<_GroceryItemsList> {
  @override
  Widget build(BuildContext context) {
    // Display all recipes without grouping by date
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: const Text(
            'All Groceries',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        // Recipes
        ...widget.recipes.map((r) {
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
            child: Consumer<GroceriesViewModel>(
              builder: (context, viewModel, child) {
                return ExpansionTile(
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  initiallyExpanded: viewModel.getExpansionState(recipeId),
                  onExpansionChanged: (isExpanded) {
                    viewModel.toggleExpansionState(recipeId, isExpanded);
                  },
                  children: [
                    ...List<Widget>.generate(ingredients.length, (i) {
                      final dynamic item = ingredients[i];
                      String fullName = ''; // Changed from separate name to fullName
                      String qty = '';
                      String unit = '';
                      
                      if (item is Map) {
                        final String name = (item['name'] ?? '').toString();
                        final String emoji = (item['emoji'] ?? '').toString();
                        qty = (item['quantity'] ?? '').toString();
                        unit = (item['unit'] ?? '').toString();
                        
                        // Construct full name with emoji
                        fullName = emoji.isNotEmpty ? '$emoji $name' : name;
                      }
                      
                      final String scaledQty = _GroceriesScreenState._scaleIngredientQuantity(qty, servings);
                      return _IngredientItem(
                        recipeId: recipeId,
                        ingredientIndex: i,
                        fullName: fullName, // Pass fullName instead of separate name
                        scaledQty: scaledQty,
                        unit: unit,
                      );
                    }),
                    const SizedBox(height: 4),
                  ],
                );
              },
            ),
          );
        }).toList(),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// StatefulWidget to manage individual ingredient items with efficient state updates
class _IngredientItem extends StatefulWidget {
  final String recipeId;
  final int ingredientIndex;
  final String fullName; // Changed from 'name' to 'fullName'
  final String scaledQty;
  final String unit;

  const _IngredientItem({
    Key? key,
    required this.recipeId,
    required this.ingredientIndex,
    required this.fullName, // Changed from 'name' to 'fullName'
    required this.scaledQty,
    required this.unit,
  }) : super(key: key);

  @override
  State<_IngredientItem> createState() => _IngredientItemState();
}

class _IngredientItemState extends State<_IngredientItem> {
  bool? _checked;

  @override
  Widget build(BuildContext context) {
    return Consumer<GroceriesViewModel>(
      builder: (context, viewModel, child) {
        // Initialize checked state from view model if not already set
        _checked ??= viewModel.getCheckboxState(widget.recipeId, widget.ingredientIndex) ?? false;
        
        return InkWell(
          onTap: () async {
            final newValue = !(_checked ?? false);
            setState(() {
              _checked = newValue;
            });
            // Update view model silently
            viewModel.updateCheckboxStateSilently(widget.recipeId, widget.ingredientIndex, newValue);
            // Update database in background
            await viewModel.toggleGroceryIngredientChecked(
              groceryId: widget.recipeId, 
              ingredientIndex: widget.ingredientIndex, 
              isChecked: newValue
            );
          },
          child: Container(
            color: _checked == true ? Colors.grey.shade100 : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Checkbox(
                  value: _checked,
                  onChanged: (v) async {
                    final newValue = v ?? false;
                    setState(() {
                      _checked = newValue;
                    });
                    // Update view model silently
                    viewModel.updateCheckboxStateSilently(widget.recipeId, widget.ingredientIndex, newValue);
                    // Update database in background
                    await viewModel.toggleGroceryIngredientChecked(
                      groceryId: widget.recipeId, 
                      ingredientIndex: widget.ingredientIndex, 
                      isChecked: newValue
                    );
                  },
                  activeColor: Colors.green,
                ),
                Expanded(
                  child: _GroceriesScreenState._buildIngredientRow(widget.fullName, widget.scaledQty, widget.unit, _checked ?? false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}