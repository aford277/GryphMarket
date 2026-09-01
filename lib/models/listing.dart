import 'package:cloud_firestore/cloud_firestore.dart';

class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.sellerId,
    required this.sellerName,
    required this.sellerEmail,
    this.imageUrl = '',
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String sellerId;
  final String sellerName;
  final String sellerEmail;
  final String imageUrl;

  factory Listing.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Listing(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num? ?? 0).toDouble(),
      category: data['category'] as String? ?? 'Other',
      sellerId: data['sellerId'] as String? ?? '',
      sellerName: data['sellerName'] as String? ?? 'Student',
      sellerEmail: data['sellerEmail'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
    );
  }
}
