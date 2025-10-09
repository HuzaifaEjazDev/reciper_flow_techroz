import 'package:flutter/material.dart';
import 'package:recipe_app/views/widgets/custom_elevated_button.dart';
import 'package:recipe_app/views/screens/startInfoCollect/recipe_sources_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CuisineInterestsScreen extends StatefulWidget {
  const CuisineInterestsScreen({super.key});

  @override
  State<CuisineInterestsScreen> createState() => _CuisineInterestsScreenState();
}

class _CuisineInterestsScreenState extends State<CuisineInterestsScreen> {
  final List<String> _options = const <String>[
    'Italian',
    'Mexican',
    'Indian',
    'Chinese',
    'Japanese',
    'French',
    'Thai',
    'Mediterrannean',
    'American',
    'Other',
  ];

  Set<String> _selected = <String>{};
  final TextEditingController _otherController = TextEditingController();
  bool _showOtherField = false;

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  Future<void> _saveCuisinePreferences() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final List<String> cuisines = _selected.toList();
      
      // If "Other" is selected and there's text in the field, add it to the list
      if (_selected.contains('Other') && _otherController.text.isNotEmpty) {
        cuisines.remove('Other');
        cuisines.add(_otherController.text.trim());
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'onboardingData': {
          'cuisinePreferences': cuisines,
        }
      }, SetOptions(merge: true));
    } catch (e) {
      // Handle error silently or show a message to the user
      print('Error saving cuisine preferences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black87,
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Are you interested in any specific cuisines?',
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
                  itemCount: _options.length + (_showOtherField ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    // Handle the additional "Other" text field
                    if (_showOtherField && index == _options.length) {
                      return TextField(
                        controller: _otherController,
                        decoration: const InputDecoration(
                          hintText: 'Please specify...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide(color: Colors.deepOrange),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      );
                    }

                    final label = _options[index];
                    final isSelected = _selected.contains(label);
                    return _CuisineTile(
                      label: label,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (_selected.contains(label)) {
                            _selected.remove(label);
                            // If "Other" is deselected, hide the text field
                            if (label == 'Other') {
                              _showOtherField = false;
                              _otherController.clear();
                            }
                          } else {
                            // If "Other" is selected, deselect all other options
                            if (label == 'Other') {
                              _selected.clear();
                              _selected.add(label);
                              _showOtherField = true;
                            } else {
                              // If any other option is selected and "Other" is currently selected, deselect "Other"
                              if (_selected.contains('Other')) {
                                _selected.remove('Other');
                                _showOtherField = false;
                                _otherController.clear();
                              }
                              _selected.add(label);
                            }
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              CustomElevatedButton(
                text: 'Next',
                onPressed: () async {
                  if (_selected.isNotEmpty) {
                    // Save cuisine preferences to Firestore
                    await _saveCuisinePreferences();
                    
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RecipeSourcesScreen(),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
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

class _CuisineTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CuisineTile({
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
      child: isChecked
          ? const Icon(
              Icons.check,
              size: 14,
              color: Colors.white,
            )
          : null,
    );
  }
}