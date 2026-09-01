import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/listing.dart';
import 'item_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GryphMarket'), actions: [
        IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Filters are coming next.'))), icon: const Icon(Icons.tune), tooltip: 'Filters'),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SearchBar(
            controller: _search,
            hintText: 'Search listings',
            leading: const Icon(Icons.search),
            trailing: [if (_query.isNotEmpty) IconButton(onPressed: () { _search.clear(); setState(() => _query = ''); }, icon: const Icon(Icons.close))],
            onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('listings').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Could not load listings: ${snapshot.error}'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final listings = snapshot.data!.docs.map(Listing.fromDoc).where((item) => _query.isEmpty || item.title.toLowerCase().contains(_query) || item.category.toLowerCase().contains(_query)).toList();
              if (listings.isEmpty) return const Center(child: Text('No listings found.'));
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 320, childAspectRatio: .78, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: listings.length,
                itemBuilder: (context, index) => _ListingCard(listing: listings[index]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing});
  final Listing listing;
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailPage(listing: listing))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: listing.imageUrl.isEmpty
              ? const ColoredBox(color: Color(0xFFE8E8E8), child: Center(child: Icon(Icons.image_outlined, size: 56)))
              : Image.network(listing.imageUrl, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, size: 48)))),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('\$${listing.price.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(listing.category, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ]),
      ),
    );
  }
}
