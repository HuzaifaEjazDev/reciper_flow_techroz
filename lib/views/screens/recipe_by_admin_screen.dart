import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:recipe_app/models/meal_plan.dart';
import 'package:recipe_app/viewmodels/user/admin_recipes_view_model.dart';
import 'package:recipe_app/views/screens/recipe_details_screen.dart';

class RecipeByAdminScreen extends StatelessWidget {
  final String? filterMealType;
  final bool autoApplyFilter;
  final bool allowMealPlanSelection; // true when launched from Meal Planner
  final String? initialSearchQuery; // optional initial search from Home
  final String? initialCuisine; // optional cuisine pre-filter
  const RecipeByAdminScreen({super.key, this.filterMealType, this.autoApplyFilter = false, this.allowMealPlanSelection = false, this.initialSearchQuery, this.initialCuisine});

  @override
  Widget build(BuildContext context) {
    debugPrint('RecipeByAdminScreen building with filterMealType: $filterMealType, autoApplyFilter: $autoApplyFilter');
    return ChangeNotifierProvider<AdminRecipesViewModel>(
      create: (_) => AdminRecipesViewModel()
        ..loadInitial()
        ..loadSortOptions()
        ..setFilterMealType(filterMealType, autoApply: autoApplyFilter)
        ..setSelectedCuisine(initialCuisine)
        ..setQueryTemp(initialSearchQuery ?? '')
        ..setSearchQuery(initialSearchQuery)
        ..applyFilters(),
      child: _RecipeByAdminView(filterMealType: filterMealType, allowMealPlanSelection: allowMealPlanSelection),
    );
  }
}

class _RecipeByAdminView extends StatelessWidget {
  final String? filterMealType;
  final bool allowMealPlanSelection;
  const _RecipeByAdminView({this.filterMealType, this.allowMealPlanSelection = false});
  
