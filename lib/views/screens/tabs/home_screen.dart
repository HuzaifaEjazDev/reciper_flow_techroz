import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/views/screens/recipe_by_admin_screen.dart';
import 'package:recipe_app/views/screens/recipe_details_screen.dart';
import 'package:recipe_app/viewmodels/user/home_view_model.dart';
import 'package:recipe_app/models/dish.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final Random _random = Random();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Add listener to handle search when text changes
    _searchController.addListener(_onSearchChanged);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
    
    // Add observer to detect when app resumes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app resumes from background, refresh recommended recipes
    if (state == AppLifecycleState.resumed) {
      _refreshRecommendedRecipesOnly();
    }
  }

  void _initializeData() {
    if (!_initialized) {
      _initialized = true;
      _refreshData();
    }
  }

  void _refreshData() {
    final homeViewModel = context.read<HomeViewModel>();
    // Force a new random value every time this method is called
    final newRandomValue = _random.nextDouble() * 0.4; // 0-0.4 as per requirements
    print('Force generated new user random value: $newRandomValue');
    
    // Call refresh with the new random value
    homeViewModel.refreshRecommendedRecipes(forcedRandomValue: newRandomValue).then((_) {
      // Load other initial data (excluding recommended recipes which are already loaded)
      homeViewModel.refreshOtherData();
    });
  }

  void _refreshRecommendedRecipesOnly() {
    final homeViewModel = context.read<HomeViewModel>();
    // Generate a new random value for recommended recipes only
    final newRandomValue = _random.nextDouble() * 0.4; // 0-0.4 as per requirements
    print('Force generated new user random value for refresh: $newRandomValue');
    
    // Call refresh with the new random value
    homeViewModel.refreshRecommendedRecipes(forcedRandomValue: newRandomValue);
  }

  void _onSearchChanged() {
    // When search bar is empty, show all data automatically
    if (_searchController.text.trim().isEmpty) {
      _performSearch();
    }
  }

  void _performSearch() {
    final String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      // Navigate to RecipeByAdminScreen with the search query
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeByAdminScreen(initialSearchQuery: query),
        ),
      ).then((_) {
        // After returning from the search screen, we could optionally clear the search field
        // _searchController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeViewModel = context.watch<HomeViewModel>();
    final List<Dish> easyMakeSnacks = homeViewModel.easyMakeSnacks;
    final List<Dish> quickWeeknightMeals = homeViewModel.quickWeeknightMeals;
    
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
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
                          // Removed the search icon from inside the field
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Search for Recipes...',
                                hintStyle: TextStyle(color: Colors.black54, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Added search button next to the search bar
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
                      child: const Icon(Icons.search, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Text(
                'Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                scrollDirection: Axis.horizontal,
                children: [
                  _CategoryBox(
                    icon: Icons.free_breakfast_outlined,
                    label: 'Breakfast',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RecipeByAdminScreen(
                            filterMealType: 'Breakfast',
                            autoApplyFilter: true,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _CategoryBox(
                    icon: Icons.lunch_dining_outlined,
                    label: 'Lunch',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RecipeByAdminScreen(
                            filterMealType: 'Lunch',
                            autoApplyFilter: true,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _CategoryBox(
                    icon: Icons.home_outlined,
                    label: 'Dinner',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RecipeByAdminScreen(
                            filterMealType: 'Dinner',
                            autoApplyFilter: true,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _CategoryBox(
                    icon: Icons.star_border_outlined,
                    label: 'Desserts',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RecipeByAdminScreen(
                            filterMealType: 'Desserts',
                            autoApplyFilter: true,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Recommended Recipes Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Text(
                'Recommended Recipes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            Consumer<HomeViewModel>(
              builder: (context, homeViewModel, child) {
                final recommendedRecipes = homeViewModel.recommendedRecipes;
                // Show loading indicator while recommended recipes are being fetched
                if (recommendedRecipes.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  itemCount: recommendedRecipes.length,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  itemBuilder: (context, index) {
                    return _DishCard(dish: recommendedRecipes[index]);
                  },
                );
              },
            ),
            const SizedBox(height: 32),

            // Easy Make Snack Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Text(
                'Easy Make Snack',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 25),
                children: easyMakeSnacks.map((dish) => 
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _SmallDishCard(
                      imageAssetPath: dish.imageAssetPath, 
                      title: dish.title, 
                      minutes: dish.minutes,
                      dish: dish,
                    ),
                  )
                ).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // Quick Weeknight Meals Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Text(
                'Quick Weeknight Meals',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 25),
                children: quickWeeknightMeals.map((dish) => 
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _SmallDishCard(
                      imageAssetPath: dish.imageAssetPath, 
                      title: dish.title, 
                      minutes: dish.minutes,
                      dish: dish,
                    ),
                  )
                ).toList(),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _SmallDishCard extends StatelessWidget {
  final String imageAssetPath;
  final String title;
  final int minutes;
  final Dish? dish; // Add this parameter
  const _SmallDishCard({required this.imageAssetPath, required this.title, required this.minutes, this.dish});

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 150;
    return GestureDetector(
      onTap: () {
        if (dish != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecipeDetailsScreen(
                title: dish!.title,
                imageAssetPath: dish!.imageAssetPath,
                minutes: dish!.minutes,
                recipeId: dish!.id,
              ),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecipeDetailsScreen(
                title: title,
                imageAssetPath: imageAssetPath,
                recipeId: title.toLowerCase().replaceAll(' ', '_'),
              ),
            ),
          );
        }
      },
      child: Container(
      width: 180,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              imageAssetPath,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.12))),
          // Title just above the bottom info bar
          Positioned(
            left: 10,
            right: 10,
            bottom: (cardHeight * 0.20) + 8,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
              ),
            ),
          ),
          // Bottom white info bar with time only (20% height)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: cardHeight * 0.20,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.black87, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '$minutes min',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  final Dish dish;
  const _DishCard({required this.dish});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeDetailsScreen(
              title: dish.title,
              imageAssetPath: dish.imageAssetPath,
              minutes: dish.minutes,
              recipeId: dish.id,
            ),
          ),
        );
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: dish.imageAssetPath.startsWith('http')
                ? Image.network(dish.imageAssetPath, fit: BoxFit.cover)
                : Image.asset(dish.imageAssetPath, fit: BoxFit.cover),
          ),
          // Dim overlay to reduce image transparency slightly
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.15)),
          ),
          // Title and subtitle at bottom over the image
          Positioned(
            left: 12,
            right: 12,
            bottom: (200 * 0.20) + 8, // just above the bottom info bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dish.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dish.subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600, // a little bold
                    color: Colors.white,
                    height: 1.3,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 200 * 0.20,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: Colors.black87),
                  const SizedBox(width: 6),
                  Text('${dish.minutes} min', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black45)),
                  // Removed rating display
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _CategoryBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _CategoryBox({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 2),
            Icon(icon, color: Colors.deepOrange),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}