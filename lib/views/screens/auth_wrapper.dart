import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/viewmodels/auth_view_model.dart';
import 'package:recipe_app/views/auth/sign_in_screen.dart';
import 'package:recipe_app/views/screens/main_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;
    
    // Show main screen if user is authenticated, otherwise show sign in screen
    if (user != null) {
      return const MainScreen();
    } else {
      return const SignInScreen();
    }
  }
}