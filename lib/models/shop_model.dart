import 'package:cloud_firestore/cloud_firestore.dart';

class ShopModel {
  final String id;
  final String shopName;
  final String description;
  final String categoryId;
  final String ownerId;
  final String coverImage;
  final String logo;
  final String location;
  final bool isOpen;
  final bool isVerified;
  final double rating;
  final int totalReviews;
  final Timestamp createdAt;

  ShopModel({
    required this.id,
    required this.shopName,
    required this.description,
    required this.categoryId,
    required this.ownerId,
    required this.coverImage,
    required this.logo,
    required this.location,
    required this.isOpen,
    this.isVerified = false,
    required this.rating,
    required this.totalReviews,
    required this.createdAt,
  });

  factory ShopModel.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return ShopModel(
      id: id,
      shopName: data['shopName'] ?? '',
      description: data['description'] ?? '',
      categoryId: data['categoryId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      coverImage: data['coverImage'] ?? '',
      logo: data['logo'] ?? '',
      location: data['location'] ?? '',
      isOpen: data['isOpen'] ?? false,
      isVerified: data['isVerified'] ?? false,
      rating: (data['rating'] ?? 0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
