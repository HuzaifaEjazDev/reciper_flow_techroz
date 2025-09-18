import 'package:flutter/material.dart';
import 'package:recipe_app/views/widgets/custom_elevated_button.dart';
import 'package:recipe_app/views/screens/startInfoCollect/onboarding_complete_screen.dart';

class GroceryListHabitsScreen extends StatefulWidget {
  const GroceryListHabitsScreen({super.key});

  @override
  State<GroceryListHabitsScreen> createState() => _GroceryListHabitsScreenState();
}

class _GroceryListHabitsScreenState extends State<GroceryListHabitsScreen> {
  final List<String> _options = const <String>[
    'Yes',
    'No',
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
              const SizedBox(height: 200),
              const Text(
                'Do you create a grocery list before going shopping?',
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
                    return _HabitTile(
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
                      builder: (_) => const OnboardingCompleteScreen(),
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

class _HabitTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _HabitTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? Colors.deepOrange : Colors.white,
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
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? null
                : Border.all(
                    color: const Color(0xFFD1D5DB),
                    width: 1.2,
                  ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontFamily: 'Roboto',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


