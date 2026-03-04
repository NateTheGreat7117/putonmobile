import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/brands_service.dart';
import '../widgets/placeholder_image.dart';
import 'brand_detail_screen.dart';

class BrandOfWeekScreen extends StatefulWidget {
  const BrandOfWeekScreen({super.key});

  @override
  State<BrandOfWeekScreen> createState() => _BrandOfWeekScreenState();
}

class _BrandOfWeekScreenState extends State<BrandOfWeekScreen> {
  final _brandsService = BrandsService();
  final _searchController = TextEditingController();
  bool _isLoading = true;
  Brand? _brandOfTheWeek;
  List<Brand> _risingBrands = [];
  List<Brand> _allBrands = [];
  bool _isSearching = false;
  bool _sortAscending = true; // true = lowest points first, false = highest first
  bool _showHowItWorks = true;
  RangeValues _pointsRange = const RangeValues(0, 1000);
  double _maxPoints = 1000;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    setState(() => _isLoading = true);

    // Load brand of the week and rising brands in parallel
    final results = await Future.wait([
      _brandsService.getBrandOfTheWeek(),
      _brandsService.getRisingBrands(limit: 10),
      _brandsService.getBrands(ascending: _sortAscending),
    ]);

    if (mounted) {
      setState(() {
        _brandOfTheWeek = results[0] as Brand?;
        _risingBrands = results[1] as List<Brand>;
        _allBrands = results[2] as List<Brand>;
        
        // Calculate max points for the slider
        if (_allBrands.isNotEmpty) {
          _maxPoints = _allBrands
              .map((b) => b.points.toDouble())
              .reduce((a, b) => a > b ? a : b);
          _pointsRange = RangeValues(0, _maxPoints);
        }
        
        _isLoading = false;
      });
    }
  }

  void _searchBrands(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
  }

  void _toggleSort() {
    setState(() {
      _sortAscending = !_sortAscending;
      _allBrands = _allBrands.reversed.toList();
      _risingBrands = _risingBrands.reversed.toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });
  }

  List<Brand> _getFilteredBrands() {
    return _allBrands.where((brand) {
      // Filter by points range
      final pointsMatch = brand.points >= _pointsRange.start && 
                         brand.points <= _pointsRange.end;
      
      // Filter by search query
      final searchQuery = _searchController.text.toLowerCase();
      final searchMatch = searchQuery.isEmpty || 
                         brand.name.toLowerCase().contains(searchQuery);
      
      return pointsMatch && searchMatch;
    }).toList();
  }

  bool _isFiltering() {
    return _pointsRange.start > 0 || _pointsRange.end < _maxPoints;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5F4C),
        title: const Text(
          'BRAND OF THE WEEK',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBrands,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2D5F4C),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadBrands,
              color: const Color(0xFF2D5F4C),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Featured Brand Banner (always visible)
                    if (_brandOfTheWeek != null)
                      _buildFeaturedBrandBanner(_brandOfTheWeek!),
                    
                    // About the Points System (collapsible, always visible)
                    _buildPointsSystemInfo(),
                    
                    // Search and Sort Bar
                    _buildSearchAndSortBar(),
                    
                    // Brand List (shows either rising brands or all brands based on search/sort)
                    if (_isSearching || _isFiltering() || _sortAscending != true)
                      _buildAllBrandsList()
                    else if (_risingBrands.isNotEmpty)
                      _buildRisingBrandsList(),
                    
                    // Empty state
                    if (_brandOfTheWeek == null && 
                        _risingBrands.isEmpty && 
                        _allBrands.isEmpty)
                      _buildEmptyState(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSearchAndSortBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: _searchBrands,
            decoration: InputDecoration(
              hintText: 'Search brands...',
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF2D5F4C),
              ),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Range slider for points
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Points Range',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '${_pointsRange.start.round()} - ${_pointsRange.end.round()} pts',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D5F4C),
                    ),
                  ),
                ],
              ),
              RangeSlider(
                values: _pointsRange,
                min: 0,
                max: _maxPoints,
                divisions: _maxPoints > 100 ? 100 : _maxPoints.toInt(),
                activeColor: const Color(0xFF2D5F4C),
                inactiveColor: const Color(0xFF2D5F4C).withOpacity(0.2),
                labels: RangeLabels(
                  _pointsRange.start.round().toString(),
                  _pointsRange.end.round().toString(),
                ),
                onChanged: (RangeValues values) {
                  setState(() {
                    _pointsRange = values;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Sort button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _toggleSort,
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 18,
                  color: const Color(0xFF2D5F4C),
                ),
                label: Text(
                  _sortAscending ? 'Lowest Points First' : 'Highest Points First',
                  style: const TextStyle(
                    color: Color(0xFF2D5F4C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  backgroundColor: const Color(0xFF2D5F4C).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedBrandBanner(Brand brand) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BrandDetailScreen(brand: brand),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2D5F4C), Color(0xFF4A8A6F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.star,
              color: Color(0xFFFFD700),
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Featured Brand',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              brand.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              brand.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.trending_up,
                    color: Color(0xFFFFD700),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${brand.points} Points',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tap to view indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tap to view details',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.touch_app,
                  color: Colors.white.withOpacity(0.6),
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsSystemInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // Header (always visible, clickable)
          InkWell(
            onTap: () {
              setState(() {
                _showHowItWorks = !_showHowItWorks;
              });
            },
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: _showHowItWorks 
                  ? const EdgeInsets.all(20)
                  : const EdgeInsets.all(16),
              child: _showHowItWorks
                  ? Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF2D5F4C),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'How It Works',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D5F4C),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_up,
                          color: Color(0xFF2D5F4C),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF2D5F4C),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF2D5F4C),
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
          // Expandable content
          if (_showHowItWorks)
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: Text(
                'We boost small brands! Brands start with 0 points. As they gain attention through creator posts, their points increase. Lower points = more visibility boost for creators.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRisingBrandsList() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Featured Brands',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5F4C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Small brands growing fast this week',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ..._risingBrands.map((brand) => _buildBrandCard(brand)),
        ],
      ),
    );
  }

  Widget _buildAllBrandsList() {
    final brandsToShow = _getFilteredBrands();
    
    if (brandsToShow.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No brands found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            if (_isFiltering())
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Try adjusting the points range',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSearching ? 'Search Results' : 'All Brands',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5F4C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${brandsToShow.length} brand${brandsToShow.length == 1 ? '' : 's'} found',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ...brandsToShow.map((brand) => _buildBrandCard(brand)),
        ],
      ),
    );
  }

  Widget _buildBrandCard(Brand brand) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BrandDetailScreen(brand: brand),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Brand logo
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: brand.logoUrl.isNotEmpty
                  ? (brand.logoUrl.startsWith('http://') ||
                          brand.logoUrl.startsWith('https://'))
                      ? Image.network(
                          brand.logoUrl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 70,
                              height: 70,
                              color: const Color(0xFF2D5F4C).withOpacity(0.1),
                              child: const Icon(
                                Icons.storefront,
                                color: Color(0xFF2D5F4C),
                                size: 35,
                              ),
                            );
                          },
                        )
                      : PlaceholderImage(
                          imageUrl: brand.logoUrl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        )
                  : Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D5F4C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.storefront,
                        color: Color(0xFF2D5F4C),
                        size: 35,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            // Brand info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D5F4C),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    brand.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D5F4C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.trending_up,
                              size: 14,
                              color: Color(0xFF2D5F4C),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${brand.points} pts',
                              style: const TextStyle(
                                color: Color(0xFF2D5F4C),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow indicator
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF2D5F4C),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Brands Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Brands will appear here once they\'re added',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}