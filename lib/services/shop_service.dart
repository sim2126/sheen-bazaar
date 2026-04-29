import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_model.dart';
import '../models/product_model.dart';

class ShopService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch shops that have at least one in-stock product in the given category
  Future<List<ShopModel>> getShopsByCategory(String categoryId) async {
    // Query products across all shops in this category
    final productsSnap = await _db
        .collectionGroup('products')
        .where('categoryId', isEqualTo: categoryId)
        .get();

    // Extract unique shopIds from products that have stock
    final shopIds = productsSnap.docs
        .where((doc) => (doc.data()['stock'] as num? ?? 0) > 0)
        .map((doc) => doc.reference.parent.parent!.id)
        .toSet();

    if (shopIds.isEmpty) return [];

    // Fetch each shop and filter to open ones only
    final shopDocs = await Future.wait(
      shopIds.map((id) => _db.collection('shops').doc(id).get()),
    );

    return shopDocs
        .where((doc) =>
            doc.exists && (doc.data()!['isOpen'] as bool? ?? false))
        .map((doc) => ShopModel.fromMap(doc.id, doc.data()!))
        .toList();
  }

  // Fetch products subcollection inside a shop
  Future<List<ProductModel>> getProducts(String shopId) async {
    final snapshot = await _db
        .collection('shops')
        .doc(shopId)
        .collection('products')
        .get();

    return snapshot.docs
        .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
        .toList();
  }
}