import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/listing.dart';

typedef OpenConversationCallback = Future<void> Function(
  String conversationId,
  String sellerName,
);

class ItemDetailPage extends StatefulWidget {
  const ItemDetailPage({
    super.key,
    required this.listing,
    required this.onOpenConversation,
  });

  final Listing listing;
  final OpenConversationCallback onOpenConversation;

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  bool _isOpeningConversation = false;

  Future<void> _messageSeller() async {
    if (_isOpeningConversation) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final listing = widget.listing;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to send a message.'),
        ),
      );

      return;
    }

    if (currentUser.uid == listing.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot message your own listing.'),
        ),
      );

      return;
    }

    setState(() {
      _isOpeningConversation = true;
    });

    try {
      final participantIds = [
        currentUser.uid,
        listing.sellerId,
      ]..sort();

      /*
       * Including the listing ID gives these two users a separate
       * conversation for each marketplace listing.
       */
      final conversationId =
          '${listing.id}_${participantIds.join('_')}';

      final conversationReference = FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId);

      await conversationReference.set(
        {
          'participantIds': participantIds,
          'participantEmails': [
            currentUser.email ?? '',
            listing.sellerEmail,
          ],
          'listingId': listing.id,
          'listingTitle': listing.title,
          'listingImageUrl': listing.imageUrl,
          'sellerId': listing.sellerId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      /*
       * Close the listing details first. This exposes MainShell,
       * which then selects Messages and opens the chat.
       */
      Navigator.pop(context);

      await widget.onOpenConversation(
        conversationId,
        listing.sellerName,
      );
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'Could not open the conversation.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningConversation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final currentUser = FirebaseAuth.instance.currentUser;

    final isOwnListing =
        currentUser?.uid == listing.sellerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(listing.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: listing.imageUrl.isEmpty
                  ? const ColoredBox(
                      color: Color(0xFFE5E5E5),
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 80,
                        ),
                      ),
                    )
                  : Image.network(
                      listing.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const ColoredBox(
                          color: Color(0xFFE5E5E5),
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 80,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            listing.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),

          const SizedBox(height: 8),

          Text(
            '\$${listing.price.toStringAsFixed(2)}',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            listing.category,
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const Divider(height: 40),

          Text(
            'Description',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 8),

          Text(
            listing.description.isEmpty
                ? 'No description provided.'
                : listing.description,
          ),

          const Divider(height: 40),

          Text(
            'Seller',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 8),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(listing.sellerName),
            subtitle: Text(listing.sellerEmail),
          ),

          const SizedBox(height: 24),

          if (!isOwnListing)
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _isOpeningConversation
                    ? null
                    : _messageSeller,
                icon: _isOpeningConversation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.chat_bubble_outline),
                label: Text(
                  _isOpeningConversation
                      ? 'Opening Conversation...'
                      : 'Message Seller',
                ),
              ),
            ),

          if (isOwnListing)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined),
                  SizedBox(width: 8),
                  Text('This is your listing.'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}