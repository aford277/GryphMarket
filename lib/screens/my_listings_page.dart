import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'sell_item_page.dart';
import 'owner_listing_detail_page.dart';

enum ListingView {
  active,
  sold,
}

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  ListingView _selectedView = ListingView.active;

  Future<void> _openCreateListingPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SellItemPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Listings'),
      ),
      body: currentUser == null
          ? const Center(
              child: Text('You must be logged in to view your listings.'),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _openCreateListingPage,
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Listing'),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ListingView>(
                      segments: const [
                        ButtonSegment<ListingView>(
                          value: ListingView.active,
                          label: Text('Active'),
                          icon: Icon(Icons.inventory_2_outlined),
                        ),
                        ButtonSegment<ListingView>(
                          value: ListingView.sold,
                          label: Text('Sold'),
                          icon: Icon(Icons.check_circle_outline),
                        ),
                      ],
                      selected: {_selectedView},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) {
                        setState(() {
                          _selectedView = selection.first;
                        });
                      },
                    ),
                  ),
                ),

                Expanded(
                  child: StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('listings')
                        .where(
                          'sellerId',
                          isEqualTo: currentUser.uid,
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Could not load listings:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final wantedStatus =
                          _selectedView == ListingView.active
                              ? 'active'
                              : 'sold';

                      final listings = snapshot.data!.docs.where((document) {
                        final data = document.data();

                        // Older listings without a status are treated as active.
                        final status =
                            data['status'] as String? ?? 'active';

                        return status == wantedStatus;
                      }).toList();

                      listings.sort((first, second) {
                        final firstDate =
                            first.data()['createdAt'] as Timestamp?;
                        final secondDate =
                            second.data()['createdAt'] as Timestamp?;

                        return (secondDate?.millisecondsSinceEpoch ?? 0)
                            .compareTo(
                          firstDate?.millisecondsSinceEpoch ?? 0,
                        );
                      });

                      if (listings.isEmpty) {
                        return _EmptyListingsMessage(
                          selectedView: _selectedView,
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: listings.length,
                        itemBuilder: (context, index) {
                          final document = listings[index];
                          final listing = document.data();

                          return _ListingCard(
                            listingId: document.id,
                            listing: listing,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.listingId,
    required this.listing,
  });

  final String listingId;
  final Map<String, dynamic> listing;

  @override
  Widget build(BuildContext context) {
    final title = listing['title'] as String? ?? 'Untitled listing';
    final category = listing['category'] as String? ?? 'Other';
    final imageUrl = listing['imageUrl'] as String? ?? '';
    final priceValue = listing['price'];

    final price = priceValue is num
        ? priceValue.toDouble()
        : double.tryParse(priceValue?.toString() ?? '') ?? 0;

     return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OwnerListingDetailPage(
                listingId: listingId,
              ),
            ),
          );
        },
        child: Row(
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: imageUrl.isEmpty
                  ? const ColoredBox(
                      color: Color(0xFFE5E5E5),
                      child: Icon(
                        Icons.image_outlined,
                        size: 42,
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const ColoredBox(
                          color: Color(0xFFE5E5E5),
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 42,
                          ),
                        );
                      },
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(category),
                    const SizedBox(height: 8),
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyListingsMessage extends StatelessWidget {
  const _EmptyListingsMessage({
    required this.selectedView,
  });

  final ListingView selectedView;

  @override
  Widget build(BuildContext context) {
    final showingActive = selectedView == ListingView.active;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showingActive
                  ? Icons.inventory_2_outlined
                  : Icons.check_circle_outline,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              showingActive
                  ? 'You have no active listings.'
                  : 'You have no sold listings.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}