import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/likes_service.dart';
import '../services/user_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'user_profile_screen.dart';
import 'profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OutfitDetailScreen extends StatefulWidget {
  final Outfit outfit;
  final VoidCallback? onNavigateToPutOns; // Optional callback to navigate to Put Ons tab

  const OutfitDetailScreen({
    super.key, 
    required this.outfit,
    this.onNavigateToPutOns,
  });

  @override
  State<OutfitDetailScreen> createState() => _OutfitDetailScreenState();
}

class _OutfitDetailScreenState extends State<OutfitDetailScreen> {
  final _likesService = LikesService();
  final _userService = UserService();
  final supabase = Supabase.instance.client;
  final Map<String, bool> _inPutOns = {};
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadPutOnsStatus(),
      _loadUserProfile(),
    ]);
  }

  Future<void> _loadPutOnsStatus() async {
    for (var item in widget.outfit.items) {
      final isAdded = await _likesService.isInPutOns(item.id);
      _inPutOns[item.id] = isAdded;
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await _userService.getUserProfile(widget.outfit.userId);
    if (mounted) {
      setState(() {
        _userProfile = profile;
      });
    }
  }

  void _navigateToProfile() {
    final currentUserId = supabase.auth.currentUser?.id;
    
    if (currentUserId == widget.outfit.userId) {
      // Navigate to own profile
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } else {
      // Navigate to other user's profile
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(userId: widget.outfit.userId),
        ),
      );
    }
  }

  Future<void> _togglePutOns(ClothingItem item) async {
    final currentStatus = _inPutOns[item.id] ?? false;
    
    // Optimistic update
    setState(() {
      _inPutOns[item.id] = !currentStatus;
    });

    final success = currentStatus
        ? await _likesService.removeFromPutOns(item.id)
        : await _likesService.addToPutOns(item);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus
                  ? '${item.name} removed from Put Ons'
                  : '${item.name} added to Put Ons',
            ),
            backgroundColor: const Color(0xFF2D5F4C),
            duration: const Duration(seconds: 4),
            action: !currentStatus ? SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // IMPORTANT: Change the tab FIRST, then pop
                if (widget.onNavigateToPutOns != null) {
                  widget.onNavigateToPutOns!();
                }
                // Then pop back to root to see the Put Ons tab
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ) : null,
          ),
        );
      }
    } else {
      // Revert on failure
      if (mounted) {
        setState(() {
          _inPutOns[item.id] = currentStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update Put Ons'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageZoom(BuildContext context, ClothingItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: 'item-image-${item.id}',
                child: item.imageUrl.startsWith('http')
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.contain,
                      )
                    : Image.asset(
                        item.imageUrl,
                        fit: BoxFit.contain,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: _navigateToProfile,
          child: Row(
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF2D5F4C),
                backgroundImage: _userProfile?['avatar_url'] != null 
                    ? NetworkImage(_userProfile!['avatar_url']) 
                    : null,
                child: _userProfile?['avatar_url'] == null
                    ? Text(
                        widget.outfit.userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              // Username
              Text(
                widget.outfit.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Outfit Image from Supabase
            _buildMainImage(widget.outfit.imageUrl),
            
            const SizedBox(height: 16),
            
            // Tagged items section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tagged Items',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Loop through items stored in the Outfit object
                  if (widget.outfit.items.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text(
                          'No items tagged in this outfit',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...widget.outfit.items.map((item) => _buildClothingItemCard(context, item)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainImage(String imageUrl) {
    // If it's a web URL (Supabase), use Image.network
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: 500,
        fit: BoxFit.cover,
        // Shows while downloading
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 500,
            color: const Color(0xFF1A1A1A),
            child: const Center(child: CircularProgressIndicator(color: Color(0xFF2D5F4C))),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(500),
      );
    } 
    // Fallback to asset if you're still testing locally
    return Image.asset(
      imageUrl,
      width: double.infinity,
      height: 500,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(500),
    );
  }

  Widget _buildClothingItemCard(BuildContext context, ClothingItem item) {
    final isInWishlist = _inPutOns[item.id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Item thumbnail - wrapped with GestureDetector and Hero for zoom
              GestureDetector(
                onTap: () => _showImageZoom(context, item),
                child: Hero(
                  tag: 'item-image-${item.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildThumbnail(item.imageUrl),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF2D5F4C),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${item.brand} • ${item.color}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${item.minPrice.toStringAsFixed(0)} - \$${item.maxPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Add to Put Ons button with text label
              OutlinedButton.icon(
                onPressed: _isLoading ? null : () => _togglePutOns(item),
                icon: Icon(
                  isInWishlist ? Icons.bookmark : Icons.bookmark_border,
                  color: isInWishlist ? const Color(0xFF2D5F4C) : Colors.white,
                  size: 20,
                ),
                label: Text(
                  isInWishlist ? 'Saved' : 'Save',
                  style: TextStyle(
                    color: isInWishlist ? const Color(0xFF2D5F4C) : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isInWishlist ? const Color(0xFF2D5F4C) : Colors.white30,
                    width: 1.5,
                  ),
                  backgroundColor: isInWishlist ? const Color(0xFF2D5F4C).withOpacity(0.1) : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Shop Now Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleShopNow(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5F4C),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text(
                'Shop Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(80),
      );
    }
    return Image.asset(
      imageUrl,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(80),
    );
  }

  Widget _buildErrorPlaceholder(double size) {
    return Container(
      width: double.infinity,
      height: size,
      color: const Color(0xFF2D2D2D),
      child: const Icon(Icons.broken_image, color: Colors.white24),
    );
  }

  void _handleShopNow(ClothingItem item) {
    if (item.purchaseUrl.isEmpty) {
      _showNoPurchaseLinkDialog(item);
      return;
    }

    _launchURL(item.purchaseUrl);
  }

  void _showNoPurchaseLinkDialog(ClothingItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          title: Row(
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                color: Color(0xFF2D5F4C),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'No Purchase Link',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This item doesn\'t have a purchase link yet.',
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Item Details',
                      style: TextStyle(
                        color: Color(0xFF2D5F4C),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.brand} ${item.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Color: ${item.color}',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                    if (item.size.isNotEmpty)
                      Text(
                        'Size: ${item.size}',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                final searchQuery = Uri.encodeComponent('${item.brand} ${item.name}');
                launchUrl(
                  Uri.parse('https://www.google.com/search?q=$searchQuery'),
                  mode: LaunchMode.externalApplication,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5F4C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.search, size: 18),
              label: const Text(
                'Search Online',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}