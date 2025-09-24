import 'package:flutter/material.dart';
import 'package:recipe_app/viewmodels/user/home_view_model.dart';
import 'package:recipe_app/viewmodels/user/meal_planner_view_model.dart';
import 'package:recipe_app/viewmodels/user/my_recipes_view_model.dart';
import 'package:recipe_app/views/screens/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/core/constants/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeViewModel>(create: (_) => HomeViewModel()..loadInitial()),
        ChangeNotifierProvider<MealPlannerViewModel>(create: (_) => MealPlannerViewModel()..init()),
        ChangeNotifierProvider<MyRecipesViewModel>(create: (_) => MyRecipesViewModel()),
      ],
      child: MaterialApp(
      title: 'Recipe App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary500),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary500,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.black,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    ),
    );
  }
}

