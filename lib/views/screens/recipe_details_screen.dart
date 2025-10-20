import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/core/constants/app_colors.dart';
import 'package:recipe_app/models/meal_plan.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';
import 'package:recipe_app/viewmodels/groceries_viewmodel.dart';
import 'package:recipe_app/viewmodels/user/meal_planner_view_model.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final String title;
  final String imageAssetPath;
  final int? minutes;
  final List<String>? ingredients;
  final List<String>? steps;
  final bool fromAdminScreen;
  final String? mealType;
  final String recipeId;
  final bool fromGroceriesScreen;
  final bool fromBookmarksScreen;

  const RecipeDetailsScreen({
    super.key,
    required this.title,
    required this.imageAssetPath,
    required this.recipeId,
    this.minutes,
    this.ingredients,
    this.steps,
    this.fromAdminScreen = false,
    this.mealType,
    this.fromGroceriesScreen = false,
    this.fromBookmarksScreen = false,
  });

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  String? _selectedTime;

  @override
  Widget build(BuildContext context) {
    final FirestoreRecipesService service = FirestoreRecipesService();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text('Recipe Details', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          // If recipeId looks like a recipes doc id, fetch from 'recipes';
          // otherwise attempt PlannedMeals fallback to extract embedded fields
          future: service.fetchRecipeById(widget.recipeId).then((recipesDoc) async {
            if (recipesDoc != null) return recipesDoc; // Case 1 (Home) / Case 3 (Grocery references using recipeId)

            // Case 2: Bookmarked sub-collection (doc id == recipeId)
            final Map<String, dynamic>? bookmarked = await service.fetchBookmarkedRecipeById(widget.recipeId);
            if (bookmarked != null) {
              return <String, dynamic>{
                'title': bookmarked['title'],
                'imageUrl': bookmarked['imageUrl'],
                'minutes': bookmarked['minutes'],
                // Bookmarks typically do not store ingredients/steps; fall back to empty
                'ingredients': <String>[],
                'steps': <String>[],
              };
            }

            // Case 4: PlannedMeals sub-collection (doc id == mealId)
            final Map<String, dynamic>? planned = await service.fetchPlannedMealById(widget.recipeId);
            if (planned != null) {
              return <String, dynamic>{
                'title': planned['recipeTitle'],
                'imageUrl': planned['recipeImage'],
                'minutes': planned['minutes'],
                'ingredients': planned['ingredients'],
                'steps': planned['instructions'],
              };
            }
            return null;
          }),
          builder: (context, snap) {
            final Map<String, dynamic>? data = snap.data;
            final String title = widget.title.isNotEmpty
                ? widget.title
                : (data != null ? (data['title']?.toString() ?? '') : '');
            final String imageUrl = widget.imageAssetPath.isNotEmpty
                ? widget.imageAssetPath
                : (data != null ? (data['imageUrl']?.toString() ?? '') : '');
            final int minutes = widget.minutes ?? ((data?['totalMinutes'] as num?)?.toInt() ?? (data?['minutes'] as num?)?.toInt() ?? 0);
            final List<String> ingredients = (widget.ingredients != null && widget.ingredients!.isNotEmpty)
                ? widget.ingredients!
                : _extractIngredientsStrings(data?['ingredients']);
            final List<String> steps = (widget.steps != null && widget.steps!.isNotEmpty)
                ? widget.steps!
                : _extractStepsStrings(data?['steps']) ?? _extractStepsStrings(data?['instructions']) ?? <String>[];

            if (snap.connectionState == ConnectionState.waiting) {
              // Show minimal header while loading details
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroImage(title: title.isEmpty ? widget.title : title, imageAssetPath: imageUrl.isEmpty ? (widget.imageAssetPath.isEmpty ? 'assets/images/dish/dish1.jpg' : widget.imageAssetPath) : imageUrl),
                        const SizedBox(height: 16),
                        _ActionRow(
                          onMealPlanTap: () => _showMealPlanDialog(context),
                          recipeId: widget.recipeId,
                          title: title.isEmpty ? widget.title : title,
                          imageUrl: imageUrl.isEmpty ? (widget.imageAssetPath.isEmpty ? 'assets/images/dish/dish1.jpg' : widget.imageAssetPath) : imageUrl,
                          minutes: minutes,
                          onGroceriesTap: () => _showGroceryDialog(context),
                          fromGroceriesScreen: widget.fromGroceriesScreen,
                          fromBookmarksScreen: widget.fromBookmarksScreen,
                        ),
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
                                Text(
                                  minutes > 0 ? '$minutes min' : 'Not available',
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
                            children: ingredients.isEmpty
                                ? const [
                                    _IngredientTile(name: 'No ingredients available', note: ''),
                                  ]
                                : ingredients.map((e) => _IngredientTile(name: e, note: '')).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _SectionTitle(text: 'Cooking Steps'),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: steps.isEmpty
                                ? const [
                                    _StepCard(step: 1, text: 'No steps available'),
                                  ]
                                : List<Widget>.generate(
                                    steps.length,
                                    (i) => _StepCard(step: i + 1, text: steps[i]),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<String> _extractIngredientsStrings(dynamic raw) {
    final List<String> out = <String>[];
    if (raw is List) {
      for (final dynamic e in raw) {
        if (e is String) {
          out.add(e);
        } else if (e is Map) {
          final String qty = (e['quantity'] ?? e['qty'] ?? '').toString();
          final String unit = (e['unit'] ?? e['u'] ?? '').toString();
          final String emoji = (e['emoji'] ?? e['icon'] ?? e['em'] ?? '').toString();
          final String name = (e['name'] ?? e['text'] ?? e['title'] ?? '').toString();
          final List<String> parts = <String>[];
          if (emoji.isNotEmpty) parts.add(emoji);
          if (qty.isNotEmpty) parts.add(qty);
          // Add unit if it exists and is not empty
          if (unit.isNotEmpty) parts.add(unit);
          if (name.isNotEmpty) parts.add(name);
          if (parts.isNotEmpty) out.add(parts.join(' '));
        } else if (e is Ingredient) {
          // Handle Ingredient objects by using their toString() method
          out.add(e.toString());
        }
      }
    }
    return out;
  }

  List<String>? _extractStepsStrings(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return null;
  }

  Future<void> _showMealPlanDialog(BuildContext context) async {
    // Admin flow: only pick time and return to caller
    // This flow is ONLY for when the meal planner screen directly opens the recipe admin screen
    // to select a recipe (indicated by allowMealPlanSelection being true)
    if (widget.fromAdminScreen && (widget.mealType != null && widget.mealType!.isNotEmpty)) {
      TimeOfDay selectedTime = TimeOfDay.now();
      String? selectedTimeText;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext ctx) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    const Text('Set Time', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Pick time'),
                      subtitle: Text(selectedTimeText ?? selectedTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedTime);
                        if (picked != null) {
                          setModalState(() {
                            selectedTime = picked;
                            selectedTimeText = picked.format(context);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'), style: TextButton.styleFrom(foregroundColor: Colors.black)),
                        ElevatedButton(
                          onPressed: () {
                            // Create a MealEntry with ingredients and instructions for proper saving
                            final MealEntry entry = MealEntry(
                              id: widget.recipeId,
                              type: widget.mealType!,
                              title: widget.title,
                              minutes: widget.minutes ?? 0,
                              imageAssetPath: widget.imageAssetPath.isEmpty ? 'assets/images/dish/dish1.jpg' : widget.imageAssetPath,
                              time: selectedTimeText ?? selectedTime.format(context),
                              ingredients: widget.ingredients,
                              instructions: widget.steps,
                            );
                            debugPrint('Creating MealEntry with ingredients: ${widget.ingredients}');
                            debugPrint('Creating MealEntry with steps: ${widget.steps}');
                            debugPrint('MealEntry ingredients: ${entry.ingredients}');
                            debugPrint('MealEntry instructions: ${entry.instructions}');
                            Navigator.of(context).pop();
                            Navigator.of(context).pop(entry);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary500, foregroundColor: Colors.white),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      );
      return;
    }

    // Extended flow: date + time + meal type, then save to Firestore
    // This flow is used for normal meal planning from any screen
    TimeOfDay selectedTime = TimeOfDay.now();
    String? selectedTimeText;
    DateTime selectedDate = DateTime.now();
    List<String> mealTypes = <String>[];
    String? selectedMealType;

    try {
      final service = FirestoreRecipesService();
      mealTypes = await service.fetchCollectionStrings('meal_types');
      if (mealTypes.isEmpty) mealTypes = ['Breakfast', 'Lunch', 'Dinner'];
      selectedMealType = mealTypes.first;
    } catch (_) {
      mealTypes = ['Breakfast', 'Lunch', 'Dinner'];
      selectedMealType = mealTypes.first;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  const Text('Meal Plan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ListTile(
                    title: const Text('Select Date'),
                    subtitle: Text(_formatDate(selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 6)),
                      );
                      if (picked != null) setModalState(() => selectedDate = picked);
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Set Time'),
                    subtitle: Text(selectedTimeText ?? selectedTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedTime);
                      if (picked != null) {
                        setModalState(() {
                          selectedTime = picked;
                          selectedTimeText = picked.format(context);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text('Select Meal Type'),
                    subtitle: Text(selectedMealType ?? 'None selected'),
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: mealTypes.map((m) {
                            final bool isSelected = m == selectedMealType;
                            return ChoiceChip(
                              label: Text(m),
                              selected: isSelected,
                              onSelected: (_) => setModalState(() => selectedMealType = isSelected ? null : m),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE5E7EB))),
                              backgroundColor: Colors.white,
                              selectedColor: AppColors.primary500,
                              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'), style: TextButton.styleFrom(foregroundColor: Colors.black)),
                      ElevatedButton(
                        onPressed: () async {
                          if (selectedMealType == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a meal type')));
                            return;
                          }
                          try {
                            final service = FirestoreRecipesService();
                            final String dateKey = service.formatDateKey(selectedDate);
                            
                            // Convert string ingredients to Ingredient objects with unit information
                            final List<Ingredient> ingredientObjects = <Ingredient>[];
                            
                            // Use widget.ingredients if available, otherwise fetch from Firestore
                            List<String>? ingredientsToUse = widget.ingredients;
                            if (ingredientsToUse == null || ingredientsToUse.isEmpty) {
                              // Try to fetch recipe data from different sources
                              // First try recipes collection
                              Map<String, dynamic>? recipeData = await service.fetchRecipeById(widget.recipeId);
                              if (recipeData != null) {
                                ingredientsToUse = _extractIngredientsStrings(recipeData['ingredients']);
                              } else {
                                // If not found in recipes collection, try PlannedMeals sub-collection
                                final Map<String, dynamic>? plannedMealData = await service.fetchPlannedMealById(widget.recipeId);
                                if (plannedMealData != null) {
                                  ingredientsToUse = _extractIngredientsStrings(plannedMealData['ingredients']);
                                }
                              }
                            }
                            
                            if (ingredientsToUse != null) {
                              for (final ingredientString in ingredientsToUse) {
                                // Parse the ingredient string to extract components
                                final Ingredient ingredient = _parseIngredientString(ingredientString);
                                ingredientObjects.add(ingredient);
                              }
                            }
                            
                            final plannedMeal = PlannedMeal(
                              uniqueId: '',
                              recipeTitle: widget.title,
                              dateForRecipe: dateKey,
                              timeForRecipe: selectedTimeText ?? selectedTime.format(context),
                              persons: 1,
                              ingredients: ingredientObjects,
                              instructions: widget.steps ?? <String>[],
                              recipeImage: widget.imageAssetPath,
                              mealType: selectedMealType!,
                              createdAt: DateTime.now(),
                              minutes: widget.minutes ?? 0,
                            );
                            await service.savePlannedMeal(plannedMeal);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meal planned successfully')));
                              final mealPlannerVM = Provider.of<MealPlannerViewModel>(context, listen: false);
                              await mealPlannerVM.refreshMeals();
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error saving meal plan')));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary500, foregroundColor: Colors.white),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const List<String> months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _showGroceryDialog(BuildContext context) async {
    int servings = 1;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  const Text('Add to Groceries', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  const Text('Servings'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setModalState(() { if (servings > 1) servings--; })),
                      Text('$servings', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                      IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setModalState(() { servings++; })),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'), style: TextButton.styleFrom(foregroundColor: Colors.black)),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final service = FirestoreRecipesService();
                            final List<Map<String, dynamic>> ingMaps = <Map<String, dynamic>>[];
                            
                            // Use widget.ingredients if available, otherwise fetch from Firestore
                            List<String>? ingredientsToUse = widget.ingredients;
                            if (ingredientsToUse == null || ingredientsToUse.isEmpty) {
                              // Try to fetch recipe data from different sources
                              // First try recipes collection
                              Map<String, dynamic>? recipeData = await service.fetchRecipeById(widget.recipeId);
                              if (recipeData != null) {
                                ingredientsToUse = _extractIngredientsStrings(recipeData['ingredients']);
                              } else {
                                // If not found in recipes collection, try PlannedMeals sub-collection
                                final Map<String, dynamic>? plannedMealData = await service.fetchPlannedMealById(widget.recipeId);
                                if (plannedMealData != null) {
                                  ingredientsToUse = _extractIngredientsStrings(plannedMealData['ingredients']);
                                }
                              }
                            }
                            
                            if (ingredientsToUse != null) {
                              for (final s in ingredientsToUse) {
                                final map = _parseIngredientToMap(s);
                                ingMaps.add({...map, 'isChecked': false});
                              }
                            }
                            
                            await service.saveGroceryRecipe(
                              title: widget.title,
                              imageUrl: widget.imageAssetPath,
                              minutes: widget.minutes ?? 0,
                              servings: servings,
                              ingredients: ingMaps,
                            );
                            final groceriesViewModel = Provider.of<GroceriesViewModel>(context, listen: false);
                            await groceriesViewModel.refreshRecipes();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Groceries')));
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error adding to Groceries')));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary500, foregroundColor: Colors.white),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

// parse to ingredient map for groceres
  Map<String, dynamic> _parseIngredientToMap(String s) {
    final String trimmed = s.trim();
    if (trimmed.isEmpty) return {'name': '', 'emoji': ''};
    
    // Split the string into parts
    final List<String> parts = trimmed.split(' ');
    if (parts.isEmpty) return {'name': '', 'emoji': ''};
    
    // Check if first part is an emoji
    final String firstPart = parts[0];
    final bool hasEmoji = firstPart.runes.length == 1 && firstPart.codeUnitAt(0) > 0x1F600;
    final int startIndex = hasEmoji ? 1 : 0;
    
    // If we have enough parts, try to parse quantity, unit, and name
    if (parts.length > startIndex + 1) {
      final String emoji = parts[startIndex];
      final String quantity = parts.length > startIndex + 2 ? parts[startIndex + 1] : '';
      final String name = parts.length > startIndex + 2 
          ? parts.sublist(startIndex + 2).join(' ') 
          : parts.sublist(startIndex + 1).join(' ');
      
      final Map<String, dynamic> result = {
        'name': name,
        'emoji': emoji,
        'isChecked': false,
      };
      
      // Add emoji and unit if they exist
      if (hasEmoji) {
        result['emoji'] = firstPart;
      }
      if (quantity.isNotEmpty) {
        result['quantity'] = quantity;
      }
      
      return result;
    } else {
      // Just name and possibly emoji
      final String name = hasEmoji ? parts.sublist(1).join(' ') : trimmed;
      
      final Map<String, dynamic> result = {
        'name': name,
        'quantity': '',
        'isChecked': false,
      };
      
      // Add emoji if it exists
      if (hasEmoji) {
        result['emoji'] = firstPart;
      }
      
      return result;
    }
  }
  
  /// Parse an ingredient string into an Ingredient object
  ///recipe to db from home screen
  Ingredient _parseIngredientString(String ingredientString) {
    final String trimmed = ingredientString.trim();
    if (trimmed.isEmpty) {
      return const Ingredient(name: '');
    }
    
    // Split the string into parts
    final List<String> parts = trimmed.split(' ');
    if (parts.length < 2) {
      return Ingredient(name: trimmed);
    }
    
    // Check if first part is an emoji
    final String firstPart = parts[0];
    final bool hasEmoji = firstPart.runes.length == 1 && firstPart.codeUnitAt(0) > 0x1F600;
    final int startIndex = hasEmoji ? 1 : 0;
    
    // If we have enough parts, try to parse quantity, unit, and name
    if (parts.length > startIndex + 1) {
      final String quantity = parts[startIndex];
      final String unit = parts.length > startIndex + 2 ? parts[startIndex + 1] : '';
      final String name = parts.length > startIndex + 2 
          ? parts.sublist(startIndex + 2).join(' ') 
          : parts.sublist(startIndex + 1).join(' ');
      
      return Ingredient(
        name: name,
        emoji: quantity, // Changed from quantity to emoji
        quantity: unit.isNotEmpty ? unit : null, // Changed from unit to quantity
      );
    } else {
      // Just name and possibly emoji
      final String name = hasEmoji ? parts.sublist(1).join(' ') : trimmed;
      return Ingredient(
        name: name,
        emoji: hasEmoji ? firstPart : null, // Keep emoji field
      );
    }
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
                imageAssetPath.startsWith('http')
                    ? Image.network(
                        imageAssetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Image.asset('assets/images/dish/dish1.jpg', fit: BoxFit.cover),
                      )
                    : Image.asset(
                        imageAssetPath.isEmpty ? 'assets/images/dish/dish1.jpg' : imageAssetPath,
                        fit: BoxFit.cover,
                      ),
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

class _ActionRow extends StatelessWidget {
  final VoidCallback onMealPlanTap;
  final String recipeId;
  final String title;
  final String imageUrl;
  final int minutes;
  final VoidCallback? onGroceriesTap;
  final bool fromGroceriesScreen;
  final bool fromBookmarksScreen;
  const _ActionRow({
    required this.onMealPlanTap,
    required this.recipeId,
    required this.title,
    required this.imageUrl,
    required this.minutes,
    this.onGroceriesTap,
    this.fromGroceriesScreen = false,
    this.fromBookmarksScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BookmarkButton(recipeId: recipeId, title: title, imageUrl: imageUrl, minutes: minutes, fromBookmarksScreen: fromBookmarksScreen),
          _ActionItem(icon: Icons.calendar_today_outlined, label: 'Meal Plan', onTap: onMealPlanTap),
          fromGroceriesScreen
              ? const _DisabledActionItem(icon: Icons.shopping_bag_outlined, label: 'Groceries')
              : _ActionItem(icon: Icons.shopping_bag_outlined, label: 'Groceries', onTap: onGroceriesTap),
          const _ActionItem(icon: Icons.ios_share_outlined, label: 'Share'),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ActionItem({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.black87),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _DisabledActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DisabledActionItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
      ],
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  final String recipeId;
  final String title;
  final String imageUrl;
  final int minutes;
  final bool fromBookmarksScreen;
  const _BookmarkButton({required this.recipeId, required this.title, required this.imageUrl, required this.minutes, this.fromBookmarksScreen = false});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreRecipesService();
    return StreamBuilder<bool>(
      stream: service.isBookmarkedStream(recipeId),
      builder: (context, snapshot) {
        final bool isBookmarked = snapshot.data == true;
        return InkWell(
          onTap: () async {
            await service.toggleBookmark(recipeId: recipeId, title: title, imageUrl: imageUrl, minutes: minutes);
            if (fromBookmarksScreen && context.mounted) {
              final bool nowBookmarked = (await service.isBookmarkedStream(recipeId).first);
              if (!nowBookmarked && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            }
          },
          child: Column(
            children: [
              Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: isBookmarked ? Colors.black : Colors.black87),
              const SizedBox(height: 4),
              const Text(
                'Bookmark',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        );
      },
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