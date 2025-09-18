import 'package:flutter/material.dart';
import 'package:recipe_app/views/widgets/custom_elevated_button.dart';
import 'package:recipe_app/views/screens/startInfoCollect/grocery_list_habits_screen.dart';

class RecipeSourcesScreen extends StatefulWidget {
  const RecipeSourcesScreen({super.key});

  @override
  State<RecipeSourcesScreen> createState() => _RecipeSourcesScreenState();
}

class _RecipeSourcesScreenState extends State<RecipeSourcesScreen> {
  final List<String> _options = const <String>[
    'Social media',
    'Google',
    'Cookbooks',
    'Other',
  ];

  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 120),
              const Text(
                'Where do you get your recipes from?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final label = _options[index];
                    final isSelected = _selected == label;
                    return _SourceTile(
                      label: label,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selected = label;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              CustomElevatedButton(
                text: 'Next',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const GroceryListHabitsScreen(),
                    ),
                  );
                },
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SourceTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        overlayColor: MaterialStateProperty.all<Color>(Colors.transparent),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD1D5DB),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    fontFamily: 'Roboto',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _CheckBox(isChecked: isSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  final bool isChecked;

  const _CheckBox({required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isChecked ? Colors.deepOrange : Colors.transparent,
        border: Border.all(
          color: isChecked ? Colors.deepOrange : const Color(0xFFD1D5DB),
          width: 1.4,
        ),
      ),
    );
  }
}


