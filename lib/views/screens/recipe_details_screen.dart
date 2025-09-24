import 'package:flutter/material.dart';
import 'package:recipe_app/core/constants/app_colors.dart';

class RecipeDetailsScreen extends StatelessWidget {
  final String title;
  final String imageAssetPath;
  const RecipeDetailsScreen({super.key, required this.title, required this.imageAssetPath});

  @override
  Widget build(BuildContext context) {
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
                    const _SectionTitle(text: 'Ingredients'),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: const [
                          _IngredientTile(name: 'Coconut Milk', note: '400ml can'),
                          _IngredientTile(name: 'Mixed Vegetables (Carrot, Bell Pepper, Zucchini)', note: '2 cups, chopped'),
                          _IngredientTile(name: 'Chickpeas', note: '1 can (400g), drained'),
                          _IngredientTile(name: 'Curry Paste (Red or Green)', note: '2 tbsp'),
                          _IngredientTile(name: 'Basmati Rice', note: '1 cup'),
                          _IngredientTile(name: 'Onion', note: '1 medium, chopped'),
                          _IngredientTile(name: 'Garlic', note: '2 cloves, minced'),
                          _IngredientTile(name: 'Ginger', note: '1 inch, grated'),
                          _IngredientTile(name: 'Fresh Cilantro', note: '1/4 cup, chopped'),
                          _IngredientTile(name: 'Lime', note: '1/2, juiced'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _SectionTitle(text: 'Cooking Steps'),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: const [
                          _StepCard(step: 1, text: 'Rinse basmati rice thoroughly, then combine with 2 cups of water in a saucepan. Bring to a boil, then reduce heat to low, cover, and simmer for 15 minutes. Remove from heat and let stand, covered, for 10 minutes, then fluff with a fork.'),
                          _StepCard(step: 2, text: 'In a large pot or Dutch oven, heat a tablespoon of oil over medium heat. Add chopped onion and sauté until softened, about 5 minutes.'),
                          _StepCard(step: 3, text: 'Stir in minced garlic and grated ginger, cooking for another minute until fragrant.'),
                          _StepCard(step: 4, text: 'Add curry paste and cook for 2-3 minutes, stirring constantly, until aromatic.'),
                          _StepCard(step: 5, text: 'Pour in coconut milk and bring to a gentle simmer. Add chopped mixed vegetables and drained chickpeas. Cook for 10-15 minutes, or until vegetables are tender-crisp.'),
                          _StepCard(step: 6, text: 'Stir in fresh lime juice and season with salt and pepper to taste. Garnish with fresh cilantro.'),
                          _StepCard(step: 7, text: 'Serve the vibrant vegetarian curry hot over the fluffy basmati rice.'),
                        ],
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
                Image.asset(imageAssetPath, fit: BoxFit.cover),
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

//


