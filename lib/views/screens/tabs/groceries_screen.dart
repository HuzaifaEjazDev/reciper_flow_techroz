import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class GroceriesScreen extends StatefulWidget {
  const GroceriesScreen({super.key});

  @override
  State<GroceriesScreen> createState() => _GroceriesScreenState();
}

class _GroceriesScreenState extends State<GroceriesScreen> {
  final Set<String> _checked = <String>{};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 70),
        children: [
          _buildSearchBar(),
          const SizedBox(height: 16),

          _buildRecipesHeader(context),
          const SizedBox(height: 10),
          _buildRecipeCardsRow(),

          const SizedBox(height: 20),
          _buildSortRow(),

          const SizedBox(height: 20),
          _SectionTitle(icon: Icons.eco_outlined, text: 'Fresh Produce'),
          const SizedBox(height: 8),
          ..._buildGroceryTiles([
            const _GroceryItem('Tomato', '50 g', 'https://images.unsplash.com/photo-1546470427-2ab16772f2bb?w=200'),
            const _GroceryItem('Boiled Potato', '100 g', 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=200'),
            const _GroceryItem('Onion', '75 g', 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=200'),
            const _GroceryItem('Cucumber', '1 pc', 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=200'),
          ]),

          const SizedBox(height: 20),
          _SectionTitle(icon: Icons.egg_alt_outlined, text: 'Dairy, Eggs & Fridge'),
          const SizedBox(height: 8),
          ..._buildGroceryTiles([
            const _GroceryItem('Milk', '1 L', 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=200'),
            const _GroceryItem('Eggs', '12 pcs', 'https://images.unsplash.com/photo-1517959105821-eaf2591984dd?w=200'),
            const _GroceryItem('Yogurt', '250 g', 'https://images.unsplash.com/photo-1580910051074-3eb694886505?w=200'),
          ]),

          const SizedBox(height: 20),
          _SectionTitle(icon: Icons.set_meal_outlined, text: 'Meat & Seafood'),
          const SizedBox(height: 8),
          ..._buildGroceryTiles([
            const _GroceryItem('Chicken Breast', '500 g', 'https://images.unsplash.com/photo-1560785496-3c9d27877182?w=200'),
            const _GroceryItem('Salmon Fillet', '300 g', 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=200'),
          ]),

          const SizedBox(height: 20),
          _SectionTitle(icon: Icons.inventory_2_outlined, text: 'Pantry Staples'),
          const SizedBox(height: 8),
          ..._buildGroceryTiles([
            const _GroceryItem('Olive Oil', '500 ml', 'https://images.unsplash.com/photo-1510626176961-4b57d4fbad03?w=200'),
            const _GroceryItem('Pasta', '250 g', 'https://images.unsplash.com/photo-1523986371872-9d3ba2e2f642?w=200'),
            const _GroceryItem('Rice', '1 kg', 'https://images.unsplash.com/photo-1603184122478-4a3e5e7f44a8?w=200'),
          ]),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: const [
          Icon(Icons.search, color: Colors.black87, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search Groceries',
              style: TextStyle(color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipesHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Recipes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
        TextButton.icon(
          onPressed: () {},
          style: TextButton.styleFrom(foregroundColor: Colors.black87),
          icon: const Text('All Recipes', style: TextStyle(fontWeight: FontWeight.w600)),
          label: const Icon(CupertinoIcons.chevron_right, color: Colors.black87),
        )
      ],
    );
  }

  Widget _buildRecipeCardsRow() {
    return Row(
      children: [
        Expanded(child: _RecipeCard(title: 'Caprese Salad', imagePath: 'assets/images/quickweeknightmeals2.jpg')),
        const SizedBox(width: 12),
        Expanded(child: _RecipeCard(title: 'Berry Smoothie', imagePath: 'assets/images/easymakesnack1.jpg')),
      ],
    );
  }

  Widget _buildSortRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('Sort by: ', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: const [
              Text('Filter', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
              SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down, color: Colors.black87),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGroceryTiles(List<_GroceryItem> items) {
    return items
        .map(
          (it) => Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    it.imagePath,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, color: Colors.black26),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(it.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black87)),
                ),
                Text(it.quantity, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_checked.contains(it.name)) {
                        _checked.remove(it.name);
                      } else {
                        _checked.add(it.name);
                      }
                    });
                  },
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _checked.contains(it.name) ? Colors.deepOrange : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _checked.contains(it.name) ? Colors.deepOrange : const Color(0xFFD1D5DB)),
                    ),
                    child: _checked.contains(it.name)
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}

class _RecipeCard extends StatelessWidget {
  final String title;
  final String imagePath;
  const _RecipeCard({required this.title, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 196;
    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Image takes top 65%
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: cardHeight * 0.65,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(color: Color(0xFFE5E7EB)),
            ),
          ),
          // Close chip on image
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 16, color: Colors.black87),
            ),
          ),
          // Bottom white section (35%) with title above and View Recipe below
          Positioned(
            left: 0,
            right: 0,
            bottom: -10,
            height: cardHeight * 0.43,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.deepOrange, padding: EdgeInsets.zero),
                    onPressed: () {},
                    icon: const Text('View Recipe', style: TextStyle(fontWeight: FontWeight.w700)),
                    label: const Icon(CupertinoIcons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon; // ignored (kept for call sites)
  final String text;
  const _SectionTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
    );
  }
}

class _GroceryItem {
  final String name;
  final String quantity;
  final String imagePath;
  const _GroceryItem(this.name, this.quantity, this.imagePath);
}



