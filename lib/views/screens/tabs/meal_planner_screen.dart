import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/models/meal_plan.dart';
import 'package:recipe_app/viewmodels/user/meal_planner_view_model.dart';
import 'package:recipe_app/views/screens/recipe_by_admin_screen.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';
import 'package:recipe_app/views/screens/recipe_details_screen.dart';
// test imports removed

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize the view model only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized) {
        context.read<MealPlannerViewModel>().init();
        _initialized = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealPlannerViewModel>();
    final List<DayPlan> plans = vm.plans;
    
    // Debug print to see how many plans we have
    debugPrint('Building MealPlannerScreen with ${plans.length} plans');

    return Container(
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 75,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: List<Widget>.generate(plans.length, (index) {
                  final day = plans[index].date;
                  final bool isSelected = index == vm.selectedIndex;
                  final String weekday = _weekdayShort(day.weekday);
                  final String dateNum = day.day.toString();
                  
                  // Debug print to see what we're building
                  debugPrint('Building date item $index: $weekday $dateNum');
                  
                  return SizedBox(
                    width: 65,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => vm.selectIndex(index),
                        child: Container(
                          height: 75,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.deepOrange : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(color: Colors.deepOrange.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                weekday,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateNum,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: vm.loading
                  ? const Center(child: CircularProgressIndicator())
                  : vm.mealTypes.isEmpty
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(height: 50),
                            Icon(Icons.error_outline, size: 48, color: Colors.red),
                            SizedBox(height: 16),
                            Text(
                              'Error in loading,Please try again',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'If still same issue then contact to Support',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // test button removed
                              
                              // Dynamically generate sections for all meal types
                              ...vm.mealTypes.map((mealType) {
                                // Get all meal entries for this meal type on the selected day
                                final List<MealEntry> entries = vm.selectedDay?.mealsOfType(mealType) ?? const <MealEntry>[];

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.local_cafe_outlined, color: Colors.deepOrange),
                                        const SizedBox(width: 8),
                                        Text(
                                          mealType,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (entries.isNotEmpty)
                                      Column(
                                        children: entries.map((mealEntry) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: _MealCard(
                                            title: mealEntry.title,
                                            timeText: _getDefaultTime(mealType),
                                            imageAssetPath: mealEntry.imageAssetPath,
                                            icon: Icons.restaurant,
                                            people: mealEntry.people,
                                            time: mealEntry.time,
                                            recipeId: mealEntry.id, // Use id instead of recipeId
                                            onRemove: () {
                                              context.read<MealPlannerViewModel>().removeMealFromDay(vm.selectedIndex, mealEntry);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Removed ${mealEntry.title} from $mealType')),
                                              );
                                            },
                                          ),
                                        )).toList(),
                                      )
                                    else
                                      const SizedBox(height: 16),
                                    _AddMealButton(
                                      text: 'Add $mealType', 
                                      navigateToAdmin: true, 
                                      filterMealType: mealType,
                                      selectedDayIndex: vm.selectedIndex, // Pass the selected day index
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                );
                              }).toList(),
                              // Show a message when there are no meal types
                              if (vm.mealTypes.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      'No meal types available. Please check your database configuration.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDefaultTime(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '8:00 AM';
      case 'lunch':
        return '1:00 PM';
      case 'dinner':
        return '7:00 PM';
      default:
        return '4:00 PM';
    }
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
        return 'Sun';
      default:
        return '';
    }
  }
}

class _MealCard extends StatelessWidget {
  final String title;
  final String timeText;
  final String imageAssetPath;
  final IconData icon;
  final int? people;
  final String? time;
  final String recipeId;
  final VoidCallback? onRemove;
  const _MealCard({
    required this.title,
    required this.timeText,
    required this.imageAssetPath,
    required this.icon,
    this.people,
    this.time,
    required this.recipeId,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: Container(
                  width: 110,
                  height: 100,
                  color: Colors.grey[200],
                  child: imageAssetPath.startsWith('http')
                      ? Image.network(
                          imageAssetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to default image if network image fails
                            return Image.asset(
                              'assets/images/easymakesnack1.jpg',
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          imageAssetPath.isEmpty ? 'assets/images/easymakesnack1.jpg' : imageAssetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to default image if asset image fails
                            return Image.asset(
                              'assets/images/easymakesnack1.jpg',
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Display time if available, otherwise use default
                    Text(
                      time ?? timeText,
                      style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    // Display people count if available
                    if (people != null)
                      Text(
                        'Persons: $people',
                        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                      ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Row(
                        children: [
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: Colors.deepOrange),
                            onPressed: () async {
                              // Navigate to recipe details screen
                              final service = FirestoreRecipesService();
                              final recipeData = await service.fetchRecipeById(recipeId);
                              
                              if (recipeData != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RecipeDetailsScreen(
                                      title: recipeData['title'] as String,
                                      imageAssetPath: recipeData['image'] as String? ?? recipeData['imageUrl'] as String? ?? imageAssetPath,
                                      minutes: recipeData['minutes'] as int? ?? recipeData['cookTime'] as int?,
                                      ingredients: List<String>.from(recipeData['ingredients'] as List? ?? []),
                                      steps: List<String>.from(recipeData['steps'] as List? ?? []),
                                      recipeId: recipeId,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to load recipe details')),
                                );
                              }
                            },
                            child: const Text('View Recipe'),
                          ),
                          const SizedBox(width: 8),
                          Image.asset(
                            'assets/images/soup.png',
                            width: 22,
                            height: 22,
                            color: Colors.deepOrange,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.ramen_dining, color: Colors.deepOrange, size: 22),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onRemove,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.black87),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddMealButton extends StatelessWidget {
  final String text;
  final bool navigateToAdmin;
  final String? filterMealType;
  final int selectedDayIndex; // Add selected day index
  const _AddMealButton({required this.text, this.navigateToAdmin = false, this.filterMealType, required this.selectedDayIndex});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.deepOrange,
          side: const BorderSide(color: Colors.deepOrange),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          if (navigateToAdmin) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RecipeByAdminScreen(filterMealType: filterMealType, autoApplyFilter: true, allowMealPlanSelection: true), // Set flags for admin-from-meal-planner flow
              ),
            ).then((result) {
              debugPrint('Received result from RecipeByAdminScreen: $result');
              // Handle the result when returning from the recipe admin screen
              if (result is MealEntry) {
                debugPrint('Adding MealEntry to day $selectedDayIndex: ${result.title}, type: ${result.type}');
                // Add the meal entry to the selected day
                final mealPlannerVM = context.read<MealPlannerViewModel>();
                mealPlannerVM.addMealToDay(selectedDayIndex, result);
                
                // Show a snackbar to confirm
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${result.title} to ${filterMealType ?? result.type.toString().split('.').last}')),
                );
              } else {
                debugPrint('Result is not a MealEntry: $result');
              }
            });
          }
        },
        icon: const Icon(Icons.add),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}