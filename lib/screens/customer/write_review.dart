import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WriteReview extends StatefulWidget {
  final String orderId;
  final String shopId;
  final String shopName;

  const WriteReview({
    super.key,
    required this.orderId,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<WriteReview> createState() => _WriteReviewState();
}

class _WriteReviewState extends State<WriteReview> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a star rating'),
          backgroundColor: Color(0xFFB5603A),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final user = FirebaseAuth.instance.currentUser!;

    // Fetch user display name from Firestore
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? user.email ?? 'Customer';

    final firestore = FirebaseFirestore.instance;

    // Write review doc
    await firestore.collection('reviews').add({
      'shopId': widget.shopId,
      'orderId': widget.orderId,
      'userId': user.uid,
      'userName': userName,
      'rating': _rating,
      'comment': _commentCtrl.text.trim(),
      'createdAt': Timestamp.now(),
    });

    // Recalculate shop rating
    final reviewsSnap = await firestore
        .collection('reviews')
        .where('shopId', isEqualTo: widget.shopId)
        .get();

    if (reviewsSnap.docs.isNotEmpty) {
      final totalRating = reviewsSnap.docs
          .fold<double>(0, (sum, doc) => sum + ((doc['rating'] ?? 0) as num).toDouble());
      final avgRating = totalRating / reviewsSnap.docs.length;

      await firestore.collection('shops').doc(widget.shopId).update({
        'rating': double.parse(avgRating.toStringAsFixed(1)),
        'totalReviews': reviewsSnap.docs.length,
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your review!'),
          backgroundColor: Color(0xFF3D2B1F),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      appBar: AppBar(
        title: const Text('Write a Review'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.shopName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D2B1F),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Share your experience with other customers',
              style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),

            const SizedBox(height: 28),

            // Star selector
            const Text(
              'Your Rating',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF3D2B1F)),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      _rating >= star ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 44,
                      color: _rating >= star ? const Color(0xFFC9A55A) : const Color(0xFFCCBBA0),
                    ),
                  ),
                );
              }),
            ),
            if (_rating > 0) ...[
              const SizedBox(height: 8),
              Text(
                ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][_rating],
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFC8821A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Comment field
            const Text(
              'Your Comment (optional)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF3D2B1F)),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _commentCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'What did you love? What could be better?',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Submit Review', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
