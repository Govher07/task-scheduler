import 'package:flutter/material.dart';

// ── Shared colors ─────────────────────────────────────────────────────────────
const _brown = Color(0xFF5C3D11);
const _sage = Color(0xFF7A9E5A);
const _gold = Color(0xFFF5C842);
const _cardBg = Color(0xFFF5EDD8);

// ── Item data ─────────────────────────────────────────────────────────────────
enum _Cat { all, animals, decor, plants, characters }

class _Item {
  final String asset, name;
  final int price;
  final _Cat cat;
  final String? desc;
  const _Item(this.asset, this.name, this.price,
      {required this.cat, this.desc});
}

const _allItems = [
  // Animals
  _Item('assets/transparent_512/chick.png', 'Chick', 200, cat: _Cat.animals),
  _Item('assets/transparent_512/cream_cat.png', 'Cream Cat', 800, cat: _Cat.animals, desc: 'A soft, elegant companion.'),
  _Item('assets/transparent_512/golden_puppy.png', 'Golden Pup', 600, cat: _Cat.animals, desc: 'A loyal friend with a heart of gold.'),
  _Item('assets/transparent_512/hedgehog.png', 'Hedgehog', 350, cat: _Cat.animals),
  _Item('assets/transparent_512/lamb.png', 'Lamb', 400, cat: _Cat.animals),
  _Item('assets/transparent_512/white_rabbit.png', 'White Rabbit', 500, cat: _Cat.animals, desc: 'Gentle and curious by nature.'),
  // Plants
  _Item('assets/transparent_512/fern.png', 'Fern', 80, cat: _Cat.plants),
  _Item('assets/transparent_512/flower_pitcher.png', 'Flower Pitcher', 100, cat: _Cat.plants),
  _Item('assets/transparent_512/flowering_cactus.png', 'Flowering Cactus', 120, cat: _Cat.plants),
  _Item('assets/transparent_512/hanging_vine_plant.png', 'Hanging Vine', 90, cat: _Cat.plants),
  _Item('assets/transparent_512/heartleaf_plant.png', 'Heartleaf', 85, cat: _Cat.plants),
  _Item('assets/transparent_512/ivy_plant.png', 'Ivy Plant', 80, cat: _Cat.plants),
  _Item('assets/transparent_512/jade_succulent.png', 'Jade Succulent', 110, cat: _Cat.plants),
  _Item('assets/transparent_512/pilea_plant.png', 'Pilea Plant', 150, cat: _Cat.plants),
  _Item('assets/transparent_512/snake_plant.png', 'Snake Plant', 100, cat: _Cat.plants),
  _Item('assets/transparent_512/succulent.png', 'Succulent', 70, cat: _Cat.plants),
  _Item('assets/transparent_512/violet_blossom.png', 'Violet Blossom', 95, cat: _Cat.plants),
  // Decor
  _Item('assets/transparent_512/laundry_basket.png', 'Laundry Basket', 450, cat: _Cat.decor),
  _Item('assets/transparent_512/lily_frame.png', 'Lily Frame', 280, cat: _Cat.decor),
  _Item('assets/transparent_512/rocking_chair.png', 'Rocking Chair', 380, cat: _Cat.decor),
  _Item('assets/transparent_512/table_lamp.png', 'Table Lamp', 350, cat: _Cat.decor),
  _Item('assets/transparent_512/tea_set.png', 'Tea Set', 300, cat: _Cat.decor),
  _Item('assets/transparent_512/watering_can.png', 'Watering Can', 120, cat: _Cat.decor),
  _Item('assets/transparent_512/wooden_stool.png', 'Wooden Stool', 300, cat: _Cat.decor),
  // Characters
  _Item('assets/transparent_512/flower_basket_girl.png', 'Flower Girl', 700, cat: _Cat.characters),
  _Item('assets/transparent_512/gardener_boy.png', 'Little Gardener', 700, cat: _Cat.characters),
  _Item('assets/transparent_512/girl_with_mug.png', 'Mug Girl', 650, cat: _Cat.characters),
  _Item('assets/transparent_512/lantern_boy.png', 'Lantern Boy', 600, cat: _Cat.characters),
  _Item('assets/transparent_512/maid_girl.png', 'Maid Mia', 750, cat: _Cat.characters),
  _Item('assets/transparent_512/mushroom_boy.png', 'Mushroom Boy', 550, cat: _Cat.characters),
  _Item('assets/transparent_512/reading_girl.png', 'Reading Girl', 680, cat: _Cat.characters),
  _Item('assets/transparent_512/sleepy_boy.png', 'Sleepy Sam', 450, cat: _Cat.characters),
];

