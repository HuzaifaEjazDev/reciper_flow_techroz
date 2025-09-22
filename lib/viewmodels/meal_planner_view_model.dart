import 'package:flutter/foundation.dart';
import 'package:recipe_app/models/meal_plan.dart';

class MealPlannerViewModel extends ChangeNotifier {
  final List<DayPlan> _plans = <DayPlan>[];
  int _selectedIndex = 0;

  List<DayPlan> get plans => List.unmodifiable(_plans);
  int get selectedIndex => _selectedIndex;
  DayPlan? get selectedDay => _plans.isEmpty ? null : _plans[_selectedIndex];

  void init() {
    if (_plans.isNotEmpty) return;
    final DateTime today = DateTime.now();
    for (int i = 0; i < 5; i++) {
      final d = DateTime(today.year, today.month, today.day).add(Duration(days: i));
      _plans.add(
        DayPlan(
          date: d,
          meals: [
            if (i == 0)
              const MealEntry(
                id: 'b1',
                type: MealType.breakfast,
                title: 'Avocado Toast with Eggs',
                minutes: 12,
                imageAssetPath: 'assets/images/easymakesnack1.jpg',
              ),
          ],
        ),
      );
    }
    notifyListeners();
  }

  void selectIndex(int index) {
    if (index < 0 || index >= _plans.length) return;
    _selectedIndex = index;
    notifyListeners();
  }
}


