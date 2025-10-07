import 'package:flutter/material.dart';
import 'package:recipe_app/models/meal_plan.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';
import 'package:recipe_app/views/screens/add_recipe_by_user/my_recipes_screen.dart'; // Import MyRecipesScreen

class PlannedMealsScreen extends StatefulWidget {
  const PlannedMealsScreen({super.key});

  @override
  State<PlannedMealsScreen> createState() => _PlannedMealsScreenState();
}

class _PlannedMealsScreenState extends State<PlannedMealsScreen> {
  late Future<Map<String, List<PlannedMeal>>> _plannedMealsFuture;
  final FirestoreRecipesService _service = FirestoreRecipesService();

  @override
  void initState() {
    super.initState();
    _loadPlannedMeals();
  }

  void _loadPlannedMeals() {
    setState(() {
      _plannedMealsFuture = _fetchAllPlannedMealsGroupedByDate();
    });
  }

  Future<Map<String, List<PlannedMeal>>> _fetchAllPlannedMealsGroupedByDate() async {
    try {
      final List<PlannedMeal> allMeals = await _service.getAllPlannedMeals();
      
      // Group meals by date
      final Map<String, List<PlannedMeal>> groupedMeals = {};
      for (final meal in allMeals) {
        if (!groupedMeals.containsKey(meal.dateForRecipe)) {
          groupedMeals[meal.dateForRecipe] = [];
        }
        groupedMeals[meal.dateForRecipe]!.add(meal);
      }
      
      // Sort dates chronologically
      final List<String> sortedDates = groupedMeals.keys.toList()
        ..sort((a, b) {
          // Parse date strings to DateTime for comparison
          final DateTime dateA = _parseDateKey(a);
          final DateTime dateB = _parseDateKey(b);
          return dateA.compareTo(dateB);
        });
      
      // Create a new map with sorted dates
      final Map<String, List<PlannedMeal>> sortedGroupedMeals = {};
      for (final date in sortedDates) {
        sortedGroupedMeals[date] = groupedMeals[date]!;
      }
      
      return sortedGroupedMeals;
    } catch (e) {
      throw Exception('Error fetching planned meals: $e');
    }
  }

  // Helper method to parse date key back to DateTime
  DateTime _parseDateKey(String dateKey) {
    final RegExp regex = RegExp(r'^(\d+) ([A-Za-z]+)$');
    final Match? match = regex.firstMatch(dateKey);
    
    if (match == null) {
      return DateTime.now(); // fallback
    }
    
    final int day = int.parse(match.group(1)!);
    final String monthStr = match.group(2)!;
    
    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final int month = months.indexOf(monthStr) + 1;
    final int year = DateTime.now().year;
    
    // Handle year transition (if month is in the past, it's probably next year)
    final DateTime now = DateTime.now();
    if (month < now.month && (now.month - month) > 6) {
      return DateTime(year + 1, month, day);
    }
    
    return DateTime(year, month, day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Planned Meals', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, List<PlannedMeal>>>(
          future: _plannedMealsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading planned meals: ${snapshot.error}'),
              );
            }
            
            final Map<String, List<PlannedMeal>> groupedMeals = snapshot.data ?? {};
            
            if (groupedMeals.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No planned meals found',
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Create your own recipes and plan meals!',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MyRecipesScreen()), // Fixed: Removed const
                        );
                      },
                      child: const Text('View My Recipes'),
                    ),
                  ],
                ),
              );
            }
            
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...groupedMeals.entries.map((entry) {
                      final String dateKey = entry.key;
                      final List<PlannedMeal> meals = entry.value;
                      return _DateSection(dateKey: dateKey, meals: meals);
                    }).toList(),
                  ],
                ),
              ),
            );
          },
        ),
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
    return Container(
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
    );
  }
}