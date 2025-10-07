import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/core/constants/app_colors.dart';
import 'package:recipe_app/models/user_created_recipe.dart';
import 'package:recipe_app/viewmodels/user/my_recipes_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipe_app/views/screens/add_recipe_by_user/create_new_recipe_screen.dart'; // Add this import
import 'dart:async';

class UserRecipeDetailsScreen extends StatefulWidget {
  final String recipeId;
  
  const UserRecipeDetailsScreen({super.key, required this.recipeId});

  @override
  State<UserRecipeDetailsScreen> createState() => _UserRecipeDetailsScreenState();
}

class _UserRecipeDetailsScreenState extends State<UserRecipeDetailsScreen> {
  late Future<UserCreatedRecipe> _recipeFuture;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _recipeListener;

  @override
  void initState() {
    super.initState();
    // Set up real-time listener for the recipe
    _setupRecipeListener();
  }

  void _setupRecipeListener() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final DocumentReference<Map<String, dynamic>> recipeRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('RecipesCreatedByUser')
        .doc(widget.recipeId);

    _recipeListener = recipeRef.snapshots().listen(
      (snapshot) {
        if (snapshot.exists) {
          setState(() {
            // Update the UI with the new data
          });
        }
      },
      onError: (error) {
        // Handle error
        debugPrint('Error listening to recipe updates: $error');
      },
    );
  }

  Future<UserCreatedRecipe> _fetchRecipeDetails() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('RecipesCreatedByUser')
          .doc(widget.recipeId)
          .get();

      if (!doc.exists) {
        throw Exception('Recipe not found');
      }

      return UserCreatedRecipe.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Error fetching recipe details: $e');
    }
  }

  @override
  void dispose() {
    _recipeListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('User Recipe Details', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreateNewRecipeScreen(
                    isEdit: true,
                    recipeId: widget.recipeId,
                  ),
                ),
              );
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<UserCreatedRecipe>(
          future: _fetchRecipeDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading recipe: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Text('Recipe not found'),
              );
            }

            final recipe = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroImage(title: recipe.title, imageAssetPath: recipe.imageUrl),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Created Recipe',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
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
                          // Display cooking time
                          Text(
                            recipe.minutes > 0 ? '${recipe.minutes} min' : 'Not available',
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
                      children: recipe.ingredients.isEmpty
                          ? const [
                              _IngredientTile(name: 'No ingredients available', note: ''),
                            ]
                          : recipe.ingredients
                              .asMap()
                              .entries
                              .map((entry) => _IngredientTile(
                                    name: '${entry.key + 1}. ${entry.value['quantity']} ${entry.value['name']}',
                                    note: '',
                                  ))
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle(text: 'Cooking Steps'),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: recipe.steps.isEmpty
                          ? const [
                              _StepCard(step: 1, text: 'No steps available'),
                            ]
                          : List<Widget>.generate(
                              recipe.steps.length,
                              (i) => _StepCard(step: i + 1, text: recipe.steps[i]),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
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
        border: Border.all(color: const Color(0xFFF7F4F4)),
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
        border: Border.all(color: const Color(0xFFE5E7EB)),
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