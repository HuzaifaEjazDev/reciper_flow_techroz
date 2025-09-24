import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/core/constants/app_colors.dart';
import 'package:recipe_app/viewmodels/user/my_recipes_view_model.dart';
import 'package:recipe_app/views/screens/add_recipe_by_user/create_new_recipe_screen.dart';

class MyRecipesScreen extends StatelessWidget {
  const MyRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MyRecipesViewModel>(
      create: (_) => MyRecipesViewModel(),
      child: const _MyRecipesView(),
    );
  }
}

class _MyRecipesView extends StatelessWidget {
  const _MyRecipesView();
  @override
  Widget build(BuildContext context) {
    final items = context.watch<MyRecipesViewModel>().items;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('My Recipes', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary500,
        onPressed: () {
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
                const Text('Your Recipes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87, height: 1.2)),
                const SizedBox(height: 16),
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateNewRecipeScreen(
                isEdit: data.recipe != null,
                initial: data.recipe,
              ),
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
                  Image.asset(data.imageAssetPath, fit: BoxFit.cover),
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