  @override
  Widget build(BuildContext context) {
    debugPrint('_RecipeByAdminView building with filterMealType: $filterMealType');
    final vm = context.watch<AdminRecipesViewModel>();
    debugPrint('_RecipeByAdminView got viewModel with selectedMealType: ${vm.selectedMealType}, filterMealType: ${vm.filterMealType}');
    final items = vm.items;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Recipes', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600,)),
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
                          Expanded(
                            child: TextField(
                              controller: vm.searchController, // Use controller from view model
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Search recipes...',
                                hintStyle: TextStyle(color: Colors.black54, fontSize: 15),
                              ),
                              /// here save the search query for temperarry to use it to search it later
                              onChanged: (v) => context.read<AdminRecipesViewModel>().setQueryTemp(v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      /// here when tap the use then the search query runs
                      /// dont search anything until the search button is tapped
                      context.read<AdminRecipesViewModel>().setSearchQuery(
                        context.read<AdminRecipesViewModel>().searchController.text.trim()
                      );
                    },
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7F00),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Center(
                        child: Icon(Icons.search, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      // Open immediately; options are prefetched on init and can refresh in-sheet if needed
                      final viewModel = context.read<AdminRecipesViewModel>();
                      showModalBottomSheet(
                        context: context,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7F00),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Icon(Icons.sort, color: Colors.white),
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
                      if (vm.loading && items.isEmpty)
                        Skeletonizer(
                          enabled: true,
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 4,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.68,
                            ),
                            itemBuilder: (context, index) => const _AdminRecipeCardSkeleton(),
                          ),
                        ),
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
                          return _AdminRecipeCard(data: r, filterMealType: filterMealType, allowMealPlanSelection: allowMealPlanSelection);
                        },
                      ),
                      const SizedBox(height: 12),
                      _PageControls(),
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
  final String? filterMealType;
  final bool allowMealPlanSelection;
  const _AdminRecipeCard({required this.data, this.filterMealType, this.allowMealPlanSelection = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        debugPrint('AdminRecipeCard tapped - Title: ${data.title}');
        debugPrint('AdminRecipeCard ingredients: ${data.ingredients}');
        debugPrint('AdminRecipeCard steps: ${data.steps}');
        
        // Navigate to recipe details and wait for a result
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeDetailsScreen(
              title: data.title,
              imageAssetPath: data.imageUrl,
              minutes: data.minutes,
              ingredients: data.ingredients ?? const [],
              steps: data.steps ?? const [],
              // Show meal plan selection UI only when launched from Meal Planner
              fromAdminScreen: allowMealPlanSelection,
              mealType: allowMealPlanSelection ? filterMealType : null,
              recipeId: data.id, // Pass the recipe ID
            ),
          ),
        );
        
        debugPrint('Received result from RecipeDetailsScreen: $result');
        
        // If we get a MealEntry back, pass it back to the meal planner screen
        if (result is MealEntry) {
          debugPrint('Passing MealEntry back to meal planner: ${result.title}');
          // Pass the result back to the screen that opened this recipe admin screen
          Navigator.of(context).pop(result);
        }
      },
    child: Container(
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
            height: 120,
            child: data.imageUrl.startsWith('http')
                ? Image.network(
                    data.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Image.asset('assets/images/dish/dish1.jpg', fit: BoxFit.cover),
                  )
                : Image.asset(data.imageUrl.isEmpty ? 'assets/images/dish/dish1.jpg' : data.imageUrl, fit: BoxFit.cover),
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
                  const SizedBox(height: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text('${data.minutes} min', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      // const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.flatware, size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text('${data.ingredientsCount} ingredients', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      // const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.local_dining_outlined, size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text('${data.stepsCount} steps', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
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

class _AdminRecipeCardSkeleton extends StatelessWidget {
  const _AdminRecipeCardSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 120, child: Container(color: Colors.white)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                // title (2 lines possible)
                SizedBox(height: 16, width: 140, child: ColoredBox(color: Colors.white)),
                SizedBox(height: 8),
                // time row
                SizedBox(height: 12, width: 90, child: ColoredBox(color: Colors.white)),
                SizedBox(height: 6),
                // ingredients row
                SizedBox(height: 12, width: 120, child: ColoredBox(color: Colors.white)),
                SizedBox(height: 6),
                // steps row
                SizedBox(height: 12, width: 100, child: ColoredBox(color: Colors.white)),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _PageControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminRecipesViewModel>();
    // Hide pager until we know totalCount (prevents showing numbers before data loads)
    if (vm.totalCount == 0 || vm.loading && vm.items.isEmpty) {
      return const SizedBox.shrink();
    }
    final int totalPages = vm.totalPages == 0 ? vm.totalKnownPages : vm.totalPages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: totalPages,
            itemBuilder: (context, index) {
              final int page = index + 1;
              final bool selected = vm.currentPage == page;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton(
                  onPressed: vm.loading ? null : () => context.read<AdminRecipesViewModel>().goToPage(page),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected ? Colors.deepOrange : Colors.white,
                    foregroundColor: selected ? Colors.white : Colors.black87,
                    side: BorderSide(color: selected ? Colors.deepOrange : const Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text(
                    '$page',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          vm.totalCount > 0
              ? 'Page ${vm.currentPage} of ${totalPages > 0 ? totalPages : vm.totalKnownPages} '
              : 'Loading pages…',
          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ],
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
          color: Colors.white,
          // height: MediaQuery.of(context).size.height * 0.65, // 65% of screen height
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
                    
                    // // Debug info
                    // Text(
                    //   'Meal Types: ${vm.mealTypes.length}, Diets: ${vm.diets.length}, Cuisines: ${vm.cuisines.length}, Tags: ${vm.tags.length}',
                    //   style: const TextStyle(fontSize: 12, color: Colors.grey),
                    // ),
                    // const SizedBox(height: 8),
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // clear all selected labels
                                vm.setSelectedMealType(null);
                                vm.setSelectedDiet(null);
                                vm.setSelectedCuisine(null);
                                vm.setSelectedTag(null);
                                // Don't call clearFilters here, just close the sheet
                              },
                              child: const Text('Cancel', style: TextStyle(color: Colors.black),),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF7F00), // FF7F00
                                foregroundColor: Colors.white, // White text
                              ),
                              onPressed: () async {
                                Navigator.of(context).pop();
                                // Check if any filters are selected
                                if (vm.selectedMealType == null && 
                                    vm.selectedDiet == null && 
                                    vm.selectedCuisine == null && 
                                    vm.selectedTag == null) {
                                  // No filters selected, clear all filters to show all recipes
                                  vm.clearFilters();
                                } else {
                                  // Apply filters
                                  vm.applyFilters();
                                }
                              },
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
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
              selected ?? (options.isEmpty ? 'Loading...' : 'Select'), 
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
                'Wait for options to load...',
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