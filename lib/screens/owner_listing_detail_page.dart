import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OwnerListingDetailPage extends StatelessWidget {
  const OwnerListingDetailPage({
    super.key,
    required this.listingId,
  });

  final String listingId;

  DocumentReference<Map<String, dynamic>> get _listingReference {
    return FirebaseFirestore.instance
        .collection('listings')
        .doc(listingId);
  }

  Future<void> _openEditPage(
    BuildContext context,
    Map<String, dynamic> listing,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditListingPage(
          listingId: listingId,
          listing: listing,
        ),
      ),
    );
  }

  Future<void> _changeListingStatus(
    BuildContext context,
    String currentStatus,
  ) async {
    final markingAsSold = currentStatus != 'sold';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            markingAsSold
                ? 'Mark listing as sold?'
                : 'Reactivate listing?',
          ),
          content: Text(
            markingAsSold
                ? 'This listing will move from Active to Sold.'
                : 'This listing will move from Sold back to Active.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(
                markingAsSold ? 'Mark as Sold' : 'Reactivate',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _listingReference.update({
        'status': markingAsSold ? 'sold' : 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            markingAsSold
                ? 'Listing marked as sold.'
                : 'Listing reactivated.',
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'Could not update the listing.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _listingReference.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                'Could not load listing:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('This listing no longer exists.'),
            ),
          );
        }

        final listing = snapshot.data!.data()!;
        final sellerId = listing['sellerId'] as String? ?? '';

        if (currentUser == null || currentUser.uid != sellerId) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text(
                'You do not have permission to manage this listing.',
              ),
            ),
          );
        }

        final title =
            listing['title'] as String? ?? 'Untitled listing';

        final description =
            listing['description'] as String? ?? '';

        final category =
            listing['category'] as String? ?? 'Other';

        final imageUrl =
            listing['imageUrl'] as String? ?? '';

        final sellerName =
            listing['sellerName'] as String? ?? 'Student';

        final status =
            listing['status'] as String? ?? 'active';

        final priceValue = listing['price'];

        final price = priceValue is num
            ? priceValue.toDouble()
            : double.tryParse(priceValue?.toString() ?? '') ?? 0;

        final isSold = status == 'sold';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Your Listing'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: imageUrl.isEmpty
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
                          imageUrl,
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

              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style:
                          Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Chip(
                    avatar: Icon(
                      isSold
                          ? Icons.check_circle
                          : Icons.inventory_2,
                      size: 18,
                    ),
                    label: Text(
                      isSold ? 'Sold' : 'Active',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                '\$${price.toStringAsFixed(2)}',
                style:
                    Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
              ),

              const SizedBox(height: 8),

              Text(
                category,
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const Divider(height: 40),

              Text(
                'Description',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 8),

              Text(
                description.isEmpty
                    ? 'No description provided.'
                    : description,
              ),

              const Divider(height: 40),

              Text(
                'Seller',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 8),

              Text(sellerName),

              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: () {
                  _openEditPage(context, listing);
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Listing'),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {
                  _changeListingStatus(context, status);
                },
                icon: Icon(
                  isSold
                      ? Icons.refresh
                      : Icons.check_circle_outline,
                ),
                label: Text(
                  isSold
                      ? 'Move Back to Active'
                      : 'Mark as Sold',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class EditListingPage extends StatefulWidget {
  const EditListingPage({
    super.key,
    required this.listingId,
    required this.listing,
  });

  final String listingId;
  final Map<String, dynamic> listing;

  @override
  State<EditListingPage> createState() =>
      _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageUrlController;

  final List<String> _categories = const [
    'Textbooks',
    'Electronics',
    'Furniture',
    'Clothing',
    'Housing',
    'School Supplies',
    'Other',
  ];

  late String _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final priceValue = widget.listing['price'];

    final price = priceValue is num
        ? priceValue.toDouble()
        : double.tryParse(priceValue?.toString() ?? '') ?? 0;

    _titleController = TextEditingController(
      text: widget.listing['title'] as String? ?? '',
    );

    _descriptionController = TextEditingController(
      text: widget.listing['description'] as String? ?? '',
    );

    _priceController = TextEditingController(
      text: price.toStringAsFixed(2),
    );

    _imageUrlController = TextEditingController(
      text: widget.listing['imageUrl'] as String? ?? '',
    );

    final existingCategory =
        widget.listing['category'] as String? ?? 'Other';

    _selectedCategory = _categories.contains(existingCategory)
        ? existingCategory
        : 'Other';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    final originalSellerId =
        widget.listing['sellerId'] as String? ?? '';

    if (currentUser.uid != originalSellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You do not have permission to edit this listing.',
          ),
        ),
      );

      return;
    }

    final price = double.tryParse(
      _priceController.text.trim(),
    );

    if (price == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.listingId)
          .update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'category': _selectedCategory,
        'imageUrl': _imageUrlController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing updated successfully.'),
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'Could not update the listing.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Listing'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  final title = value?.trim() ?? '';

                  if (title.isEmpty) {
                    return 'Enter a title.';
                  }

                  if (title.length < 3) {
                    return 'The title must be at least 3 characters.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 4,
                maxLines: 7,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  final description = value?.trim() ?? '';

                  if (description.isEmpty) {
                    return 'Enter a description.';
                  }

                  if (description.length < 10) {
                    return 'Add a little more information.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}'),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  final price = double.tryParse(
                    value?.trim() ?? '',
                  );

                  if (price == null) {
                    return 'Enter a valid price.';
                  }

                  if (price < 0) {
                    return 'The price cannot be negative.';
                  }

                  if (price > 100000) {
                    return 'Enter a price below \$100,000.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: _isSaving
                    ? null
                    : (category) {
                        if (category != null) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        }
                      },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _imageUrlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
                validator: (value) {
                  final imageUrl = value?.trim() ?? '';

                  if (imageUrl.isEmpty) {
                    return null;
                  }

                  final uri = Uri.tryParse(imageUrl);

                  if (uri == null ||
                      !uri.hasScheme ||
                      !uri.hasAuthority ||
                      (uri.scheme != 'http' &&
                          uri.scheme != 'https')) {
                    return 'Enter a valid image URL.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      _isSaving ? null : _saveChanges,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving
                        ? 'Saving Changes...'
                        : 'Save Changes',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}