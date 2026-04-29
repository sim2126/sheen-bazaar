import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  Future<List<CategoryModel>>
  getCategories() async {
    final snapshot = await _db
        .collection('categories')
        .orderBy('sortOrder')
        .get();

    return snapshot.docs
        .where((doc) => doc.id != 'sculptures')
        .map(
          (doc) => CategoryModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }
}
