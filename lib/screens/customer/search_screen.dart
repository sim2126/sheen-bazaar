import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import '../../models/shop_model.dart';
import '../../utils/transitions.dart';
import '../../theme/app_theme.dart';
import 'product_detail.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _selectedCategory = 'all';
  double _currentMaxPrice = 50000;
  List<_SearchResult> _results = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return;
    setState(() { _query = q; _loading = true; _searched = true; _results = []; });

    try {
      Query shopsQuery = FirebaseFirestore.instance
          .collection('shops')
          .where('isOpen', isEqualTo: true);
      if (_selectedCategory != 'all') {
        shopsQuery = shopsQuery.where('categoryId', isEqualTo: _selectedCategory);
      }
      final shopsSnap = await shopsQuery.get();
      final results = <_SearchResult>[];

      for (final shopDoc in shopsSnap.docs) {
        final shop = ShopModel.fromMap(shopDoc.id, shopDoc.data() as Map<String, dynamic>);
        final productsSnap = await FirebaseFirestore.instance
            .collection('shops').doc(shopDoc.id).collection('products').get();
        for (final pd in productsSnap.docs) {
          final product = ProductModel.fromMap(pd.id, pd.data());
          final nameMatch = product.name.toLowerCase().contains(q);
          final descMatch = product.description.toLowerCase().contains(q);
          if ((nameMatch || descMatch) && product.price <= _currentMaxPrice) {
            results.add(_SearchResult(product: product, shop: shop));
          }
        }
      }
      results.sort((a, b) {
        final aName = a.product.name.toLowerCase().contains(q) ? 0 : 1;
        final bName = b.product.name.toLowerCase().contains(q) ? 0 : 1;
        if (aName != bName) return aName.compareTo(bName);
        return a.product.price.compareTo(b.product.price);
      });
      setState(() { _results = results; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.walnut,
      appBar: AppBar(
        title: const Text('Search'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── Search bar + filters ─────────────────────────────────────
          Container(
            color: AppColors.walnutDeep,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        onSubmitted: (_) => _search(),
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Search Pashmina, Papier Mache, Wood...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.terracotta, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _search,
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: const BoxDecoration(
                          color: AppColors.terracotta,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.search, color: AppColors.cream, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: 'All', selected: _selectedCategory == 'all',
                          onTap: () => setState(() => _selectedCategory = 'all')),
                      _FilterChip(label: 'Pashmina', selected: _selectedCategory == 'pashmina',
                          onTap: () => setState(() => _selectedCategory = 'pashmina')),
                      _FilterChip(label: 'Papier Mache', selected: _selectedCategory == 'papier_mache',
                          onTap: () => setState(() => _selectedCategory = 'papier_mache')),
                      _FilterChip(label: 'Walnut Wood', selected: _selectedCategory == 'wood',
                          onTap: () => setState(() => _selectedCategory = 'wood')),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('Max Price:', style: AppTextStyles.caption),
                    const SizedBox(width: 8),
                    Text(
                      '₹${_currentMaxPrice.toInt()}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.terracottaLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.terracotta,
                          inactiveTrackColor: AppColors.surface,
                          thumbColor: AppColors.terracottaLight,
                          overlayColor: AppColors.terracotta.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: _currentMaxPrice,
                          min: 500,
                          max: 50000,
                          divisions: 99,
                          onChanged: (v) => setState(() => _currentMaxPrice = v),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Results ──────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
                : !_searched
                    ? _emptyState('Search for authentic\nKashmiri handicrafts', Icons.search_outlined)
                    : _results.isEmpty
                        ? _emptyState('No products found for "$_query"', Icons.find_in_page_outlined)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length,
                            itemBuilder: (context, index) =>
                                _SearchResultCard(result: _results[index]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52, color: AppColors.stone),
          const SizedBox(height: 16),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.stone,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.terracotta : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.terracotta : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? AppColors.cream : AppColors.stone,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SearchResult {
  final ProductModel product;
  final ShopModel shop;
  _SearchResult({required this.product, required this.shop});
}

class _SearchResultCard extends StatelessWidget {
  final _SearchResult result;
  const _SearchResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final p = result.product;
    final s = result.shop;
    return GestureDetector(
      onTap: () => Navigator.push(context, fadeSlideRoute(ProductDetail(product: p, shop: s))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppDecorations.cardElevated,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
              child: p.image.isNotEmpty
                  ? Image.network(p.image, width: 90, height: 90, fit: BoxFit.cover,
                      errorBuilder: (context, err, stack) => _fallback())
                  : _fallback(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600, color: AppColors.cream),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(s.shopName,
                        style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₹${p.price.toStringAsFixed(0)}',
                            style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700, color: AppColors.saffron, fontSize: 15)),
                        Text(p.stock > 0 ? '${p.stock} in stock' : 'Out of stock',
                            style: AppTextStyles.caption.copyWith(
                                color: p.stock > 0 ? Colors.green[400] : Colors.red[400])),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() => Container(
    width: 90, height: 90, color: AppColors.surface,
    child: const Center(child: Text('✦', style: TextStyle(color: AppColors.stone, fontSize: 20))),
  );
}
