import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/viewmodels/user/admin_recipes_view_model.dart';

class RecipeByAdminScreen extends StatelessWidget {
  const RecipeByAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminRecipesViewModel>(
      create: (_) => AdminRecipesViewModel()..loadInitial(),
      child: const _RecipeByAdminView(),
    );
  }
}

class _RecipeByAdminView extends StatelessWidget {
  const _RecipeByAdminView();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminRecipesViewModel>();
    final items = vm.items;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Recipes by Admin'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                          const Icon(Icons.search, color: Colors.black54, size: 20),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Search recipes...',
                                hintStyle: TextStyle(color: Colors.black54, fontSize: 15),
                              ),
                              onChanged: (v) => context.read<AdminRecipesViewModel>().setSearchQuery(v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      // Load sort options first
                      await context.read<AdminRecipesViewModel>().loadSortOptions();
                      
                      // Show bottom sheet after loading
                      if (!context.mounted) return;
                      final viewModel = context.read<AdminRecipesViewModel>();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: const Color(0xFFF5F5F5),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (bottomSheetContext) => ChangeNotifierProvider.value(
                          value: viewModel,
                          child: const _SortBottomSheet(),
                        ),
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
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      if (vm.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(vm.error!, style: const TextStyle(color: Colors.red)),
                        ),
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
                        itemBuilder: (context, index) {
                          final r = items[index];
                          return _AdminRecipeCard(data: r);
                        },
                      ),
                      const SizedBox(height: 12),
                      if (vm.hasMore)
                        SizedBox(
                          width: 160,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: vm.loading ? null : () => context.read<AdminRecipesViewModel>().loadMore(),
                            child: vm.loading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Load more'),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminRecipeCard extends StatelessWidget {
  final AdminRecipeCardData data;
  const _AdminRecipeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 150,
            child: data.imageUrl.startsWith('http')
                ? Image.network(data.imageUrl, fit: BoxFit.cover)
                : Image.asset(data.imageUrl.isEmpty ? 'assets/images/easymakesnack1.jpg' : data.imageUrl, fit: BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text('${data.minutes} min', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                      const Icon(Icons.star_border, size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text('${data.rating}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
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

class _SortBottomSheet extends StatelessWidget {
  const _SortBottomSheet();
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AdminRecipesViewModel>(
      builder: (context, vm, child) {
        return Container(
          color: const Color(0xFFF5F5F5),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
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
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Debug info
                    Text(
                      'Meal Types: ${vm.mealTypes.length}, Diets: ${vm.diets.length}, Cuisines: ${vm.cuisines.length}, Tags: ${vm.tags.length}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ChipsExpansionTile(
                        title: 'Meal Types',
                        options: vm.mealTypes,
                        selected: vm.selectedMealType,
                        onSelected: (v) => vm.setSelectedMealType(v),
                      ),
                      const Divider(height: 24, thickness: 1, color: Color(0xFFE5E7EB)),

                      _ChipsExpansionTile(
                        title: 'Diets',
                        options: vm.diets,
                        selected: vm.selectedDiet,
                        onSelected: (v) => vm.setSelectedDiet(v),
                      ),
                      const Divider(height: 24, thickness: 1, color: Color(0xFFE5E7EB)),

                      _ChipsExpansionTile(
                        title: 'Cuisines',
                        options: vm.cuisines,
                        selected: vm.selectedCuisine,
                        onSelected: (v) => vm.setSelectedCuisine(v),
                      ),
                      const Divider(height: 24, thickness: 1, color: Color(0xFFE5E7EB)),

                      _ChipsExpansionTile(
                        title: 'Special Tags',
                        options: vm.tags,
                        selected: vm.selectedTag,
                        onSelected: (v) => vm.setSelectedTag(v),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
            Text(
              selected ?? (options.isEmpty ? 'No options available' : 'Select'), 
              style: TextStyle(
                color: options.isEmpty ? Colors.red : Colors.black54,
              ),
            ),
          ],
        ),
        children: [
          if (options.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                'No data found. Check Firestore configuration.',
                style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic),
              ),
            )
          else
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

