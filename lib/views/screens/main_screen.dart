import 'package:flutter/material.dart';
import 'package:recipe_app/views/screens/tabs/home_screen.dart';
import 'package:recipe_app/views/screens/tabs/meal_planner_screen.dart';
import 'package:recipe_app/views/screens/tabs/groceries_screen.dart';
import 'package:recipe_app/views/screens/tabs/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<_TabItem> _items = <_TabItem>[
    _TabItem('RecipeApp', const HomeScreen(), Icons.home),
    _TabItem('Meal Planner', const MealPlannerScreen(), Icons.calendar_month),
    _TabItem('Groceries', const GroceriesScreen(), Icons.shopping_cart),
    _TabItem('Profile', const ProfileScreen(), Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final _TabItem active = _items[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          active.title,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: active.page,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.black,
        selectedLabelStyle: const TextStyle(color: Colors.deepOrange),
        unselectedLabelStyle: const TextStyle(color: Color(0xFF374151)),
        items: _items
            .map(
              (e) => BottomNavigationBarItem(
                icon: Icon(e.icon),
                label: e.title,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final String title;
  final Widget page;
  final IconData icon;
  _TabItem(this.title, this.page, this.icon);
}


