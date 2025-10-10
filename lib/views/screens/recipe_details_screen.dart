import 'package:flutter/material.dart';
import 'package:recipe_app/core/constants/app_colors.dart';
import 'package:recipe_app/models/meal_plan.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/viewmodels/groceries_viewmodel.dart';
import 'package:recipe_app/viewmodels/user/meal_planner_view_model.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final String title;
  final String imageAssetPath;
  final int? minutes;
  final List<String>? ingredients;
  final List<String>? steps;
  final bool fromAdminScreen;
  final String? mealType; // Change from MealType? to String?
  final String recipeId; // Add recipe ID
  final bool fromGroceriesScreen; // Add this new parameter
  final bool fromBookmarksScreen; // Add this new parameter
  
  const RecipeDetailsScreen({
    super.key, 
    required this.title, 
    required this.imageAssetPath, 
    this.minutes, 
    this.ingredients, 
    this.steps,
    this.fromAdminScreen = false,
    this.mealType, // Change from MealType? to String?
    required this.recipeId,
    this.fromGroceriesScreen = false, // Default to false
    this.fromBookmarksScreen = false, // Default to false
  });
  
  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  String? _selectedTime;

  @override
  Widget build(BuildContext context) {
    debugPrint('RecipeDetailsScreen building with title: ${widget.title}, mealType: ${widget.mealType}, fromAdminScreen: ${widget.fromAdminScreen}');
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
        actions: null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroImage(title: widget.title, imageAssetPath: widget.imageAssetPath),
                    const SizedBox(height: 16),
                    _ActionRow(
                      onMealPlanTap: () => _showMealPlanDialog(context),
                      fromAdminScreen: widget.fromAdminScreen,
                      recipeId: widget.recipeId,
                      title: widget.title,
                      imageUrl: widget.imageAssetPath,
                      minutes: widget.minutes ?? 0,
                      onGroceriesTap: () => _showGroceryDialog(context),
                      fromGroceriesScreen: widget.fromGroceriesScreen, // Pass the new parameter
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
                              widget.minutes == null ? 'Not available' : '${widget.minutes} min',
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
                        children: (widget.ingredients == null || widget.ingredients!.isEmpty)
                            ? const [
                                _IngredientTile(name: 'No ingredients available', note: ''),
                              ]
                            : widget.ingredients!
                                .map((e) => _IngredientTile(name: e, note: ''))
                                .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _SectionTitle(text: 'Cooking Steps'),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: (widget.steps == null || widget.steps!.isEmpty)
                            ? const [
                                _StepCard(step: 1, text: 'No steps available'),
                              ]
                            : List<Widget>.generate(
                                widget.steps!.length,
                                (i) => _StepCard(step: i + 1, text: widget.steps![i]),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMealPlanDialog(BuildContext context) async {
    // Only show the extended options if NOT from admin screen
    if (!widget.fromAdminScreen) {
      // Show the new bottom sheet with date picker and meal types
      await _showExtendedMealPlanDialog(context);
      return;
    }
    
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

    // Show bottom sheet instead of dialog
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
                        onPressed: () {
                          // Update the parent state with selected values
                          if (mounted) {
                            setState(() {
                              _selectedTime = selectedTimeText ?? selectedTime.format(context);
                            });
                          }
                          
                          Navigator.of(context).pop();
                          
                          // Show confirmation
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Meal planned at ${selectedTimeText ?? selectedTime.format(context)}'),
                            ),
                          );

                          // If we came from Admin screen, save and return MealEntry (same as old AppBar button)
                          if (widget.fromAdminScreen && widget.mealType != null) {
                            final mealEntry = MealEntry(
                              id: widget.recipeId,
                              type: widget.mealType!,
                              title: widget.title,
                              minutes: widget.minutes ?? 0,
                              imageAssetPath: widget.imageAssetPath,
                              time: _selectedTime,
                              people: null,
                              ingredients: widget.ingredients,
                              instructions: widget.steps,
                            );
                            Navigator.of(context).pop(mealEntry);
                          }
                        },
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

  Future<void> _showExtendedMealPlanDialog(BuildContext context) async {
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
    List<DateTime> dateOptions = List.generate(7, (index) => DateTime.now().add(Duration(days: index)));
    
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
                          
                          try {
                            // Save the planned meal to Firestore
                            final service = FirestoreRecipesService();
                            final String dateKey = service.formatDateKey(selectedDate);
                            
                            final plannedMeal = PlannedMeal(
                              uniqueId: '', // Will be generated by Firestore
                              recipeTitle: widget.title,
                              dateForRecipe: dateKey,
                              timeForRecipe: selectedTimeText ?? selectedTime.format(context),
                              persons: 1, // Default to 1 person
                              ingredients: widget.ingredients ?? [],
                              instructions: widget.steps ?? [],
                              recipeImage: widget.imageAssetPath,
                              mealType: selectedMealType!,
                              createdAt: DateTime.now(),
                              minutes: widget.minutes ?? 0,
                            );
                            
                            await service.savePlannedMeal(plannedMeal);
                            
                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close bottom sheet
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Meal planned successfully')),
                              );
                              
                              // Notify the MealPlannerViewModel to refresh its data
                              final mealPlannerVM = Provider.of<MealPlannerViewModel>(context, listen: false);
                              await mealPlannerVM.refreshMeals();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Error saving meal plan')),
                              );
                            }
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

  Future<void> _showGroceryDialog(BuildContext context) async {
    int servings = 1;
    
    // Show bottom sheet instead of dialog
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
                        onPressed: () => setModalState(() { if (servings > 1) servings--; }),
                      ),
                      Text('$servings', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setModalState(() { servings++; }),
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
                          final service = FirestoreRecipesService();
                          final List<Map<String, dynamic>> ingMaps = <Map<String, dynamic>>[];
                          if (widget.ingredients != null) {
                            for (final s in widget.ingredients!) {
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
                          
                          // Refresh the groceries screen data
                          final groceriesViewModel = Provider.of<GroceriesViewModel>(context, listen: false);
                          await groceriesViewModel.refreshRecipes();
                          
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Close bottom sheet
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Groceries')));
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

  Map<String, dynamic> _parseIngredientToMap(String s) {
    final String trimmed = s.trim();
    if (trimmed.isEmpty) return {'name': '', 'quantity': ''};
    
    // Split only on first 2 spaces to handle format: "emoji quantity name"
    final List<String> parts = trimmed.split(' ');
    if (parts.length < 3) {
      // If we don't have enough parts, return as is
      return {'name': trimmed, 'quantity': ''};
    }
    
    // First part is emoji, second part is quantity, rest is name
    final String emoji = parts[0];
    final String quantity = parts[1];
    final String name = parts.sublist(2).join(' ');
    
    // Combine emoji and name for the name field, and use quantity for the quantity field
    return {'name': '$emoji $name', 'quantity': quantity};
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
                    ? Image.network(imageAssetPath, fit: BoxFit.cover)
                    : Image.asset(imageAssetPath, fit: BoxFit.cover),
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
  final bool fromAdminScreen;
  final String recipeId;
  final String title;
  final String imageUrl;
  final int minutes;
  final VoidCallback? onGroceriesTap;
  final bool fromGroceriesScreen; // Add this new parameter
  final bool fromBookmarksScreen; // Add this new parameter
  const _ActionRow({
    required this.onMealPlanTap, 
    this.fromAdminScreen = false, 
    required this.recipeId, 
    required this.title, 
    required this.imageUrl, 
    required this.minutes, 
    this.onGroceriesTap,
    this.fromGroceriesScreen = false, // Default to false
    this.fromBookmarksScreen = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BookmarkButton(recipeId: recipeId, title: title, imageUrl: imageUrl, minutes: minutes, fromBookmarksScreen: fromBookmarksScreen),
              // Keep Meal Plan button enabled even when navigated from groceries screen
              _ActionItem(
                icon: Icons.calendar_today_outlined,
                label: 'Meal Plan',
                onTap: onMealPlanTap,
              ),
              // Disable Groceries button when navigated from groceries screen
              fromGroceriesScreen
                ? _DisabledActionItem(icon: Icons.shopping_bag_outlined, label: 'Groceries')
                : _ActionItem(
                    icon: Icons.shopping_bag_outlined, 
                    label: 'Groceries', 
                    onTap: onGroceriesTap
                  ),
              const _ActionItem(icon: Icons.ios_share_outlined, label: 'Share'),
              const _ActionItem(icon: Icons.restaurant_menu_outlined, label: 'Nutrition'),
            ],
          ),
    );
  }

  // Removed unused _showGroceryDialogStatic to satisfy linter
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

// New widget for disabled action items
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
              // If we un-bookmarked while coming from bookmarks, close this details screen
              // Pop only if un-bookmarked now
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
        border: Border.all(color: Color.fromRGBO(247, 244, 244, 1)),
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
        border: Border.all(color: Color(0xFFE5E7EB)),
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