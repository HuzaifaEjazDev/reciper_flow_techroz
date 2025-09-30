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


