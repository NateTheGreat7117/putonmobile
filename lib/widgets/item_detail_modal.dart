import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/likes_service.dart';
import 'edit_item_modal.dart';

class ItemDetailModal extends StatelessWidget {
  final ClothingItem item;
  final bool showMoveToWardrobe;
  final bool isInWardrobe;
  final VoidCallback? onItemChanged;

  const ItemDetailModal({
    super.key,
    required this.item,
    this.showMoveToWardrobe = false,
    this.isInWardrobe = false,
    this.onItemChanged,
  });

  static void show(
    BuildContext context,
    ClothingItem item, {
    bool showMoveToWardrobe = false,
    bool isInWardrobe = false,
    VoidCallback? onItemChanged,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => ItemDetailModal(
        item: item,
        showMoveToWardrobe: showMoveToWardrobe,
        isInWardrobe: isInWardrobe,
        onItemChanged: onItemChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Item Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Image (clickable for zoom)
                  GestureDetector(
                    onTap: () => _showImageZoom(context),
                    child: Hero(
                      tag: 'item-image-${item.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildItemImage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Item Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Name:', item.name),
                        _buildDetailRow('Category:', item.category),
                        _buildDetailRow('Brand:', item.brand),
                        _buildDetailRow('Color:', item.color),
                        _buildDetailRow('Size:', item.size),
                        _buildDetailRow(
                          'Price:',
                          '\$${item.minPrice.toStringAsFixed(0)}-\$${item.maxPrice.toStringAsFixed(0)}',
                        ),
                        if (item.purchaseUrl.isNotEmpty)
                          _buildDetailRow('Product Link:', '-', isLink: true)
                        else
                          _buildDetailRow('Product Link:', '-'),
                        if (isInWardrobe && item.notes != null && item.notes!.isNotEmpty)
                          _buildDetailRow('Notes:', item.notes!)
                        else if (isInWardrobe)
                          _buildDetailRow('Notes:', '-'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _buildActionButtons(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (showMoveToWardrobe) {
      // Put Ons screen - show Edit and Move to Wardrobe
      return Column(
        children: [
          // Edit button (full width)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleEditItem(context),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Colors.black26),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Move to Wardrobe button (full width)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleMoveToWardrobe(context),
              icon: const Icon(Icons.checkroom, size: 18),
              label: const Text('Move to Wardrobe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5F4C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (isInWardrobe) {
      // Wardrobe screen - show only Edit button (no Shop Now)
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _handleEditItem(context),
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Edit Details'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87,
            side: const BorderSide(color: Colors.black26),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    } else {
      // Other screens (like outfit detail) - show Edit and Shop Now
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _handleEditItem(context),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Colors.black26),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _launchURL(item.purchaseUrl),
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('Shop Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5F4C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  void _showImageZoom(BuildContext context) {
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

  Widget _buildItemImage() {
    if (item.imageUrl.startsWith('http')) {
      return Image.network(
        item.imageUrl,
        width: 120,
        height: 160,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 120,
            height: 160,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
          );
        },
      );
    }
    return Image.asset(
      item.imageUrl,
      width: 120,
      height: 160,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 120,
          height: 160,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          isLink && item.purchaseUrl.isNotEmpty
              ? GestureDetector(
                  onTap: () => _launchURL(item.purchaseUrl),
                  child: const Text(
                    'View Product',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2D5F4C),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
        ],
      ),
    );
  }

  Future<void> _handleEditItem(BuildContext context) async {
    final callback = onItemChanged;
    
    Navigator.pop(context);
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (context.mounted) {
      EditItemModal.show(
        context,
        item,
        isInWardrobe: isInWardrobe,
        onItemUpdated: callback,
      );
    }
  }

  Future<void> _handleMoveToWardrobe(BuildContext context) async {
    if (showMoveToWardrobe) {
      final likesService = LikesService();
      
      final success = await likesService.movePutOnToWardrobe(item);
      
      if (success && context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} moved to wardrobe'),
            backgroundColor: const Color(0xFF2D5F4C),
          ),
        );
        onItemChanged?.call();
      }
    }
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) return;
    
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}