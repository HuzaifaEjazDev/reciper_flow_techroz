import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/models/meal_plan.dart';
import 'package:recipe_app/viewmodels/meal_planner_view_model.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealPlannerViewModel>();
    final List<DayPlan> plans = vm.plans;

    return Container(
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List<Widget>.generate(plans.length, (index) {
                final day = plans[index].date;
                final bool isSelected = index == vm.selectedIndex;
                final String weekday = _weekdayShort(day.weekday);
                final String dateNum = day.day.toString();
                return SizedBox(
                  width: 65,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => vm.selectIndex(index),
                      child: Container(
                        height: 75,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.deepOrange : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(color: Colors.deepOrange.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              weekday,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateNum,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.local_cafe_outlined, color: Colors.deepOrange),
                        SizedBox(width: 8),
                        Text(
                          'BreakFast',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            child: Container(
                              width: 110,
                              height: 100,
                              color: Colors.grey[200],
                              child: Image.asset(
                                (plans.isNotEmpty
                                        ? plans[vm.selectedIndex].mealOfType(MealType.breakfast)?.imageAssetPath
                                        : null) ??
                                    'assets/images/easymakesnack1.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (plans.isNotEmpty
                                          ? plans[vm.selectedIndex].mealOfType(MealType.breakfast)?.title
                                          : null) ??
                                      'Avocado Toast with Eggs',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '8:00 AM',
                                  style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Row(
                                    children: [
                                      const Spacer(),
                                      TextButton(
                                        style: TextButton.styleFrom(foregroundColor: Colors.deepOrange),
                                        onPressed: () {},
                                        child: const Text('View Recipe'),
                                      ),
                                      const SizedBox(width: 8),
                                      Image.asset(
                                        'assets/images/soup.png',
                                        width: 22,
                                        height: 22,
                                        color: Colors.deepOrange,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.ramen_dining, color: Colors.deepOrange, size: 22),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepOrange,
                          side: const BorderSide(color: Colors.deepOrange),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Add Breakfast',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: const [
                        Icon(Icons.local_cafe_outlined, color: Colors.deepOrange),
                        SizedBox(width: 8),
                        Text(
                          'Lunch',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _MealCard(
                      title: (plans.isNotEmpty
                              ? plans[vm.selectedIndex].mealOfType(MealType.lunch)?.title
                              : null) ??
                          'Grilled Chicken Salad',
                      timeText: '1:00 PM',
                      imageAssetPath: (plans.isNotEmpty
                              ? plans[vm.selectedIndex].mealOfType(MealType.lunch)?.imageAssetPath
                              : null) ??
                          'assets/images/quickweeknightmeals2.jpg',
                      icon: Icons.local_cafe_outlined,
                    ),
                    const SizedBox(height: 16),
                    _AddMealButton(text: 'Add Lunch'),

                    const SizedBox(height: 24),

                    Row(
                      children: const [
                        Icon(Icons.local_cafe_outlined, color: Colors.deepOrange),
                        SizedBox(width: 8),
                        Text(
                          'Dinner',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _MealCard(
                      title: (plans.isNotEmpty
                              ? plans[vm.selectedIndex].mealOfType(MealType.dinner)?.title
                              : null) ??
                          'Pasta Arrabbiata',
                      timeText: '7:00 PM',
                      imageAssetPath: (plans.isNotEmpty
                              ? plans[vm.selectedIndex].mealOfType(MealType.dinner)?.imageAssetPath
                              : null) ??
                          'assets/images/quickweeknightmeals1.jpg',
                      icon: Icons.local_cafe_outlined,
                    ),
                    const SizedBox(height: 16),
                    _AddMealButton(text: 'Add Dinner'),

                    const SizedBox(height: 24),

                    Row(
                      children: const [
                        Icon(Icons.local_cafe_outlined, color: Colors.deepOrange),
                        SizedBox(width: 8),
                        Text(
                          'Snacks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _MealCard(
                      title: 'Yogurt Parfait',
                      timeText: '4:00 PM',
                      imageAssetPath: 'assets/images/easymakesnack2.jpg',
                      icon: Icons.local_cafe_outlined,
                    ),
                    const SizedBox(height: 16),
                    _AddMealButton(text: 'Add Snack'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }
}

class _MealCard extends StatelessWidget {
  final String title;
  final String timeText;
  final String imageAssetPath;
  final IconData icon;
  const _MealCard({
    required this.title,
    required this.timeText,
    required this.imageAssetPath,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Container(
              width: 110,
              height: 100,
              color: Colors.grey[200],
              child: Image.asset(
                imageAssetPath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(timeText, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: Colors.deepOrange),
                        onPressed: () {},
                        child: const Text('View Recipe'),
                      ),
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/images/soup.png',
                        width: 22,
                        height: 22,
                        color: Colors.deepOrange,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.ramen_dining, color: Colors.deepOrange, size: 22),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMealButton extends StatelessWidget {
  final String text;
  const _AddMealButton({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.deepOrange,
          side: const BorderSide(color: Colors.deepOrange),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}



