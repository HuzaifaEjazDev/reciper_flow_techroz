import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/viewmodels/auth_view_model.dart';
import 'package:recipe_app/views/widgets/custom_elevated_button.dart';
import 'package:recipe_app/views/auth/singup_screen.dart';
import 'package:recipe_app/views/screens/main_screen.dart';
import 'package:recipe_app/views/screens/startInfoCollect/goals_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

  Future<void> _handleGoogleSignIn() async {
    final success = await context.read<AuthViewModel>().signInWithGoogle();
    if (success) {
      // Check if user has completed onboarding
      final hasCompletedOnboarding = await _hasCompletedOnboarding();
      
      if (hasCompletedOnboarding) {
        // Skip onboarding and go directly to main screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      } else {
        // User hasn't completed onboarding, start from goals screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const GoalsScreen()),
          (route) => false,
        );
      }
    } else {
      final msg = context.read<AuthViewModel>().errorMessage ?? 'Google Sign-In failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(duration: const Duration(seconds: 3), content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 90),
              const Text(
                'Welcome back',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Email Address',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'your.email@example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF9CA3AF)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Password',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '*********',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF9CA3AF)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              // Inline error removed; show SnackBar on error instead
              const SizedBox(height: 24),
              CustomElevatedButton(
                text: authViewModel.isLoading ? 'Signing In...' : 'Sign In',
                onPressed: authViewModel.isLoading
                    ? null
                    : () async {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text.trim();
                        
                        if (email.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(duration: Duration(seconds: 3), content: Text('Please enter email and password')),
                          );
                          return;
                        }
                        
                        final success = await context.read<AuthViewModel>().signIn(email, password);
                        if (success) {
                          // Check if user has completed onboarding
                          final hasCompletedOnboarding = await _hasCompletedOnboarding();
                          
                          if (hasCompletedOnboarding) {
                            // Skip onboarding and go directly to main screen
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const MainScreen()),
                              (route) => false,
                            );
                          } else {
                            // User hasn't completed onboarding, start from goals screen
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const GoalsScreen()),
                              (route) => false,
                            );
                          }
                        } else {
                          final msg = context.read<AuthViewModel>().errorMessage ?? 'Sign in failed';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(duration: const Duration(seconds: 3), content: Text(msg)),
                          );
                        }
                      },
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(child: Divider(thickness: 1, color: Color(0xFFE5E7EB))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: Colors.black87)),
                  ),
                  Expanded(child: Divider(thickness: 1, color: Color(0xFFE5E7EB))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.black87),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SingUp(),
                        ),
                      );
                    },
                    child: const Text('Sign Up'),
                style: TextButton.styleFrom(
                      foregroundColor: Colors.deepOrange, // Explicitly set text color to black
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: authViewModel.isLoading ? null : _handleGoogleSignIn,
                      icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                      label: Text(authViewModel.isLoading ? 'Signing in with Google...' : 'Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.apple, color: Colors.black),
                      label: const Text('Apple'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: Colors.black, // Set text color to black
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}