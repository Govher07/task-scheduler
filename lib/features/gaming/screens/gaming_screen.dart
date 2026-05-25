import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

// ── Shared colors ─────────────────────────────────────────────────────────────
const _brown = Color(0xFF5C3D11);
const _sage = Color(0xFF7A9E5A);
const _gold = Color(0xFFF5C842);
const _cardBg = Color(0xFFF5EDD8);

// ── Item data ─────────────────────────────────────────────────────────────────
enum _Cat { all, animals, decor, plants, characters }

class _Item {
  final String id, asset, name;
  final int price;
  final _Cat cat;
  final String? desc;
  const _Item(this.id, this.asset, this.name, this.price,
      {required this.cat, this.desc});
}

_Cat _catFromString(String s) => switch (s) {
  'animals'    => _Cat.animals,
  'plants'     => _Cat.plants,
  'decor'      => _Cat.decor,
  'characters' => _Cat.characters,
  _            => _Cat.all,
};

_Item _itemFromRow(Map<String, dynamic> r) => _Item(
  r['id'] as String,
  r['asset_path'] as String,
  r['name'] as String,
  r['price'] as int,
  cat: _catFromString(r['category'] as String),
  desc: r['description'] as String?,
);

// ── GamingScreen ──────────────────────────────────────────────────────────────
class GamingScreen extends ConsumerStatefulWidget {
  const GamingScreen({super.key});

  @override
  ConsumerState<GamingScreen> createState() => _GamingScreenState();
}

class _GamingScreenState extends ConsumerState<GamingScreen> {
  Map<String, _Item?> _slots = {
    'animals': null, 'plants': null, 'decor': null, 'characters': null,
  };

  // Positions as fractions of screen (dx, dy from center: -1=edge, 0=center, 1=edge)
  static const _slotAlignments = {
    'plants':     Alignment(-1.10, -0.10),
    'decor':      Alignment(-0.80,  0.20),
    'characters': Alignment( 0.65,  -0.05),
    'animals':    Alignment( -0.10,  0.70),
  };

  static const _slotSizes = {
    'plants': 130.0, 'decor': 160.0, 'characters': 200.0, 'animals': 160.0,
  };

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    final data = await ref.read(rewardServiceProvider).getRoomSlots();
    if (mounted) {
      setState(() {
        _slots = data.map((k, v) => MapEntry(k, v != null ? _itemFromRow(v) : null));
      });
    }
  }

  Future<void> _openSlotPicker(String slotType) async {
    final ownedRows = await ref.read(rewardServiceProvider).getOwnedItems();
    final ownedOfType = ownedRows
        .map(_itemFromRow)
        .where((i) => i.cat == _catFromString(slotType))
        .toList();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SlotPickerSheet(
        slotType: slotType,
        items: ownedOfType,
        currentItem: _slots[slotType],
        onSelect: (item) async {
          Navigator.pop(ctx);
          try {
            await ref.read(rewardServiceProvider).setRoomSlot(slotType, item?.id);
            await _loadSlots();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

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
          // Room decoration slots
          ..._slotAlignments.entries.map((entry) {
            final slotType = entry.key;
            final item = _slots[slotType];
            final size = _slotSizes[slotType]!;
            return Align(
              alignment: entry.value,
              child: GestureDetector(
                onTap: () => _openSlotPicker(slotType),
                child: item != null
                    ? Image.asset(item.asset, width: size, height: size, fit: BoxFit.contain)
                    : _EmptySlot(size: size),
              ),
            );
          }),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _openBackpack(context),
                      icon: const Text('🎒', style: TextStyle(fontSize: 22)),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _openShop(context),
                      icon: const Icon(Icons.store_rounded, size: 26),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
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
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _ShopPage()),
    );
  }

  void _openBackpack(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _BackpackPage()),
    );
  }
}

// ── Empty slot indicator ───────────────────────────────────────────────────────
class _EmptySlot extends StatelessWidget {
  final double size;
  const _EmptySlot({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Icon(Icons.add, color: Colors.white.withValues(alpha: 0.5), size: size * 0.35),
    );
  }
}

// ── Slot picker bottom sheet ───────────────────────────────────────────────────
class _SlotPickerSheet extends StatelessWidget {
  final String slotType;
  final List<_Item> items;
  final _Item? currentItem;
  final void Function(_Item? item) onSelect;

