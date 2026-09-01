import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/listing.dart';
import 'chat_page.dart';

class ItemDetailPage extends StatefulWidget {
  const ItemDetailPage({super.key, required this.listing});
  final Listing listing;
  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  bool _opening = false;

  Future<void> _contactSeller() async {
    if (_opening) return;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null || current.uid == widget.listing.sellerId) return;
    setState(() => _opening = true);
    try {
      final ids = [current.uid, widget.listing.sellerId]..sort();
      final conversationId = '${widget.listing.id}_${ids.join('_')}';
      final ref = FirebaseFirestore.instance.collection('conversations').doc(conversationId);
      await ref.set({
        'participantIds': ids,
        'participantEmails': [current.email, widget.listing.sellerEmail],
        'listingId': widget.listing.id,
        'listingTitle': widget.listing.title,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(conversationId: conversationId, title: widget.listing.sellerName)));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.listing;
    final isOwner = FirebaseAuth.instance.currentUser?.uid == item.sellerId;
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        AspectRatio(aspectRatio: 16 / 10, child: item.imageUrl.isEmpty ? const ColoredBox(color: Color(0xFFE8E8E8), child: Icon(Icons.image_outlined, size: 80)) : Image.network(item.imageUrl, fit: BoxFit.cover)),
        const SizedBox(height: 20),
        Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
        Text('\$${item.price.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(item.description),
        const SizedBox(height: 20),
        Text('Sold by ${item.sellerName}', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 20),
        if (!isOwner) FilledButton.icon(onPressed: _opening ? null : _contactSeller, icon: const Icon(Icons.chat), label: Text(_opening ? 'Opening...' : 'Message seller')),
        if (isOwner) const Text('This is your listing.', textAlign: TextAlign.center),
      ]),
    );
  }
}
