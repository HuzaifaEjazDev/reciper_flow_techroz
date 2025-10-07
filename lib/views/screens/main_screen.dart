import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_app/views/screens/tabs/home_screen.dart';
import 'package:recipe_app/views/screens/tabs/meal_planner_screen.dart';
import 'package:recipe_app/views/screens/tabs/groceries_screen.dart';
import 'package:recipe_app/views/screens/tabs/profile_screen.dart';
import 'package:recipe_app/views/screens/add_recipe_by_user/create_new_recipe_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<_TabItem> _items = <_TabItem>[
    _TabItem('Home', const HomeScreen(), Icons.home_outlined),
    _TabItem('Meal', const MealPlannerScreen(), Icons.menu_book_outlined),
    _TabItem('Groceries', const GroceriesScreen(), Icons.add_shopping_cart_outlined),
    _TabItem('Profile', const ProfileScreen(), Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final _TabItem active = _items[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: _currentIndex == 0 ? false : true, // Left-aligned for home screen, centered for others
        title: _currentIndex == 0
            ? Row(
                children: [
                  // App logo circle
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepOrange,
                    ),
                    child: ClipOval(
                      // shows asset image here
                      child: Image.asset('assets/images/logo.png'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // App title with Noto Sans font
                  Text(
                    'Recipeflow',
                    style: GoogleFonts.notoSans(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      fontSize: 20,
                      // textStyle: const TextStyle(
                      //   fontFamilyFallback: ['Noto Sans', 'sans-serif'],
                      // ),
                    ),
                  ),
                ],
              )
            : Text(
                _currentIndex == 1
                    ? 'Meal Planner'
                    : _currentIndex == 2
                        ? 'Groceries'
                        : 'Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,

          ),
              ),
        // actions: _currentIndex == 0
        //     ? [] // No actions for home screen
        //     : [
        //         // Add notification icon and profile picture for other screens
        //         IconButton(
        //           icon: const Icon(Icons.notifications_none),
        //           color: Colors.black87,
        //           onPressed: () {
        //           },
        //           tooltip: 'Notifications',
        //         ),
        //         const Padding(
        //           padding: EdgeInsets.only(right: 12),
        //           child: CircleAvatar(
        //             radius: 14,
        //             backgroundColor: Color(0xFFE5E7EB),
        //           ),
        //         ),
        //       ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: active.page,
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateNewRecipeScreen(),
                  ),
                );
              },
              backgroundColor: Colors.deepOrange,
              child: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Add Recipe',
            )
          : null,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.deepOrange,
            unselectedItemColor: Colors.grey[800],
            selectedLabelStyle: GoogleFonts.notoSans(
              color: Colors.deepOrange, 
              fontWeight: FontWeight.w600,
              textStyle: const TextStyle(
                fontFamilyFallback: ['Noto Sans', 'sans-serif'],
              ),
            ),
            unselectedLabelStyle: GoogleFonts.notoSans(
              color: const Color(0xFF374151), 
              fontWeight: FontWeight.w600,
              textStyle: const TextStyle(
                fontFamilyFallback: ['Noto Sans', 'sans-serif'],
              ),
            ),
            items: _items
                .map(
                  (e) => BottomNavigationBarItem(
                    icon: Icon(e.icon),
                    label: e.title,
                  ),
                )
                .toList(),
          ),
        ],
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