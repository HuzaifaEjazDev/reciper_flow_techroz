import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/views/screens/auth_wrapper.dart';
import 'firebase_options.dart';
import 'package:recipe_app/viewmodels/user/home_view_model.dart';
import 'package:recipe_app/viewmodels/user/meal_planner_view_model.dart';
import 'package:recipe_app/viewmodels/user/my_recipes_view_model.dart';
import 'package:recipe_app/viewmodels/user/user_recipes_pager_view_model.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';
import 'package:recipe_app/viewmodels/auth_view_model.dart';
import 'package:recipe_app/viewmodels/groceries_viewmodel.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel()),
        ChangeNotifierProvider<HomeViewModel>(create: (_) => HomeViewModel()..loadInitial()),
        ChangeNotifierProvider<MealPlannerViewModel>(create: (_) => MealPlannerViewModel()),
        ChangeNotifierProvider<MyRecipesViewModel>(create: (_) => MyRecipesViewModel()),
        ChangeNotifierProvider<UserRecipesPagerViewModel>(create: (_) => UserRecipesPagerViewModel(FirestoreRecipesService())),
        ChangeNotifierProvider<GroceriesViewModel>(create: (_) => GroceriesViewModel()),
      ],
      child: MaterialApp(
        title: 'Recipe App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepOrange,
          fontFamily: 'Poppins',
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}