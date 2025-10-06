import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/views/screens/recipe_by_admin_screen.dart';
import 'package:recipe_app/views/screens/recipe_details_screen.dart';
import 'package:recipe_app/viewmodels/user/home_view_model.dart';
import 'package:recipe_app/models/dish.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Dish> dishes = context.watch<HomeViewModel>().recommended;
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
                        children: const [
                          Icon(Icons.search, color: Colors.black54, size: 20),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Search for Recipes...',
                              style: TextStyle(color: Colors.black54, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Text(
                'Recommended Dishes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              itemCount: dishes.length,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 25),
              itemBuilder: (context, index) {
                final dish = dishes[index];
                return _DishCard(dish: dish);
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
                children: const [
                  _SmallDishCard(imageAssetPath: 'assets/images/easymakesnack1.jpg', title: 'Crispy Bites', minutes: 8),
                  SizedBox(width: 12),
                  _SmallDishCard(imageAssetPath: 'assets/images/easymakesnack2.jpg', title: 'Fruit Delight', minutes: 6),
                  SizedBox(width: 12),
                  _SmallDishCard(imageAssetPath: 'assets/images/easymakesnack3.jpg', title: 'Cheesy Toast', minutes: 10),
                ],
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
                children: const [
                  _SmallDishCard(imageAssetPath: 'assets/images/quickweeknightmeals1.jpg', title: 'Pasta Bowl', minutes: 20),
                  SizedBox(width: 12),
                  _SmallDishCard(imageAssetPath: 'assets/images/quickweeknightmeals2.jpg', title: 'Veggie Stir-fry', minutes: 15),
                  SizedBox(width: 12),
                  _SmallDishCard(imageAssetPath: 'assets/images/quickweeknightmeals3.jpg', title: 'Grilled Wraps', minutes: 18),
                ],
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
  const _SmallDishCard({required this.imageAssetPath, required this.title, required this.minutes});

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 150;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeDetailsScreen(
              title: title,
              imageAssetPath: imageAssetPath,
              recipeId: title.toLowerCase().replaceAll(' ', '_'),
            ),
          ),
        );
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
                  const SizedBox(width: 16),
                  const Icon(Icons.star_border, size: 18, color: Colors.black87),
                  const SizedBox(width: 6),
                  Text('${dish.rating}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black45)),
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



