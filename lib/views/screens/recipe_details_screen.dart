import 'package:flutter/material.dart';
import 'package:recipe_app/core/constants/app_colors.dart';
import 'package:recipe_app/models/user/meal_plan.dart';

class RecipeDetailsScreen extends StatelessWidget {
  final String title;
  final String imageAssetPath;
  final int? minutes;
  final List<String>? ingredients;
  final List<String>? steps;
  final bool fromAdminScreen;
  final String? mealType; // Change from MealType? to String?
  final String recipeId; // Add recipe ID
  
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
  });
  
  @override
  Widget build(BuildContext context) {
    debugPrint('RecipeDetailsScreen building with title: $title, mealType: $mealType, fromAdminScreen: $fromAdminScreen');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Recipe Details', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        ),
        actions: fromAdminScreen
            ? [
                TextButton(
                  onPressed: () {
                    debugPrint('Add button pressed. Meal type: $mealType');
                    // Create a MealEntry from the recipe data
                    if (mealType != null) {
                      final mealEntry = MealEntry(
                        id: recipeId,
                        type: mealType!, // Pass the meal type as string
                        title: title,
                        minutes: minutes ?? 0,
                        imageAssetPath: imageAssetPath,
                      );
                      
                      debugPrint('Created MealEntry: ${mealEntry.title}, type: ${mealEntry.type}');
                      
                      // Pass the meal entry back to the meal planner screen
                      Navigator.of(context).pop(mealEntry);
                    } else {
                      debugPrint('Meal type is null, not creating MealEntry');
                    }
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.black87, size: 20),
                      SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroImage(title: title, imageAssetPath: imageAssetPath),
                    const SizedBox(height: 16),
                    _ActionRow(),
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
                              minutes == null ? 'Not available' : '$minutes min',
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
                        children: (ingredients == null || ingredients!.isEmpty)
                            ? const [
                                _IngredientTile(name: 'No ingredients available', note: ''),
                              ]
                            : ingredients!
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
                        children: (steps == null || steps!.isEmpty)
                            ? const [
                                _StepCard(step: 1, text: 'No steps available'),
                              ]
                            : List<Widget>.generate(
                                steps!.length,
                                (i) => _StepCard(step: i + 1, text: steps![i]),
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _ActionItem(icon: Icons.bookmark_border, label: 'Bookmark'),
          _ActionItem(icon: Icons.calendar_today_outlined, label: 'Meal Plan'),
          _ActionItem(icon: Icons.shopping_bag_outlined, label: 'Groceries'),
          _ActionItem(icon: Icons.ios_share_outlined, label: 'Share'),
          _ActionItem(icon: Icons.restaurant_menu_outlined, label: 'Nutrition'),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ActionItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.black87),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ],
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



