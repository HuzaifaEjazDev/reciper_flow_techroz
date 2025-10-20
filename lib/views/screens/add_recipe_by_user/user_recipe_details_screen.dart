import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/core/constants/app_colors.dart';
import 'package:recipe_app/viewmodels/user/user_recipe_details_view_model.dart';
import 'package:recipe_app/views/screens/add_recipe_by_user/create_new_recipe_screen.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';
import 'package:recipe_app/viewmodels/groceries_viewmodel.dart';
import 'package:recipe_app/viewmodels/user/meal_planner_view_model.dart';
import 'package:recipe_app/models/meal_plan.dart';
import 'package:share_plus/share_plus.dart';

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
  String? _selectedTime;
  
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _deleteRecipe(vm); // Delete the recipe
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
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

  Future<void> _showMealPlanDialog() async {
    final UserRecipeDetailsViewModel vm = Provider.of<UserRecipeDetailsViewModel>(context, listen: false);
    if (vm.recipe == null) return;
    
    TimeOfDay _parseTimeOfDay(String s) {
      final RegExp re = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false);
      final Match? m = re.firstMatch(s.trim());
      if (m == null) return TimeOfDay.now();
      int hour = int.tryParse(m.group(1) ?? '') ?? 0;
      final int minute = int.tryParse(m.group(2) ?? '') ?? 0;
      final String period = (m.group(3) ?? '').toUpperCase();
      hour = hour % 12;
      if (period == 'PM') hour += 12;
      return TimeOfDay(hour: hour, minute: minute);
    }

    final TimeOfDay initialTime = _selectedTime != null ? _parseTimeOfDay(_selectedTime!) : TimeOfDay.now();
    TimeOfDay selectedTime = initialTime;
    String? selectedTimeText = _selectedTime; // Pre-fill from previously selected time
    
    // Date selection - today to next 6 days
    DateTime selectedDate = DateTime.now();
    
    // Meal types - to be fetched from Firestore
    List<String> mealTypes = [];
    String? selectedMealType;
    
    // Fetch meal types from Firestore
    try {
      final service = FirestoreRecipesService();
      // Try to fetch meal types using the existing method
      mealTypes = await service.fetchCollectionStrings('meal_types');
      if (mealTypes.isEmpty) {
        // Fallback to default meal types
        mealTypes = ['Breakfast', 'Lunch', 'Dinner'];
      }
      if (mealTypes.isNotEmpty) {
        selectedMealType = mealTypes.first;
      }
    } catch (e) {
      // Fallback to default meal types if there's an error
      mealTypes = ['Breakfast', 'Lunch', 'Dinner'];
      if (mealTypes.isNotEmpty) {
        selectedMealType = mealTypes.first;
      }
    }

    // Show bottom sheet with date picker and meal types
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with drag handle
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Meal Plan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Date selection
                  ListTile(
                    title: const Text('Select Date'),
                    subtitle: Text(_formatDate(selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      // Show date picker for the next 7 days
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 6)),
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Time selection
                  ListTile(
                    title: const Text('Set Time'),
                    subtitle: Text(selectedTimeText ?? selectedTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedTime = picked;
                          selectedTimeText = picked.format(context);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Meal type selection in ExpansionTile with container chips
                  ExpansionTile(
                    title: const Text('Select Meal Type'),
                    subtitle: Text(selectedMealType ?? 'None selected'),
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: mealTypes.map((mealType) {
                            final bool isSelected = mealType == selectedMealType;
                            return ChoiceChip(
                              label: Text(mealType),
                              selected: isSelected,
                              onSelected: (_) {
                                setModalState(() {
                                  selectedMealType = isSelected ? null : mealType;
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              backgroundColor: Colors.white,
                              selectedColor: const Color(0xFFFF7F00),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
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
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // Validate that all required fields are selected
                          if (selectedMealType == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a meal type')),
                            );
                            return;
                          }
                          
                          // Pass the recipe data directly instead of trying to access through Provider
                          final recipe = vm.recipe!;
                          
                          try {
                            // Save the planned meal to Firestore
                            final service = FirestoreRecipesService();
                            final String dateKey = service.formatDateKey(selectedDate);
                            
                            // Convert ingredients to list of Ingredient objects
                            final List<Ingredient> ingredientList = recipe.ingredients
                                .map((e) => Ingredient(
                                  name: e['name'].toString(),
                                  emoji: e['quantity']?.toString(), // Changed from quantity to emoji
                                ))
                                .toList();
                            
                            final plannedMeal = PlannedMeal(
                              uniqueId: '', // Will be generated by Firestore
                              recipeTitle: recipe.title,
                              dateForRecipe: dateKey,
                              timeForRecipe: selectedTimeText ?? selectedTime.format(context),
                              persons: 1, // Default to 1 person
                              ingredients: ingredientList,
                              instructions: recipe.steps,
                              recipeImage: recipe.imageUrl,
                              mealType: selectedMealType!,
                              createdAt: DateTime.now(),
                              minutes: recipe.minutes,
                            );
                            
                            await service.savePlannedMeal(plannedMeal);
                            
                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close bottom sheet
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Meal planned successfully')),
                              );
                              
                              // Notify the MealPlannerViewModel to refresh its data
                              try {
                                final mealPlannerVM = Provider.of<MealPlannerViewModel>(context, listen: false);
                                await mealPlannerVM.refreshMeals();
                              } catch (e) {
                                // If we can't refresh the meal planner, it's not critical
                                debugPrint('Could not refresh meal planner: $e');
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Error saving meal plan')),
                              );
                            }
                            debugPrint('Error saving meal plan: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7F00), // Teal orange color
                          foregroundColor: Colors.white, // White text color
                        ),
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
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _showGroceryDialog() async {
    final UserRecipeDetailsViewModel vm = Provider.of<UserRecipeDetailsViewModel>(context, listen: false);
    if (vm.recipe == null) return;
    
    int servings = 1;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add to Groceries',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Servings'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setModalState(() {
                          if (servings > 1) servings--;
                        }),
                      ),
                      Text(
                        '$servings',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setModalState(() {
                          servings++;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final service = FirestoreRecipesService();
                            final List<Map<String, dynamic>> ingMaps = [];
                            
                            // Convert ingredients to the format expected by saveGroceryRecipe
                            for (final ingredient in vm.recipe!.ingredients) {
                              ingMaps.add({
                                'name': ingredient['name'],
                                'quantity': ingredient['quantity'],
                                'unit': ingredient['unit'] ?? '',
                                'isChecked': false,
                              });
                            }
                            
                            await service.saveGroceryRecipe(
                              title: vm.recipe!.title,
                              imageUrl: vm.recipe!.imageUrl,
                              minutes: vm.recipe!.minutes,
                              servings: servings,
                              ingredients: ingMaps,
                            );
                            
                            final groceriesViewModel = Provider.of<GroceriesViewModel>(context, listen: false);
                            await groceriesViewModel.refreshRecipes();
                            
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Added to Groceries')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Error adding to Groceries')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary500,
                          foregroundColor: Colors.white,
                        ),
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

  // Add share functionality
  Future<void> _shareRecipe(String title, int minutes, List<Map<String, dynamic>> ingredients, List<String> steps, String imageUrl) async {
    // Format the recipe data as text
    final StringBuffer buffer = StringBuffer();
    
    // Add title
    buffer.writeln('Recipe: $title');
    buffer.writeln('');
    
    // Add time
    if (minutes > 0) {
      buffer.writeln('Estimated Time: $minutes minutes');
      buffer.writeln('');
    }
    
    // Add ingredients section
    buffer.writeln('Ingredients:');
    buffer.writeln('-------------');
    if (ingredients.isEmpty) {
      buffer.writeln('No ingredients available');
    } else {
      for (int i = 0; i < ingredients.length; i++) {
        final ingredient = ingredients[i];
        final quantity = ingredient['quantity'] ?? '';
        final unit = ingredient['unit'] ?? '';
        final name = ingredient['name'] ?? '';
        buffer.writeln('${i + 1}. $quantity $unit $name'.trim());
      }
    }
    buffer.writeln('');
    
    // Add steps section
    buffer.writeln('Cooking Steps:');
    buffer.writeln('--------------');
    if (steps.isEmpty) {
      buffer.writeln('No steps available');
    } else {
      for (int i = 0; i < steps.length; i++) {
        buffer.writeln('${i + 1}. ${steps[i]}');
      }
    }
    
    // Share the text
    try {
      await Share.share(buffer.toString());
    } catch (e) {
      // Handle MissingPluginException or other errors
      debugPrint('Error sharing recipe: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to share recipe. Please try again.')),
        );
      }
    }
  }

  Map<String, dynamic> _parseIngredientToMap(String s) {
    final String trimmed = s.trim();
    if (trimmed.isEmpty) return {'name': '', 'quantity': ''};
    
    // Split the string into parts
    final List<String> parts = trimmed.split(' ');
    if (parts.isEmpty) return {'name': '', 'quantity': ''};
    
    // Check if first part is an emoji
    final String firstPart = parts[0];
    final bool hasEmoji = firstPart.runes.length == 1 && firstPart.codeUnitAt(0) > 0x1F600;
    final int startIndex = hasEmoji ? 1 : 0;
    
    // If we have enough parts, try to parse quantity and unit
    if (parts.length > startIndex + 1) {
      final String quantity = parts[startIndex];
      final String unit = parts.length > startIndex + 2 ? parts[startIndex + 1] : '';
      final String name = parts.length > startIndex + 2 
          ? parts.sublist(startIndex + 2).join(' ') 
          : parts.sublist(startIndex + 1).join(' ');
      
      final Map<String, dynamic> result = {
        'name': name,
        'quantity': quantity,
        'isChecked': false,
      };
      
      // Add emoji and unit if they exist
      if (hasEmoji) {
        result['emoji'] = firstPart;
      }
      if (unit.isNotEmpty) {
        result['unit'] = unit;
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
            surfaceTintColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            title: const Text('Your Recipe Details', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 20)),
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
                  _ActionRow(
                    recipeId: vm.recipeId,
                    title: recipe.title,
                    imageUrl: recipe.imageUrl,
                    minutes: recipe.minutes,
                    onMealPlanTap: _showMealPlanDialog,
                    onGroceriesTap: _showGroceryDialog,
                    onShareTap: () => _shareRecipe(
                      recipe.title,
                      recipe.minutes,
                      recipe.ingredients,
                      recipe.steps,
                      recipe.imageUrl,
                    ),
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
                              .map((entry) {
                                // Build the ingredient string with all components
                                final quantity = entry.value['quantity'] ?? '';
                                final unit = entry.value['unit'] ?? '';
                                final name = entry.value['name'] ?? '';
                                
                                // Combine components, avoiding extra spaces
                                final parts = [quantity, unit, name].where((s) => s.toString().isNotEmpty).toList();
                                final ingredientText = parts.join(' ');
                                
                                return _IngredientTile(
                                  name: ingredientText,
                                  note: '',
                                );
                              })
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
                // Check if the imageAssetPath is a URL (starts with http) or a local asset
                if (imageAssetPath.startsWith('http'))
                  // It's a URL from imgbb, use Image.network
                  Image.network(
                    imageAssetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to a default image if the network image fails to load
                      return Image.asset(
                        'assets/images/vegitables.jpg',
                        fit: BoxFit.cover,
                      );
                    },
                  )
                else if (imageAssetPath.startsWith('assets/'))
                  // It's a local asset, use Image.asset
                  Image.asset(
                    imageAssetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to a default image if the asset fails to load
                      return Image.asset(
                        'assets/images/vegitables.jpg',
                        fit: BoxFit.cover,
                      );
                    },
                  )
                else
                  // For any other case (including empty), use the default image
                  Image.asset(
                    'assets/images/vegitables.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to a default image if the asset fails to load
                      return Image.asset(
                        'assets/images/easymakesnack1.jpg',
                        fit: BoxFit.cover,
                      );
                    },
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
  final String recipeId;
  final String title;
  final String imageUrl;
  final int minutes;
  final VoidCallback onMealPlanTap;
  final VoidCallback onGroceriesTap;
  final VoidCallback onShareTap; // Add this line
  
  const _ActionRow({
    required this.recipeId,
    required this.title,
    required this.imageUrl,
    required this.minutes,
    required this.onMealPlanTap,
    required this.onGroceriesTap,
    required this.onShareTap, // Add this line
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BookmarkButton(recipeId: recipeId, title: title, imageUrl: imageUrl, minutes: minutes),
          _ActionItem(
            icon: Icons.calendar_today_outlined,
            label: 'Meal Plan',
            onTap: onMealPlanTap,
          ),
          _ActionItem(
            icon: Icons.shopping_bag_outlined,
            label: 'Groceries',
            onTap: onGroceriesTap,
          ),
          _ActionItem(icon: Icons.ios_share_outlined, label: 'Share', onTap: onShareTap), // Update this line
          // Removed Nutrition button
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

class _BookmarkButton extends StatelessWidget {
  final String recipeId;
  final String title;
  final String imageUrl;
  final int minutes;
  const _BookmarkButton({required this.recipeId, required this.title, required this.imageUrl, required this.minutes});

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
