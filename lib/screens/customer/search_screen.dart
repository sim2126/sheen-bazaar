import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import '../../models/shop_model.dart';
import '../../utils/transitions.dart';
import 'product_detail.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  // Filter state
  String _selectedCategory = 'all';
  double _maxPrice = 50000;
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
      // Fetch all open shops (filtered by category if set)
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
            .collection('shops')
            .doc(shopDoc.id)
            .collection('products')
            .get();

        for (final pd in productsSnap.docs) {
          final product = ProductModel.fromMap(pd.id, pd.data());
          final nameMatch = product.name.toLowerCase().contains(q);
          final descMatch = product.description.toLowerCase().contains(q);
          final priceMatch = product.price <= _currentMaxPrice;
          if ((nameMatch || descMatch) && priceMatch) {
            results.add(_SearchResult(product: product, shop: shop));
          }
        }
      }

      // Sort: name matches first, then by price ascending
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
      backgroundColor: const Color(0xFFF5EDE0),
      appBar: AppBar(
        title: const Text('Search Products'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar + filter strip
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          hintText: 'Search Pashmina, Papier Mache, Wood...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFFC8821A)),
                          filled: true,
                          fillColor: const Color(0xFFF5EDE0),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _search,
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: const BoxDecoration(
                          color: Color(0xFF3D2B1F),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.search, color: Color(0xFFC9A55A), size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Category filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: 'All', value: 'all', selected: _selectedCategory == 'all',
                          onTap: () => setState(() => _selectedCategory = 'all')),
                      _FilterChip(label: 'Pashmina', value: 'pashmina', selected: _selectedCategory == 'pashmina',
                          onTap: () => setState(() => _selectedCategory = 'pashmina')),
                      _FilterChip(label: 'Papier Mache', value: 'papier_mache', selected: _selectedCategory == 'papier_mache',
                          onTap: () => setState(() => _selectedCategory = 'papier_mache')),
                      _FilterChip(label: 'Walnut Wood', value: 'wood', selected: _selectedCategory == 'wood',
                          onTap: () => setState(() => _selectedCategory = 'wood')),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Price filter
                Row(
                  children: [
                    const Text('Max Price:', style: TextStyle(fontSize: 12, color: Color(0xFF3D2B1F), fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Text('₹${_currentMaxPrice.toInt()}', style: const TextStyle(fontSize: 12, color: Color(0xFFC8821A), fontWeight: FontWeight.w700)),
                    Expanded(
                      child: Slider(
                        value: _currentMaxPrice,
                        min: 500,
                        max: 50000,
                        divisions: 99,
                        activeColor: const Color(0xFFC9A55A),
                        inactiveColor: const Color(0xFFE0D0BC),
                        onChanged: (v) => setState(() => _currentMaxPrice = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC8821A)))
                : !_searched
                    ? _emptyState('Search for authentic Kashmiri handicrafts', Icons.search)
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
          Icon(icon, size: 60, color: const Color(0xFFCCBBA0)),
          const SizedBox(height: 16),
          Text(msg, textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, height: 1.5)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3D2B1F) : const Color(0xFFF5EDE0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF3D2B1F) : const Color(0xFFCCBBA0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFFF5EDE0) : const Color(0xFF3D2B1F),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: const Color(0xFF3D2B1F).withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              child: p.image.isNotEmpty
                  ? Image.network(p.image, width: 90, height: 90, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback())
                  : _fallback(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF3D2B1F)),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(s.shopName,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8FA8A0), fontStyle: FontStyle.italic)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₹${p.price.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFB5603A))),
                        Text(p.stock > 0 ? '${p.stock} in stock' : 'Out of stock',
                            style: TextStyle(fontSize: 11, color: p.stock > 0 ? Colors.green[600] : Colors.red[400])),
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
    width: 90, height: 90, color: const Color(0xFFEDE0CC),
    child: Center(child: Image.asset('assets/images/wicker_basket.png', height: 36, color: const Color(0x333D2B1F))),
  );
}
