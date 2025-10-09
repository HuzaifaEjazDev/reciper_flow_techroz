import 'package:flutter/material.dart';
import 'package:recipe_app/views/widgets/custom_elevated_button.dart';
import 'package:recipe_app/views/screens/startInfoCollect/analysis_progress_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingCompleteScreen extends StatelessWidget {
  const OnboardingCompleteScreen({super.key});

  Future<void> _markOnboardingComplete() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'onBoardingDone': true,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error marking onboarding complete: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double imageDiameter = MediaQuery.of(context).size.width * 0.5; // medium size

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 120),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: imageDiameter,
                  height: imageDiameter,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/vegitables.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Your Culinary Journey Begins!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'We understand your needs and will find recipes based on your interests.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  fontFamily: 'Roboto',
                  height: 1.5,
                ),
              ),
              const Spacer(),
              CustomElevatedButton(
                text: 'Start Cooking',
                onPressed: () async {
                  await _markOnboardingComplete();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AnalysisProgressScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}