const _featuredItems = [
  _Item('assets/transparent_512/golden_puppy.png', 'Golden Pup', 600, cat: _Cat.animals, desc: 'A loyal friend with a heart of gold.'),
  _Item('assets/transparent_512/cream_cat.png', 'Cream Cat', 800, cat: _Cat.animals, desc: 'A soft, elegant companion.'),
  _Item('assets/transparent_512/white_rabbit.png', 'White Rabbit', 500, cat: _Cat.animals, desc: 'Gentle and curious by nature.'),
];

// ── GamingScreen ──────────────────────────────────────────────────────────────
class GamingScreen extends StatelessWidget {
  const GamingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/home_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC2D2D2D)],
                stops: [0.45, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: IconButton(
                  onPressed: () => _openShop(context),
                  icon: const Icon(Icons.store_rounded, size: 26),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openShop(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _ShopPage(),
      ),
    );
  }
}

// ── Shop page ─────────────────────────────────────────────────────────────────
class _ShopPage extends StatefulWidget {
  const _ShopPage();

  @override
  State<_ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<_ShopPage> {
  _Cat _cat = _Cat.all;
  int _featuredIdx = 0;
  final _pageCtrl = PageController();

  List<_Item> get _filtered => _cat == _Cat.all
      ? _allItems
      : _allItems.where((i) => i.cat == _cat).toList();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/shop_frame.png', fit: BoxFit.fill),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 8),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 10),
                  _buildCategoryTabs(),
                  const SizedBox(height: 10),
                  _buildFeaturedBanner(),
                  const SizedBox(height: 10),
                  Expanded(child: _buildGrid()),
                  _buildBottomTimer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _brown.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: _brown, size: 16),
          ),
        ),
        const Expanded(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🌿', style: TextStyle(fontSize: 14)),
                SizedBox(width: 6),
                Text(
                  'Shop',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _brown,
                  ),
                ),
                SizedBox(width: 6),
                Text('🌿', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
        const _CurrencyChip(amount: '12,450'),
      ],
    );
  }

  // ── Category tabs ─────────────────────────────────────────────────────────
  Widget _buildCategoryTabs() {
    const cats = [
      (_Cat.all, 'All'),
      (_Cat.animals, 'Animals'),
      (_Cat.decor, 'Decor'),
      (_Cat.plants, 'Plants'),
      (_Cat.characters, 'Characters'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cats.map((c) {
          final selected = _cat == c.$1;
          return GestureDetector(
            onTap: () => setState(() => _cat = c.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? _sage : _cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? _sage : _brown.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                c.$2,
                style: TextStyle(
                  color: selected ? Colors.white : _brown,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Featured banner ───────────────────────────────────────────────────────
  Widget _buildFeaturedBanner() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brown.withValues(alpha: 0.2)),
      ),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: _featuredItems.length,
            onPageChanged: (i) => setState(() => _featuredIdx = i),
            itemBuilder: (_, i) {
              final item = _featuredItems[i];
              return Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(children: [
                            const Text('🌿', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 4),
                            Text(
                              'Featured',
                              style: TextStyle(
                                color: _sage,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: _brown,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.desc ?? 'A charming addition to your space.',
                            style: TextStyle(
                              color: _brown.withValues(alpha: 0.65),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _PriceTag(item: item),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Image.asset(item.asset, fit: BoxFit.contain),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _featuredItems.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _featuredIdx ? 14 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: i == _featuredIdx
                        ? _sage
                        : _brown.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Item grid ─────────────────────────────────────────────────────────────
  Widget _buildGrid() {
    final items = _filtered;
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.72,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _ItemCard(item: items[i]),
    );
  }

  // ── Bottom timer ──────────────────────────────────────────────────────────
  Widget _buildBottomTimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, color: _brown.withValues(alpha: 0.7), size: 13),
          const SizedBox(width: 4),
          Text(
            'New items in: 05h 32m',
            style: TextStyle(color: _brown.withValues(alpha: 0.7), fontSize: 12),
          ),
          const SizedBox(width: 4),
          const Text('🌸', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Currency chip ─────────────────────────────────────────────────────────────
class _CurrencyChip extends StatelessWidget {
  final String amount;
  const _CurrencyChip({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            amount,
            style: const TextStyle(
              color: _brown,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Price tag ─────────────────────────────────────────────────────────────────
class _PriceTag extends StatelessWidget {
  final _Item item;
  const _PriceTag({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _sage,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            '${item.price}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Item card ─────────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final _Item item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _brown.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Image.asset(item.asset, fit: BoxFit.contain),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: Column(
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _brown,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 9)),
                    const SizedBox(width: 2),
                    Text(
                      '${item.price}',
                      style: TextStyle(
                        fontSize: 10,
                        color: _brown.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 22,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sage,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Buy',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
