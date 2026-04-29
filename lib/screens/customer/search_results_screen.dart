import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import '../../models/shop_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import 'product_detail.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  const SearchResultsScreen({super.key, required this.query});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResult {
  final ProductModel product;
  final ShopModel shop;
  _SearchResult({required this.product, required this.shop});
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<_SearchResult> _results = [];
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _runSearch();
  }

  Future<void> _runSearch() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final q = widget.query.toLowerCase();

      // Fetch all products across all shops (collectionGroup)
      final productsSnap = await FirebaseFirestore.instance
          .collectionGroup('products')
          .get();

      // Filter by name or description match in Dart
      final matching = productsSnap.docs.where((doc) {
        final data = doc.data();
        final name = (data['name'] as String? ?? '').toLowerCase();
        final desc = (data['description'] as String? ?? '').toLowerCase();
        return name.contains(q) || desc.contains(q);
      }).toList();

      if (matching.isEmpty) {
        setState(() {
          _results = [];
          _loading = false;
        });
        return;
      }

      // Collect unique shop IDs
      final shopIds = matching
          .map((doc) => doc.reference.parent.parent!.id)
          .toSet()
          .toList();

      // Fetch those shops in parallel
      final shopDocs = await Future.wait(
        shopIds.map(
          (id) => FirebaseFirestore.instance.collection('shops').doc(id).get(),
        ),
      );
      final shopMap = {
        for (final doc in shopDocs)
          if (doc.exists) doc.id: ShopModel.fromMap(doc.id, doc.data()!),
      };

      // Build results — keep out-of-stock products, only skip closed shops
      final results = <_SearchResult>[];
      for (final doc in matching) {
        final shopId = doc.reference.parent.parent!.id;
        final shop = shopMap[shopId];
        if (shop == null || !shop.isOpen) continue;
        results.add(_SearchResult(
          product: ProductModel.fromMap(doc.id, doc.data()),
          shop: shop,
        ));
      }

      // Sort: in-stock first, then name matches before description matches,
      // then ascending price within each group
      results.sort((a, b) {
        final aInStock = a.product.stock > 0 ? 0 : 1;
        final bInStock = b.product.stock > 0 ? 0 : 1;
        if (aInStock != bInStock) return aInStock.compareTo(bInStock);

        final aName = a.product.name.toLowerCase().contains(q) ? 0 : 1;
        final bName = b.product.name.toLowerCase().contains(q) ? 0 : 1;
        if (aName != bName) return aName.compareTo(bName);

        return a.product.price.compareTo(b.product.price);
      });

      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.walnut,
      appBar: AppBar(
        title: Text(
          '"${widget.query}"',
          style: AppTextStyles.bodyMedium.copyWith(
            fontStyle: FontStyle.italic,
            color: AppColors.cream,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.terracotta),
            )
          : _hasError
              ? _emptyState(
                  'Something went wrong.\nPlease try again.',
                  Icons.error_outline,
                )
              : _results.isEmpty
                  ? _emptyState(
                      'No products found\nfor "${widget.query}"',
                      Icons.find_in_page_outlined,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Text(
                            '${_results.length} result${_results.length == 1 ? '' : 's'}',
                            style: AppTextStyles.caption,
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 40),
                            itemCount: _results.length,
                            itemBuilder: (context, i) =>
                                _ResultCard(result: _results[i]),
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

class _ResultCard extends StatelessWidget {
  final _SearchResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final p = result.product;
    final s = result.shop;
    final outOfStock = p.stock == 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        fadeSlideRoute(ProductDetail(product: p, shop: s)),
      ),
      child: Opacity(
        opacity: outOfStock ? 0.55 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppDecorations.cardElevated,
          child: Row(
            children: [
              // ── Product image ──────────────────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(11),
                    ),
                    child: p.image.isNotEmpty
                        ? Image.network(
                            p.image,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _fallback(),
                          )
                        : _fallback(),
                  ),
                  if (outOfStock)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(11),
                        ),
                        child: ColoredBox(
                          color: AppColors.walnutDeep.withValues(alpha: 0.5),
                          child: const Center(
                            child: Text(
                              'sold\nout',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.stone,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // ── Info ───────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: outOfStock
                              ? AppColors.stone
                              : AppColors.cream,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.storefront_outlined,
                              size: 12, color: AppColors.stone),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              s.shopName,
                              style: AppTextStyles.caption
                                  .copyWith(fontStyle: FontStyle.italic),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${p.price.toStringAsFixed(0)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: outOfStock
                                  ? AppColors.stone
                                  : AppColors.saffron,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            outOfStock
                                ? 'Out of stock'
                                : '${p.stock} in stock',
                            style: AppTextStyles.caption.copyWith(
                              color: outOfStock
                                  ? Colors.red[400]
                                  : Colors.green[400],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.stone,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() => Container(
        width: 90,
        height: 90,
        color: AppColors.surface,
        child: const Center(
          child: Text(
            '✦',
            style: TextStyle(color: AppColors.stone, fontSize: 22),
          ),
        ),
      );
}
