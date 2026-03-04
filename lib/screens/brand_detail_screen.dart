import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/brands_service.dart';
import '../widgets/placeholder_image.dart';
import 'package:url_launcher/url_launcher.dart';

class BrandDetailScreen extends StatefulWidget {
  final Brand brand;

  const BrandDetailScreen({
    super.key,
    required this.brand,
  });

  @override
  State<BrandDetailScreen> createState() => _BrandDetailScreenState();
}

class _BrandDetailScreenState extends State<BrandDetailScreen> {
  final _brandsService = BrandsService();
  bool _isLoading = true;
  List<BrandProduct> _products = [];
  List<BrandCustomField> _customFields = [];

  @override
  void initState() {
    super.initState();
    _loadBrandDetails();
  }

  Future<void> _loadBrandDetails() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _brandsService.getBrandProducts(widget.brand.id),
      _brandsService.getBrandCustomFields(widget.brand.id),
    ]);

    if (mounted) {
      setState(() {
        _products = results[0] as List<BrandProduct>;
        _customFields = results[1] as List<BrandCustomField>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0ED),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2D5F4C),
              ),
            )
          : CustomScrollView(
              slivers: [
                // App Bar with back button
                SliverAppBar(
                  backgroundColor: const Color(0xFF2D5F4C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Section with Brand Name and Tagline
                      _buildHeroSection(),

                      // Brand Info Card
                      _buildBrandInfoCard(),

                      // Iconic Products Section
                      if (_products.isNotEmpty) _buildIconicProductsSection(),

                      // CTA Section
                      _buildCTASection(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeroSection() {
    final tagline = widget.brand.tagline.isNotEmpty
        ? widget.brand.tagline
        : 'Discover the world\'s leading ${widget.brand.name}';
    
    final heroImageUrl = widget.brand.heroImageUrl.isNotEmpty
        ? widget.brand.heroImageUrl
        : widget.brand.logoUrl;

    return Container(
      width: double.infinity,
      color: const Color(0xFF8BA399),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand name and tagline
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.brand.name,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5F4C),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tagline,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3D5F4F),
                  ),
                ),
              ],
            ),
          ),
          
          // Hero Image
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: heroImageUrl.isNotEmpty
                  ? (heroImageUrl.startsWith('http://') ||
                          heroImageUrl.startsWith('https://'))
                      ? Image.network(
                          heroImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderHero();
                          },
                        )
                      : PlaceholderImage(
                          imageUrl: heroImageUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                  : _buildPlaceholderHero(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPlaceholderHero() {
    return Container(
      color: const Color(0xFF2D5F4C).withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.storefront,
          size: 80,
          color: const Color(0xFF2D5F4C).withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildBrandInfoCard() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFD4E3DC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: widget.brand.logoUrl.isNotEmpty
                  ? Image.network(
                      widget.brand.logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to initial if logo fails to load
                        return Center(
                          child: Text(
                            widget.brand.name.isNotEmpty
                                ? widget.brand.name[0].toUpperCase()
                                : 'B',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D5F4C),
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        widget.brand.name.isNotEmpty
                            ? widget.brand.name[0].toUpperCase()
                            : 'B',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D5F4C),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Brand Name and Category
          Text(
            widget.brand.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5F4C),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Athletic & Sportswear',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF3D5F4F),
            ),
          ),
          const SizedBox(height: 16),

          // Brand Description
          Text(
            widget.brand.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF2D5F4C),
            ),
          ),
          
          // Custom Fields (if any)
          if (_customFields.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildCustomFieldsGrid(),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomFieldsGrid() {
    // Organize fields into rows of 2
    final rows = <Widget>[];
    for (int i = 0; i < _customFields.length; i += 2) {
      final field1 = _customFields[i];
      final field2 = i + 1 < _customFields.length ? _customFields[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildInfoColumn(field1.label, field1.value),
              ),
              if (field2 != null)
                Expanded(
                  child: _buildInfoColumn(field2.label, field2.value),
                ),
              if (field2 == null) const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF5A6F62),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF2D5F4C),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildIconicProductsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.brand.productsSectionTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5F4C),
            ),
          ),
          const SizedBox(height: 20),

          // Products Grid
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];

                return GestureDetector(
                  onTap: () => _handleProductTap(product),
                  child: Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product image or placeholder
                        Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: product.imageUrl.isNotEmpty
                                ? (product.imageUrl.startsWith('http://') ||
                                        product.imageUrl.startsWith('https://'))
                                    ? Image.network(
                                        product.imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return _buildProductPlaceholder();
                                        },
                                      )
                                    : PlaceholderImage(
                                        imageUrl: product.imageUrl,
                                        width: double.infinity,
                                        height: 160,
                                        fit: BoxFit.cover,
                                      )
                                : _buildProductPlaceholder(),
                          ),
                        ),
                        // Product info
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D5F4C),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                product.price,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF3D5F4F),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleProductTap(BrandProduct product) {
    if (product.productUrl.isEmpty) {
      // Show a message that this product doesn't have a link
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This product doesn\'t have a store link yet'),
          backgroundColor: const Color(0xFF2D5F4C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show dialog asking if user wants to visit the store
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                color: Color(0xFF2D5F4C),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Visit Store?',
                  style: const TextStyle(
                    color: Color(0xFF2D5F4C),
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
                'Would you like to view ${product.name} in the store?',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link,
                      size: 16,
                      color: Color(0xFF2D5F4C),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product.productUrl,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2D5F4C),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _launchProductUrl(product.productUrl);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5F4C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Visit Store',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchProductUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
    
    // For now, just show a message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening: $url'),
          backgroundColor: const Color(0xFF2D5F4C),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildProductPlaceholder() {
    return Center(
      child: Icon(
        Icons.checkroom,
        size: 60,
        color: Colors.black12,
      ),
    );
  }

  Widget _buildCTASection() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF8BA399),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            widget.brand.ctaHeading,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5F4C),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.brand.ctaDescription,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF3D5F4F),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchProductUrl(widget.brand.shopUrl);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5F4C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Shop ${widget.brand.name}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}