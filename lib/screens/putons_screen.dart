import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/likes_service.dart';
import '../widgets/item_detail_modal.dart';

class PutOnsScreen extends StatefulWidget {
  const PutOnsScreen({super.key});

  @override
  State<PutOnsScreen> createState() => _PutOnsScreenState();
}

class _PutOnsScreenState extends State<PutOnsScreen> {
  final _likesService = LikesService();
  final _searchController = TextEditingController(); // Added
  String selectedCategory = 'All';
  String searchQuery = ''; // Added
  bool _isLoading = true;
  List<ClothingItem> _allItems = [];

  @override
  void initState() {
    super.initState();
    _loadPutOnsItems();
  }

  @override
  void dispose() {
    _searchController.dispose(); // Added
    super.dispose();
  }

  Future<void> _loadPutOnsItems() async {
    print('=== LOADING PUT ONS ITEMS ===');
    setState(() => _isLoading = true);
    final items = await _likesService.getPutOnsItems();
    print('Loaded ${items.length} items');
    if (mounted) {
      setState(() {
        _allItems = items;
        _isLoading = false;
      });
      print('State updated with ${_allItems.length} items');
    }
  }

  List<ClothingItem> get filteredItems {
    var items = _allItems;
    
    // Filter by category
    if (selectedCategory != 'All') {
      items = items.where((item) => item.category == selectedCategory).toList();
    }
    
    // Filter by search query
    if (searchQuery.isNotEmpty) {
      items = items.where((item) {
        return item.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            item.brand.toLowerCase().contains(searchQuery.toLowerCase()) ||
            item.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
            item.color.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }
    
    return items;
  }

  Future<void> _confirmRemoveItem(ClothingItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Are you sure you want to remove "${item.name}" from Put Ons?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      _removeItem(item);
    }
  }

  Future<void> _removeItem(ClothingItem item) async {
    // Optimistically remove from local state
    setState(() {
      _allItems.removeWhere((i) => i.id == item.id);
    });

    // Show snackbar immediately
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} removed from Put Ons'),
          backgroundColor: const Color(0xFF2D5F4C),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () async {
              // Re-add the item
              final success = await _likesService.addToPutOns(item);
              if (success) {
                _loadPutOnsItems(); // Reload to get it back
              }
            },
          ),
        ),
      );
    }

    // Actually delete from database
    final success = await _likesService.removeFromPutOns(item.id);
    
    if (!success) {
      // If delete failed, reload to restore state
      _loadPutOnsItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove item'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA8C5B5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5F4C),
        title: const Text(
          'PUT ONS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPutOnsItems,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar and category filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF2D5F4C)),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2D5F4C),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('All'),
                      _buildCategoryChip('Tops'),
                      _buildCategoryChip('Bottoms'),
                      _buildCategoryChip('Accessories'),
                      _buildCategoryChip('Shoes'),
                      _buildCategoryChip('Outerwear'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Items grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2D5F4C),
                    ),
                  )
                : filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              searchQuery.isNotEmpty || selectedCategory != 'All'
                                  ? Icons.search_off
                                  : Icons.bookmark_outline,
                              size: 80,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isNotEmpty || selectedCategory != 'All'
                                  ? 'No items match your search'
                                  : 'No items in Put Ons',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              searchQuery.isNotEmpty || selectedCategory != 'All'
                                  ? 'Try a different search or category'
                                  : 'Browse outfits and add items!',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          return _buildPutOnItemCard(filteredItems[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedCategory = category;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF2D5F4C),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSmartImage(String imageUrl) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (imageUrl.startsWith('http')) {
          return Image.network(
            imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (frame == null) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2D5F4C),
                  ),
                );
              }
              return child;
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image),
              );
            },
          );
        }
        return Image.asset(
          imageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        );
      },
    );
  }

  Widget _buildPutOnItemCard(ClothingItem item) {
    return GestureDetector(
      onTap: () {
        ItemDetailModal.show(
          context,
          item,
          showMoveToWardrobe: true,
          isInWardrobe: false,
          onItemChanged: _loadPutOnsItems,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item image
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: _buildSmartImage(item.imageUrl),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.red),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: () => _confirmRemoveItem(item),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Item details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Color(0xFF2D5F4C),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.brand,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.minPrice.toStringAsFixed(0)} - \$${item.maxPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}