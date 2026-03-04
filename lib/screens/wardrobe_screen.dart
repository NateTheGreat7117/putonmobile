import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/likes_service.dart';
import '../services/wardrobe_service.dart';
import '../services/outfit_service.dart';
import '../widgets/placeholder_image.dart';
import '../widgets/item_detail_modal.dart';
import '../widgets/add_item_modal.dart';
import '../widgets/bulk_add_modal.dart';
import '../widgets/create_outfit_modal.dart';
import '../widgets/view_outfit_modal.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final _likesService = LikesService();
  final _wardrobeService = WardrobeService();
  final _outfitService = OutfitService();
  
  String selectedTab = 'Items';
  String selectedCategory = 'All Categories';
  String searchQuery = '';
  bool _isLoading = true;
  List<ClothingItem> _allItems = [];
  List<Map<String, dynamic>> _allOutfits = [];

  final List<String> categories = [
    'All Categories',
    'Tops',
    'Bottoms',
    'Accessories',
    'Shoes',
  ];

  @override
  void initState() {
    super.initState();
    _loadWardrobeItems();
  }

  Future<void> _loadWardrobeItems() async {
    setState(() => _isLoading = true);
    final items = await _wardrobeService.getWardrobeItems();
    if (mounted) {
      setState(() {
        _allItems = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOutfits() async {
    setState(() => _isLoading = true);
    final outfits = await _outfitService.getUserOutfits();
    if (mounted) {
      setState(() {
        _allOutfits = outfits;
        _isLoading = false;
      });
    }
  }

  List<ClothingItem> get filteredItems {
    var items = _allItems;

    // Filter by category
    if (selectedCategory != 'All Categories') {
      items = items.where((item) => item.category == selectedCategory).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      items = items.where((item) {
        return item.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            item.brand.toLowerCase().contains(searchQuery.toLowerCase()) ||
            item.category.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    return items;
  }

  Future<void> _confirmRemoveItem(ClothingItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Are you sure you want to remove "${item.name}" from your wardrobe?'),
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
    final success = await _wardrobeService.deleteWardrobeItem(item.id);
    if (success) {
      _loadWardrobeItems(); // Reload the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} removed from wardrobe'),
            backgroundColor: const Color(0xFF2D5F4C),
          ),
        );
      }
    }
  }

  Future<void> _confirmRemoveOutfit(Map<String, dynamic> outfit) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Outfit'),
        content: Text('Are you sure you want to delete "${outfit['name']}"?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      _removeOutfit(outfit['id']);
    }
  }

  Future<void> _removeOutfit(String outfitId) async {
    final success = await _outfitService.deleteOutfit(outfitId);
    if (success) {
      _loadOutfits();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Outfit deleted'),
            backgroundColor: Color(0xFF2D5F4C),
          ),
        );
      }
    }
  }

  void _showAddOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            const Text(
              'Add Items to Wardrobe',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D5F4C),
              ),
            ),
            const SizedBox(height: 20),
            // Add Single Item Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5F4C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFF2D5F4C),
                ),
              ),
              title: const Text(
                'Add Single Item',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: const Text('Add one item with all details'),
              onTap: () {
                Navigator.pop(context);
                _showAddItemModal();
              },
            ),
            const SizedBox(height: 8),
            // Bulk Add Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5F4C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.collections,
                  color: Color(0xFF2D5F4C),
                ),
              ),
              title: const Text(
                'Bulk Add Items',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: const Text('Upload multiple items at once'),
              onTap: () {
                Navigator.pop(context);
                _showBulkAddModal();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showAddItemModal() {
    showDialog(
      context: context,
      builder: (context) => AddItemModal(
        onItemAdded: _loadWardrobeItems,
      ),
    );
  }

  void _showBulkAddModal() {
    showDialog(
      context: context,
      builder: (context) => BulkAddModal(
        onItemsAdded: _loadWardrobeItems,
      ),
    );
  }

  void _showCreateOutfitModal() {
    showDialog(
      context: context,
      builder: (context) => CreateOutfitModal(
        onOutfitCreated: _loadOutfits,
      ),
    );
  }

  void _showViewOutfitModal(String outfitId) {
    showDialog(
      context: context,
      builder: (context) => ViewOutfitModal(
        outfitId: outfitId,
        onOutfitUpdated: _loadOutfits,
        onOutfitDeleted: _loadOutfits,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA8C5B5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFA8C5B5),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Wardrobe',
              style: TextStyle(
                color: Color(0xFF2D5F4C),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Organize and manage your clothing collection',
              style: TextStyle(
                color: Color(0xFF5A7A6A),
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2D5F4C)),
            onPressed: () {
              if (selectedTab == 'Items') {
                _loadWardrobeItems();
              } else {
                _loadOutfits();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: const Color(0xFFA8C5B5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _buildTab('Items'),
                const SizedBox(width: 10),
                _buildTab('Outfits'),
              ],
            ),
          ),
          // Search and Filter
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFA8C5B5),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: selectedTab == 'Items' 
                          ? 'Search wardrobe items...'
                          : 'Search outfits...',
                      hintStyle: const TextStyle(color: Color(0xFF7A9A8A)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF5A7A6A)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (selectedTab == 'Items')
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D5F4C),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onSelected: (value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                      itemBuilder: (context) => categories
                          .map((cat) => PopupMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                    ),
                  ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: const Color(0xFF2D5F4C),
                  onPressed: selectedTab == 'Items'
                      ? _showAddOptionsMenu
                      : _showCreateOutfitModal,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          // Grid of items or outfits
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2D5F4C),
                    ),
                  )
                : selectedTab == 'Items'
                    ? _buildItemsGrid()
                    : _buildOutfitsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsGrid() {
    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 80,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty
                  ? 'No items match your search'
                  : 'No items in wardrobe',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Tap the + button to add items!',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFA8C5B5),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          return _buildWardrobeItemCard(item);
        },
      ),
    );
  }

  Widget _buildOutfitsGrid() {
    if (_allOutfits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 80,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'No outfits created yet',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create your first outfit!',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFA8C5B5),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: _allOutfits.length,
        itemBuilder: (context, index) {
          final outfit = _allOutfits[index];
          return _buildOutfitCard(outfit);
        },
      ),
    );
  }

  Widget _buildTab(String title) {
    final isSelected = selectedTab == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = title;
        });
        if (title == 'Outfits') {
          _loadOutfits();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D5F4C) : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.checkroom : Icons.checkroom_outlined,
              color: isSelected ? Colors.white : const Color(0xFF2D5F4C),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2D5F4C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWardrobeItemCard(ClothingItem item) {
    return GestureDetector(
      onTap: () {
        ItemDetailModal.show(
          context,
          item,
          showMoveToWardrobe: false,
          isInWardrobe: true,
          onItemChanged: _loadWardrobeItems,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
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
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child: _buildItemImage(item.imageUrl),
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
                        icon: const Icon(Icons.close, size: 18),
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
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
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
                          item.category,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
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

  Widget _buildOutfitCard(Map<String, dynamic> outfit) {
    final coverImageUrl = outfit['cover_image_url'] as String? ?? '';
    final itemIds = List<String>.from(outfit['item_ids'] ?? []);
    
    return GestureDetector(
      onTap: () {
        _showViewOutfitModal(outfit['id'] as String);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
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
            // Outfit cover image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child: coverImageUrl.isNotEmpty
                          ? _buildItemImage(coverImageUrl)
                          : Center(
                              child: Icon(
                                Icons.checkroom,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                            ),
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
                        icon: const Icon(Icons.close, size: 18),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: () => _confirmRemoveOutfit(outfit),
                      ),
                    ),
                  ),
                  // Item count badge
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D5F4C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${itemIds.length} items',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Outfit details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      outfit['name'] as String,
                      style: const TextStyle(
                        color: Color(0xFF2D5F4C),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (outfit['description'] != null && 
                        (outfit['description'] as String).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        outfit['description'] as String,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            color: Colors.grey.shade300,
            child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
          );
        },
      );
    } else if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            color: Colors.grey.shade300,
            child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
          );
        },
      );
    } else {
      return PlaceholderImage(
        imageUrl: imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
  }
}