import 'package:flutter/material.dart';
import 'package:recipe_app/views/widgets/custom_elevated_button.dart';
import 'package:recipe_app/views/screens/add_recipe_by_user/my_recipes_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderCard(),
            const SizedBox(height: 20),
            const _SectionTitle('Your Preferences'),
            const SizedBox(height: 10),
            _ChipsRow(chips: const ['Vegetarian', 'Low sugar', 'Italian', 'Quick meals']),
            const SizedBox(height: 20),
            const _SectionTitle('Goals Summary'),
            const SizedBox(height: 10),
            _TwoStatsRow(
              leftTitle: 'Weekly Cooking',
              leftValue: '3–4 days',
              rightTitle: 'Cuisine Focus',
              rightValue: 'Mediterranean',
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Account'),
            const SizedBox(height: 10),
            _NavTile(
              icon: Icons.manage_accounts_outlined,
              title: 'Edit profile',
              subtitle: 'Name, photo, contact',
              onTap: () {},
            ),
            _NavTile(
              icon: Icons.subscriptions_outlined,
              title: 'Subscriptions',
              subtitle: 'Manage plan and billing',
              onTap: () {},
            ),
            _NavTile(
              icon: Icons.tune_outlined,
              title: 'Dietary preferences',
              subtitle: 'Allergies, dislikes, cuisines',
              onTap: () {},
            ),
            _NavTile(
              icon: Icons.book_outlined,
              title: 'My Recipes',
              subtitle: 'Your created recipes',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyRecipesScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            CustomElevatedButton(
              text: 'Log out',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                width: 64,
                height: 64,
                color: Colors.grey[200],
                child: const Icon(Icons.person, color: Colors.black54),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Recipeflow User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                SizedBox(height: 4),
                Text('user@example.com', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepOrange,
              side: const BorderSide(color: Colors.deepOrange),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Edit'),
          )
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87));
  }
}

class _ChipsRow extends StatelessWidget {
  final List<String> chips;
  const _ChipsRow({required this.chips});
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips
          .map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(e, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
              ))
          .toList(),
    );
  }
}

class _TwoStatsRow extends StatelessWidget {
  final String leftTitle;
  final String leftValue;
  final String rightTitle;
  final String rightValue;
  const _TwoStatsRow({
    required this.leftTitle,
    required this.leftValue,
    required this.rightTitle,
    required this.rightValue,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(title: leftTitle, value: leftValue)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(title: rightTitle, value: rightValue)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.title, this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.black87),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: const TextStyle(color: Colors.black54)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}


