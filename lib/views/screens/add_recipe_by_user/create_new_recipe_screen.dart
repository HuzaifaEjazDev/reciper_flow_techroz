import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/core/constants/app_colors.dart';
import 'package:recipe_app/viewmodels/create_new_recipe_view_model.dart';
import 'package:recipe_app/viewmodels/my_recipes_view_model.dart';
import 'package:recipe_app/models/user_recipe.dart';

class CreateNewRecipeScreen extends StatelessWidget {
  final bool isEdit;
  final UserRecipe? initial;
  const CreateNewRecipeScreen({super.key, this.isEdit = false, this.initial});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CreateNewRecipeViewModel>(
      create: (_) {
        final vm = CreateNewRecipeViewModel();
        vm.prefillFrom(initial);
        return vm;
      },
      child: _CreateRecipeView(isEdit: isEdit),
    );
  }
}

class _CreateRecipeView extends StatelessWidget {
  final bool isEdit;
  const _CreateRecipeView({required this.isEdit});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CreateNewRecipeViewModel>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(isEdit ? 'Edit Recipe' : 'Create New Recipe', style: const TextStyle(color: Colors.black87, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recipe Image', style: TextStyle(fontSize: 22,color: Colors.black87)),
              const SizedBox(height: 10),
              _ImagePickerCard(
                onTap: () => vm.pickImage(),
              ),
              const SizedBox(height: 16),
              const Text('Recipe Title', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: vm.titleController,
                decoration: InputDecoration(
                  hintText: "Enter your recipe's name",
                  hintStyle: const TextStyle(color: Colors.black45),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary500)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Ingredients', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black87)),
              const SizedBox(height: 12),
              ListView.builder(
                itemCount: vm.qtyControllers.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return _IngredientRow(index: index);
                },
              ),
              const SizedBox(height: 8),
              _AddButton(
                icon: Icons.add,
                label: 'Add Ingredient',
                onTap: () => vm.addIngredient(),
              ),
              const SizedBox(height: 24),
              const Text('Cooking Steps', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black87)),
              const SizedBox(height: 12),
              ListView.builder(
                itemCount: vm.stepControllers.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) => _StepTile(index: index),
              ),
              const SizedBox(height: 8),
              _AddButton(
                icon: Icons.add,
                label: 'Add Step',
                onTap: () => vm.addStep(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final recipe = vm.buildRecipe();
                    final String title = recipe.title.isEmpty ? 'Untitled Recipe' : recipe.title;
                    // Save to MyRecipesViewModel if available up the tree
                    try {
                      final myVm = context.read<MyRecipesViewModel>();
                      myVm.add(MyRecipeCardData(
                        title: title,
                        imageAssetPath: recipe.imagePath ?? 'assets/images/easymakesnack1.jpg',
                        ingredientsCount: recipe.ingredients.length,
                        stepsCount: recipe.steps.length,
                        recipe: recipe,
                      ));
                    } catch (_) {}
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Saved: '+title)),
                    );
                    Navigator.of(context).maybePop();
                  },
                  child: const Text('Save Recipe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ImagePickerCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CreateNewRecipeViewModel>();
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        height: 160,
        child: CustomPaint(
          painter: _DashedRRectPainter(
            color: Colors.black87,
            strokeWidth: 2,
            radius: 16,
            dashLength: 6,
            gapLength: 6,
          ),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F8),
              borderRadius: BorderRadius.circular(12)
            ),
            clipBehavior: Clip.antiAlias,
            child: vm.imagePath == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.image_outlined, size: 40, color: Colors.black38),
                      SizedBox(height: 10),
                      Text('Upload Recipe Image', style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('Tap to select an image', style: TextStyle(color: Colors.black38)),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(vm.imagePath!),
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                          child: const Text('Change', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final int index;
  const _IngredientRow({required this.index});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CreateNewRecipeViewModel>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              controller: vm.qtyControllers[index],
              decoration: const InputDecoration(border: InputBorder.none, hintText: '1 cup', hintStyle: TextStyle(color: Colors.black45)),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              controller: vm.nameControllers[index],
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'Flour', hintStyle: TextStyle(color: Colors.black45)),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => vm.removeIngredient(index),
          ),
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  final int index;
  const _StepTile({required this.index});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CreateNewRecipeViewModel>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 24, child: Text((index + 1).toString()+'.', style: const TextStyle(color: Colors.black87))),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              controller: vm.stepControllers[index],
              maxLines: null,
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'Write step here...', hintStyle: TextStyle(color: Colors.black45)),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => vm.removeStep(index),
          ),
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AddButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF7A00)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary500),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double gapLength;

  _DashedRRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(rect.deflate(strokeWidth / 2), Radius.circular(radius));
    final Path path = Path()..addRRect(rrect);
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + dashLength;
        final Path extractPath = metric.extractPath(distance, next);
        canvas.drawPath(extractPath, paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}


