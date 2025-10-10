import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/viewmodels/dietary_preferences_view_model.dart';

class DietaryPreferencesScreen extends StatelessWidget {
  const DietaryPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Dietary Preferences'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ChangeNotifierProvider(
          create: (_) => DietaryPreferencesViewModel()..init(),
          child: const _DietaryPreferencesContent(),
        ),
      ),
    );
  }
}

class _DietaryPreferencesContent extends StatelessWidget {
  const _DietaryPreferencesContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DietaryPreferencesViewModel>();
    
    return Column(
      children: [
        const SizedBox(height: 16),
        // const Text(
        //   'Select your dietary preferences and cuisine interests',
        //   style: TextStyle(
        //     fontSize: 16,
        //     color: Colors.black54,
        //   ),
        //   textAlign: TextAlign.center,
        // ),
        // const SizedBox(height: 24),
        
        // Show loading indicator if data is loading
        if (viewModel.isLoading)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else
          // Expansion tiles for cuisines and diets
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _ExpansionTileWithChips(
                          title: 'Cuisine Interests',
                          options: viewModel.cuisines,
                          selectedOptions: viewModel.selectedCuisines,
                          onToggle: (option) => viewModel.toggleCuisine(option),
                        ),
                        const SizedBox(height: 16),
                        _ExpansionTileWithChips(
                          title: 'Diet Preferences',
                          options: viewModel.diets,
                          selectedOptions: viewModel.selectedDiets,
                          onToggle: (option) => viewModel.toggleDiet(option),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Error message if any
                if (viewModel.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                // Save button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () async {
                              final success = await viewModel.savePreferences();
                              if (success && context.mounted) {
                                Navigator.of(context).pop(); // Go back to profile screen
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Preferences saved successfully'),
                                    ),
                                  );
                                }
                              } else if (!success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to save preferences'),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7F00),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        viewModel.isLoading ? 'Saving...' : 'Save',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ExpansionTileWithChips extends StatelessWidget {
  final String title;
  final List<String> options;
  final Set<String> selectedOptions;
  final Function(String) onToggle;

  const _ExpansionTileWithChips({
    required this.title,
    required this.options,
    required this.selectedOptions,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                final isSelected = selectedOptions.contains(option);
                return ChoiceChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (_) => onToggle(option),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? Colors.deepOrange : const Color(0xFFE5E7EB),
                    ),
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.deepOrange : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}