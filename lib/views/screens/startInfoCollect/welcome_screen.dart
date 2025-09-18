import 'package:flutter/material.dart';
import '../../widgets/custom_elevated_button.dart';
import 'package:recipe_app/core/constants/app_colors.dart';
import 'package:recipe_app/views/screens/startInfoCollect/goals_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Using responsive width via LayoutBuilder below

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // const Spacer(flex: 1),
              
              // Circular image placed inside a box; box padding = 10, image padding to box = 10
              _buildBoxedCircularImage(),
              
              // const SizedBox(height: 40),
              
              // App Title
              _buildAppTitle(),
              
              const SizedBox(height: 24),
              
              // Description Text
              _buildDescriptionText(),
              
              const Spacer(flex: 2),
              
              // Get Started Button
              _buildGetStartedButton(context),
              
              const SizedBox(height: 40),
            ],
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
            builder: (_) => const GoalsScreen(),
          ),
        );
      },
    );
  }
}