  const _SlotPickerSheet({
    required this.slotType,
    required this.items,
    required this.currentItem,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final label = slotType[0].toUpperCase() + slotType.substring(1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Place $label',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _brown),
              ),
              const Spacer(),
              if (currentItem != null)
                TextButton.icon(
                  onPressed: () => onSelect(null),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No $slotType owned yet.\nBuy some from the shop!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _brown.withValues(alpha: 0.6)),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.85,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final isSelected = currentItem?.id == item.id;
                return GestureDetector(
                  onTap: () => onSelect(item),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? _sage.withValues(alpha: 0.2) : _cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? _sage : _brown.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(item.asset, fit: BoxFit.contain),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            item.name,
                            style: TextStyle(fontSize: 9, color: _brown, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Shop page ─────────────────────────────────────────────────────────────────
class _ShopPage extends ConsumerStatefulWidget {
  const _ShopPage();

  @override
  ConsumerState<_ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<_ShopPage> {
  _Cat _cat = _Cat.all;
  int _featuredIdx = 0;
  final _pageCtrl = PageController();
  int _balance = 0;
  List<_Item> _items = [];
  List<_Item> _featured = [];
  Set<String> _ownedIds = {};

  List<_Item> get _filtered {
    final base = _cat == _Cat.all
        ? _items
        : _items.where((i) => i.cat == _cat).toList();
    return base.where((i) => !_ownedIds.contains(i.id)).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final svc = ref.read(rewardServiceProvider);
    final results = await Future.wait([
      svc.getBalance(),
      svc.getShopItems(),
      svc.getOwnedItems(),
    ]);
    if (mounted) {
      final allItems = (results[1] as List<Map<String, dynamic>>)
          .map(_itemFromRow)
          .toList();
      final ownedIds = (results[2] as List<Map<String, dynamic>>)
          .map((r) => r['id'] as String)
          .toSet();
      setState(() {
        _balance = results[0] as int;
        _items = allItems;
        _featured = allItems.where((i) => i.desc != null).toList();
        _ownedIds = ownedIds;
      });
    }
  }

  Future<void> _buyItem(_Item item) async {
    if (_balance < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins!')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Buy ${item.name}?'),
        content: Text('This will cost 🪙 ${item.price} coins.\nYour balance: 🪙 $_balance'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Buy')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(rewardServiceProvider).purchaseItem(item.id, item.price);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} purchased!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    }
  }

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
        _CurrencyChip(amount: '$_balance'),
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
            itemCount: _featured.length,
            onPageChanged: (i) => setState(() => _featuredIdx = i),
            itemBuilder: (_, i) {
              final item = _featured[i];
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
                _featured.length,
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
      itemBuilder: (_, i) => _ItemCard(item: items[i], onBuy: () => _buyItem(items[i])),
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
  final VoidCallback onBuy;
  const _ItemCard({required this.item, required this.onBuy});

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
                    onPressed: onBuy,
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

// ── Backpack page ─────────────────────────────────────────────────────────────
class _BackpackPage extends ConsumerStatefulWidget {
  const _BackpackPage();

  @override
  ConsumerState<_BackpackPage> createState() => _BackpackPageState();
}

class _BackpackPageState extends ConsumerState<_BackpackPage> {
  List<_Item> _ownedItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final rows = await ref.read(rewardServiceProvider).getOwnedItems();
    if (mounted) {
      setState(() {
        _ownedItems = rows.map(_itemFromRow).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownedItems = _ownedItems;

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
                  Row(
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
                              Text('🎒', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 6),
                              Text(
                                'Backpack',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _brown),
                              ),
                              SizedBox(width: 6),
                              Text('🎒', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else if (ownedItems.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎒', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              'Your backpack is empty',
                              style: TextStyle(color: _brown.withValues(alpha: 0.7), fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Buy items from the shop!',
                              style: TextStyle(color: _brown.withValues(alpha: 0.5), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: ownedItems.length,
                        itemBuilder: (_, i) => _BackpackItemCard(item: ownedItems[i]),
                      ),
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

class _BackpackItemCard extends StatelessWidget {
  final _Item item;
  const _BackpackItemCard({required this.item});

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
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Column(
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 10, color: _brown, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _sage.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _sage.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'Owned',
                    style: TextStyle(fontSize: 9, color: _sage, fontWeight: FontWeight.bold),
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
