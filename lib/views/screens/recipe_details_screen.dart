import 'package:flutter/material.dart';
import 'package:recipe_app/core/constants/app_colors.dart';
import 'package:recipe_app/models/meal_plan.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';

class RecipeDetailsScreen extends StatefulWidget {
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
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  String? _selectedTime;
  int? _selectedPeople;

  @override
  Widget build(BuildContext context) {
    debugPrint('RecipeDetailsScreen building with title: ${widget.title}, mealType: ${widget.mealType}, fromAdminScreen: ${widget.fromAdminScreen}');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Recipe Details', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        ),
        actions: widget.fromAdminScreen
            ? [
                TextButton(
                  onPressed: () async {
                    debugPrint('Add button pressed. Meal type: ${widget.mealType}');
                    if (widget.mealType == null) {
                      debugPrint('Meal type is null, not creating MealEntry');
                      return;
                    }
                    // Ensure time and persons are set
                    if (_selectedTime == null || _selectedPeople == null) {
                      await _showMealPlanDialog(context);
                    }
                    if (_selectedTime == null || _selectedPeople == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please set time and number of persons first')),
                      );
                      return;
                    }
                    // Create a MealEntry from the recipe data
                    debugPrint('Creating MealEntry with ingredients: ${widget.ingredients}');
                    debugPrint('Creating MealEntry with steps: ${widget.steps}');
                    final mealEntry = MealEntry(
                      id: widget.recipeId,
                      type: widget.mealType!,
                      title: widget.title,
                      minutes: widget.minutes ?? 0,
                      imageAssetPath: widget.imageAssetPath,
                      time: _selectedTime,
                      people: _selectedPeople,
                      ingredients: widget.ingredients,
                      instructions: widget.steps,
                    );
                    debugPrint('Created MealEntry: ${mealEntry.title}, type: ${mealEntry.type}');
                    debugPrint('MealEntry ingredients: ${mealEntry.ingredients}');
                    debugPrint('MealEntry instructions: ${mealEntry.instructions}');
                    Navigator.of(context).pop(mealEntry);
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.add_task, color: Colors.black87, size: 20),
                      SizedBox(width: 4),
                      Column(
                        children: [
                          Text(
                        'Add to',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),

                      Text(
                        'Meal Plan',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                        ],
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
                    _HeroImage(title: widget.title, imageAssetPath: widget.imageAssetPath),
                    const SizedBox(height: 16),
                    _ActionRow(
                      onMealPlanTap: () => _showMealPlanDialog(context),
                      fromAdminScreen: widget.fromAdminScreen,
                      recipeId: widget.recipeId,
                      title: widget.title,
                      imageUrl: widget.imageAssetPath,
                      minutes: widget.minutes ?? 0,
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
                            Text(
                              widget.minutes == null ? 'Not available' : '${widget.minutes} min',
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
                        children: (widget.ingredients == null || widget.ingredients!.isEmpty)
                            ? const [
                                _IngredientTile(name: 'No ingredients available', note: ''),
                              ]
                            : widget.ingredients!
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
                        children: (widget.steps == null || widget.steps!.isEmpty)
                            ? const [
                                _StepCard(step: 1, text: 'No steps available'),
                              ]
                            : List<Widget>.generate(
                                widget.steps!.length,
                                (i) => _StepCard(step: i + 1, text: widget.steps![i]),
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

  Future<void> _showMealPlanDialog(BuildContext context) async {
    final TextEditingController peopleController = TextEditingController(
      text: _selectedPeople == null ? '' : _selectedPeople.toString(),
    );

    TimeOfDay _parseTimeOfDay(String s) {
      final RegExp re = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false);
      final Match? m = re.firstMatch(s.trim());
      if (m == null) return TimeOfDay.now();
      int hour = int.tryParse(m.group(1) ?? '') ?? 0;
      final int minute = int.tryParse(m.group(2) ?? '') ?? 0;
      final String period = (m.group(3) ?? '').toUpperCase();
      hour = hour % 12;
      if (period == 'PM') hour += 12;
      return TimeOfDay(hour: hour, minute: minute);
    }

    final TimeOfDay initialTime = _selectedTime != null ? _parseTimeOfDay(_selectedTime!) : TimeOfDay.now();
    TimeOfDay selectedTime = initialTime;
    String? selectedTimeText = _selectedTime; // Pre-fill from previously selected time

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Meal Plan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: peopleController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Number of People',
                      hintText: 'Enter number of people',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Set Time'),
                    subtitle: Text(selectedTimeText ?? selectedTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedTime = picked;
                          selectedTimeText = picked.format(context);
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Handle the meal plan creation
                    final String people = peopleController.text;
                    final int peopleCount = int.tryParse(people) ?? 1;
                    
                    // Update the parent state with selected values
                    if (mounted) {
                      setState(() {
                        _selectedPeople = peopleCount;
                        _selectedTime = selectedTimeText ?? selectedTime.format(context);
                      });
                    }
                    
                    Navigator.of(context).pop();
                    
                    // Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Meal planned for $people people at ${selectedTimeText ?? selectedTime.format(context)}'),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
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
  final VoidCallback onMealPlanTap;
  final bool fromAdminScreen;
  final String recipeId;
  final String title;
  final String imageUrl;
  final int minutes;
  const _ActionRow({required this.onMealPlanTap, this.fromAdminScreen = false, required this.recipeId, required this.title, required this.imageUrl, required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BookmarkButton(recipeId: recipeId, title: title, imageUrl: imageUrl, minutes: minutes),
          fromAdminScreen
              ? _ActionItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Set Persons',
                  secondLine: 'and Time',
                  onTap: onMealPlanTap,
                )
              : const _ActionItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Meal Plan',
                ),
          const _ActionItem(icon: Icons.shopping_bag_outlined, label: 'Groceries'),
          const _ActionItem(icon: Icons.ios_share_outlined, label: 'Share'),
          const _ActionItem(icon: Icons.restaurant_menu_outlined, label: 'Nutrition'),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? secondLine;
  final VoidCallback? onTap;
  const _ActionItem({required this.icon, required this.label, this.secondLine, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.black87),
          const SizedBox(height: 4),
          if (secondLine == null)
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
            )
          else
            Column(
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                Text(
                  secondLine!,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  final String recipeId;
  final String title;
  final String imageUrl;
  final int minutes;
  const _BookmarkButton({required this.recipeId, required this.title, required this.imageUrl, required this.minutes});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreRecipesService();
    return StreamBuilder<bool>(
      stream: service.isBookmarkedStream(recipeId),
      builder: (context, snapshot) {
        final bool isBookmarked = snapshot.data == true;
        return InkWell(
          onTap: () async {
            await service.toggleBookmark(recipeId: recipeId, title: title, imageUrl: imageUrl, minutes: minutes);
          },
          child: Column(
            children: [
              Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: isBookmarked ? Colors.black : Colors.black87),
              const SizedBox(height: 4),
              const Text(
                'Bookmark',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        );
      },
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