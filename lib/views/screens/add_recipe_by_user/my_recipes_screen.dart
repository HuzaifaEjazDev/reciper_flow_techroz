import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/core/constants/app_colors.dart';
import 'package:recipe_app/viewmodels/user/user_recipes_pager_view_model.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';
import 'package:recipe_app/views/screens/add_recipe_by_user/create_new_recipe_screen.dart';
import 'package:recipe_app/views/screens/add_recipe_by_user/user_recipe_details_screen.dart';

class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  late UserRecipesPagerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = UserRecipesPagerViewModel(FirestoreRecipesService())..loadInitial();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserRecipesPagerViewModel>.value(
      value: _viewModel,
      child: const _MyRecipesView(),
    );
  }
}

class _MyRecipesView extends StatelessWidget {
  const _MyRecipesView();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserRecipesPagerViewModel>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Your Recipes', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 16, 25, 8),
              child: Row(
                children: [
                  Expanded(child: _SearchField(viewModel: vm)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => vm.applySearch(),
                    child: Container(
                      height: 48,
                      width: 48,
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
                ],
              ),
            ),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(vm.error!, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                  child: Column(
                    children: [
                      if (vm.loading && vm.items.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: vm.items.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.68,
                        ),
                        itemBuilder: (context, index) {
                          final r = vm.items[index];
                          return _RecipeCard(
                            title: r['title']?.toString() ?? '', 
                            imageAssetPath: r['imageUrl']?.toString() ?? 'assets/images/vegitables.jpg',
                            ingredientsCount: r['ingredients'] is List ? r['ingredients'].length : 0,
                            stepsCount: r['steps'] is List ? (r['steps'] as List).length : 0,
                            id: r['id']?.toString() ?? '',
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _PageControls(vm: vm),
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

class _RecipeCard extends StatelessWidget {
  final String title;
  final String imageAssetPath;
  final int ingredientsCount;
  final int stepsCount;
  final String id;
  
  const _RecipeCard({
    required this.title,
    required this.imageAssetPath,
    required this.ingredientsCount,
    required this.stepsCount,
    required this.id,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 185,
      height: 250,
      child: InkWell(
        onTap: () {
          // Navigate to UserRecipeDetailsScreen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserRecipeDetailsScreen(recipeId: id),
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
                    _RecipeImage(pathOrUrl: imageAssetPath),
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
                        title,
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
                      Text('$ingredientsCount ingredients', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
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
                    Text('$stepsCount steps', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
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

class _SearchField extends StatelessWidget {
  final UserRecipesPagerViewModel viewModel;
  
  const _SearchField({required this.viewModel});
  
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
          Expanded(
            child: TextField(
              controller: viewModel.searchController, // Use controller from view model
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search your recipes...',
                hintStyle: TextStyle(color: Colors.black54, fontSize: 15),
              ),
              /// Save the search query temporarily to use it later when search button is tapped
              onChanged: (v) => viewModel.setQueryTemp(v),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageControls extends StatelessWidget {
  final UserRecipesPagerViewModel vm;
  const _PageControls({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.items.isEmpty && vm.loading) return const SizedBox.shrink();
    final int totalPages = vm.totalPages;
    if (totalPages <= 1) return const SizedBox.shrink();
    return Column(
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
                  onPressed: vm.loading ? null : () => vm.goToPage(page),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected ? Colors.deepOrange : Colors.white,
                    foregroundColor: selected ? Colors.white : Colors.black87,
                    side: BorderSide(color: selected ? Colors.deepOrange : const Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text('$page', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          vm.totalCount > 0
              ? 'Page ${vm.currentPage} of $totalPages  •  ${vm.totalCount} total User Recipes'
              : 'Loading pages…',
          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}