import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/viewmodels/auth_view_model.dart';
import 'package:recipe_app/views/auth/sign_in_screen.dart';
import 'package:recipe_app/views/screens/main_screen.dart';
import 'package:recipe_app/views/screens/startInfoCollect/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/views/screens/startInfoCollect/goals_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _shouldShowOnboarding(User user) async {
    try {
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('onBoardingDone')) {
          return !(data['onBoardingDone'] as bool? ?? false);
        }
        
        // Check if all required onboarding data is present (old method)
        if (data != null && data.containsKey('onboardingData')) {
          final onboardingData = data['onboardingData'] as Map<String, dynamic>?;
          if (onboardingData != null) {
            // Check if all required fields are present and not empty/invalid
            final hasGoals = onboardingData.containsKey('goals') && 
                             onboardingData['goals'] is List && 
                             (onboardingData['goals'] as List).isNotEmpty;
                             
            final hasCookingFrequency = onboardingData.containsKey('cookingFrequency') && 
                                        onboardingData['cookingFrequency'] != null && 
                                        onboardingData['cookingFrequency'] != '';
                                        
            final hasDietPreference = onboardingData.containsKey('dietPreference') && 
                                      onboardingData['dietPreference'] != null && 
                                      onboardingData['dietPreference'] != '';
                                      
            final hasCuisinePreferences = onboardingData.containsKey('cuisinePreferences') && 
                                          onboardingData['cuisinePreferences'] is List && 
                                          (onboardingData['cuisinePreferences'] as List).isNotEmpty;
                                          
            final hasRecipeSources = onboardingData.containsKey('recipeSources') && 
                                     onboardingData['recipeSources'] != null && 
                                     onboardingData['recipeSources'] != '';
                                     
            final hasGroceryListHabits = onboardingData.containsKey('groceryListHabits') && 
                                         onboardingData['groceryListHabits'] != null && 
                                         onboardingData['groceryListHabits'] != '';

            return !(hasGoals && hasCookingFrequency && hasDietPreference && 
                   hasCuisinePreferences && hasRecipeSources && hasGroceryListHabits);
          }
        }
      }
    } catch (e) {
      print('Error checking onboarding status: $e');
    }
    
    // Default to showing onboarding if there's any issue or no data
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;
    final isLoading = authViewModel.isLoading;
    
    // Show loading while auth state is changing to avoid flicker to SignIn
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If user is authenticated, check onboarding status
    if (user != null) {
      return FutureBuilder<bool>(
        future: _shouldShowOnboarding(user),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          if (snapshot.hasData && !snapshot.data!) {
            // Onboarding is done, show main screen
            return const MainScreen();
          } else {
            // Onboarding not done, show onboarding flow
            return const GoalsScreen();
          }
        },
      );
    } else {
      // User not authenticated, show welcome screen
      return const WelcomeScreen();
    }
  }
}