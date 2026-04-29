import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

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
        SnackBar(
          content: const Text('Please select a star rating'),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.terracotta),
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final user = FirebaseAuth.instance.currentUser!;

    final userDoc = await FirebaseFirestore.instance
        .collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? user.email ?? 'Customer';

    final firestore = FirebaseFirestore.instance;

    await firestore.collection('reviews').add({
      'shopId': widget.shopId,
      'orderId': widget.orderId,
      'userId': user.uid,
      'userName': userName,
      'rating': _rating,
      'comment': _commentCtrl.text.trim(),
      'createdAt': Timestamp.now(),
    });

    final reviewsSnap = await firestore
        .collection('reviews')
        .where('shopId', isEqualTo: widget.shopId)
        .get();

    if (reviewsSnap.docs.isNotEmpty) {
      final totalRating = reviewsSnap.docs
          .fold<double>(0, (acc, doc) => acc + ((doc['rating'] ?? 0) as num).toDouble());
      final avgRating = totalRating / reviewsSnap.docs.length;

      await firestore.collection('shops').doc(widget.shopId).update({
        'rating': double.parse(avgRating.toStringAsFixed(1)),
        'totalReviews': reviewsSnap.docs.length,
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Thank you for your review!'),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.walnut,
      appBar: AppBar(
        title: const Text('Write a Review'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.shopName, style: AppTextStyles.displayMedium),
            const SizedBox(height: 4),
            Text(
              'Share your experience with other customers',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.stone, fontStyle: FontStyle.italic),
            ),

            const SizedBox(height: 32),

            // ── Ornamental divider ─────────────────────────────────────────
            Row(children: [
              Expanded(child: Container(height: 1, color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('✦', style: AppTextStyles.caption),
              ),
              Expanded(child: Container(height: 1, color: AppColors.border)),
            ]),

            const SizedBox(height: 28),

            // ── Star selector ──────────────────────────────────────────────
            Text('Your Rating',
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      _rating >= star
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 44,
                      color: _rating >= star
                          ? AppColors.terracotta
                          : AppColors.surface,
                    ),
                  ),
                );
              }),
            ),
            if (_rating > 0) ...[
              const SizedBox(height: 8),
              Text(
                ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][_rating],
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.terracottaLight, fontWeight: FontWeight.w600),
              ),
            ],

            const SizedBox(height: 28),

            // ── Comment field ──────────────────────────────────────────────
            Text('Your Comment (optional)',
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _commentCtrl,
              maxLines: 4,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.cream),
              decoration: InputDecoration(
                hintText: 'What did you love? What could be better?',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.stone, fontSize: 15),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.terracotta),
                ),
              ),
            ),

            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.terracotta,
                  disabledBackgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.cream, strokeWidth: 2),
                      )
                    : Text('Submit Review',
                        style: AppTextStyles.button.copyWith(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
