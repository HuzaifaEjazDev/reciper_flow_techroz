import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/core/constants/app_colors.dart';
import 'package:recipe_app/viewmodels/user/my_recipes_view_model.dart';
import 'package:recipe_app/views/screens/add_recipe_by_user/create_new_recipe_screen.dart';
import 'package:recipe_app/views/screens/add_recipe_by_user/user_recipe_details_screen.dart';

class MyRecipesScreen extends StatelessWidget {
  const MyRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MyRecipesViewModel>(
      create: (_) => MyRecipesViewModel()..loadFromFirestore(collection: 'RecipesCreatedByUser'),
      child: const _MyRecipesView(),
    );
  }
}

class _MyRecipesView extends StatelessWidget {
  const _MyRecipesView();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyRecipesViewModel>();
    final items = vm.items;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('User Created Recipes', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary500,
        onPressed: () {
          // Navigate to create new recipe screen
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateNewRecipeScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _SearchField()),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                        await context.read<MyRecipesViewModel>().loadSortOptions();
                        // ignore: use_build_context_synchronously
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Color(0xFFF5F7F9),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (_) => const _SortBottomSheet(),
                        );
                      },
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.sort, color: Colors.black87),
                            SizedBox(width: 6),
                            Text('Sort', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (vm.loading) const Center(child: CircularProgressIndicator()),
                if (vm.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(vm.error!, style: const TextStyle(color: Colors.red)),
                  ),
                if (!vm.loading && items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'No recipes found.\nCreate your first recipe!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.68,
                    ),
                    itemBuilder: (context, index) => _RecipeCard(data: items[index]),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final MyRecipeCardData data;
  const _RecipeCard({required this.data});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 185,
      height: 250,
      child: InkWell(
        onTap: () {
          // Navigate to UserRecipeDetailsScreen instead of CreateNewRecipeScreen for viewing
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserRecipeDetailsScreen(recipeId: data.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _RecipeImage(pathOrUrl: data.imageAssetPath),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xB3000000)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.flatware, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text('${data.ingredientsCount} ingredients', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 0, 8),
              child: Row(
                children: [
                  const Icon(Icons.local_dining_outlined, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text('${data.stepsCount} steps', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _RecipeImage extends StatelessWidget {
  final String pathOrUrl;
  const _RecipeImage({required this.pathOrUrl});
  @override
  Widget build(BuildContext context) {
    // Use the asset image since all user recipes use the same static image
    return Image.asset(
      'assets/images/vegitables.jpg',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to a default image if the asset fails to load
        return Image.asset(
          'assets/images/easymakesnack1.jpg',
          fit: BoxFit.cover,
        );
      },
    );
  }
}

class _SortBottomSheet extends StatelessWidget {
  const _SortBottomSheet();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyRecipesViewModel>();
    return Container(
      color: const Color(0xFFF5F7F9),
      child: Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 12),

          _ChipsExpansionTile(
            title: 'meal Types',
            options: vm.mealTypes,
            selected: vm.selectedMealType,
            onSelected: (v) => context.read<MyRecipesViewModel>().setSelectedMealType(v),
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFE5E7EB)),

          _ChipsExpansionTile(
            title: 'diets',
            options: vm.diets,
            selected: vm.selectedDiet,
            onSelected: (v) => context.read<MyRecipesViewModel>().setSelectedDiet(v),
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFE5E7EB)),

          _ChipsExpansionTile(
            title: 'cuisines',
            options: vm.cuisines,
            selected: vm.selectedCuisine,
            onSelected: (v) => context.read<MyRecipesViewModel>().setSelectedCuisine(v),
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFE5E7EB)),

          _ChipsExpansionTile(
            title: 'special Tags',
            options: vm.tags,
            selected: vm.selectedTag,
            onSelected: (v) => context.read<MyRecipesViewModel>().setSelectedTag(v),
          ),
          const SizedBox(height: 8),
        ],
      ),
      ),
    );
  }
}

class _ChipsExpansionTile extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _ChipsExpansionTile({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 2),
            Text(selected ?? 'Select', style: const TextStyle(color: Colors.black54)),
          ],
        ),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final bool isSelected = opt == selected;
              return ChoiceChip(
                label: Text(opt),
                selected: isSelected,
                onSelected: (_) => onSelected(isSelected ? null : opt),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                backgroundColor: Colors.white,
                selectedColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black54, size: 20),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search your recipes...',
                hintStyle: TextStyle(color: Colors.black54, fontSize: 15),
              ),
              onChanged: (v) => context.read<MyRecipesViewModel>().setSearchQuery(v),
            ),
          ),
        ],
      ),
    );
  }
}