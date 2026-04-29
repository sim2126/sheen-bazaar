import 'package:cloud_functions/cloud_functions.dart';

/// Triggers the `seedCategories` Cloud Function, which runs with Firebase Admin
/// privileges and therefore bypasses Firestore security rules.
/// Returns the number of categories written.
class CategorySeeder {
  static Future<int> seed() async {
    final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
        .httpsCallable('seedCategories');
    final result = await callable.call();
    return (result.data['count'] as num).toInt();
  }
}
