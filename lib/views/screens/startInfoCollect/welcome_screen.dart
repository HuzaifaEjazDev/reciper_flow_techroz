import 'package:flutter/material.dart';
import '../../widgets/custom_elevated_button.dart';
import 'package:recipe_app/core/constants/app_colors.dart';
import 'package:recipe_app/views/auth/singup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipe_app/views/screens/main_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/views/screens/startInfoCollect/goals_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;

  Future<bool> _hasCompletedOnboarding() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        // Check if user has completed onboarding by checking the onBoardingDone field
        if (data != null) {
          // Check if onboarding is explicitly marked as done
          if (data.containsKey('onBoardingDone') && data['onBoardingDone'] == true) {
            return true;
          }
          
          // Check if all required onboarding data is present (old method)
          if (data.containsKey('onboardingData')) {
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

              return hasGoals && hasCookingFrequency && hasDietPreference && 
                     hasCuisinePreferences && hasRecipeSources && hasGroceryListHabits;
            }
          }
        }
      }
    } catch (e) {
      print('Error checking onboarding status: $e');
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    setState(() {
      _isLoading = true;
    });

    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is already authenticated, check onboarding status
      final hasCompletedOnboarding = await _hasCompletedOnboarding();
      
      if (mounted) {
        if (hasCompletedOnboarding) {
          // Skip onboarding and go directly to main screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } else {
          // User hasn't completed onboarding, start from goals screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const GoalsScreen()),
          );
        }
      }
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Circular image placed inside a box; box padding = 10, image padding to box = 10
                _buildBoxedCircularImage(),
                
                const SizedBox(height: 40),
                
                // App Title
                _buildAppTitle(),
                
                const SizedBox(height: 24),
                
                // Description Text
                _buildDescriptionText(),
                
                const SizedBox(height: 40),
                
                // Get Started Button
                _buildGetStartedButton(context),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoxedCircularImage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        return Container(
          width: boxWidth,
          padding: const EdgeInsets.all(15), // box padding = 10
          child: AspectRatio(
            aspectRatio: 1,
            child: Padding(
              padding: const EdgeInsets.all(12), // image padding with box = 10
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.restaurant_menu,
                        size: boxWidth * 0.35,
                        color: AppColors.primary500,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppTitle() {
    return const Text(
      'Recipeflow',
      style: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        color: Colors.black87,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescriptionText() {
    return const Text(
      'Your culinary journey begins here. Discover personalized recipes, simplify meal planning, and ignite your passion for cooking.',
      style: TextStyle(
        fontSize: 18,
        color: Colors.black54,
        height: 1.5,
        letterSpacing: 0.3,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return CustomElevatedButton(
      text: 'Get Started',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SingUp(),
          ),
        );
      },
    );
  }
}