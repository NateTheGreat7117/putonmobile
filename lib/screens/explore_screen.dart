import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'outfit_detail_screen.dart';
import '../services/likes_service.dart';
import 'user_profile_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import '../main.dart'; // Import to access mainScreenKey

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String selectedTab = 'For You';
  final supabase = Supabase.instance.client;
  
  // Filter state
  Set<String> selectedStyles = {};
  Set<String> selectedSeasons = {};
  Set<String> selectedOccasions = {};
  bool useAndLogic = true; // true = AND, false = OR

  // Filter options - must match create_post_screen.dart exactly
  final List<String> styleOptions = [
    'Streetwear',
    'Casual',
    'Formal',
    'Business Casual',
    'Athleisure',
    'Vintage',
    'Minimalist',
    'Bohemian',
    'Preppy',
    'Grunge',
    'Y2K',
    'Techwear',
  ];

  final List<String> seasonOptions = [
    'Spring',
    'Summer',
    'Fall',
    'Winter',
  ];

  final List<String> occasionOptions = [
    'Date Night',
    'Beach',
    'Gym/Workout',
    'Office',
    'Party',
    'Brunch',
    'Travel',
    'Concert',
    'Wedding',
    'Casual Hangout',
    'Interview',
    'Festival',
  ];

  int get activeFilterCount {
    return selectedStyles.length + 
           selectedSeasons.length + 
           selectedOccasions.length;
  }

  Future<List<Outfit>> _fetchOutfits(String tab) async {
    try {
      var query = supabase
          .from('outfits')
          .select()
          .eq('tab_category', tab);

      final response = await query.order('created_at', ascending: false);
      
      // Get all outfits first, then filter in Dart
      var outfits = (response as List).map((json) => Outfit.fromJson(json)).toList();
      
      debugPrint('Total outfits before filtering: ${outfits.length}');
      debugPrint('Filter mode: ${useAndLogic ? "AND" : "OR"}');
      
      // Apply client-side filtering
      if (selectedStyles.isNotEmpty || selectedSeasons.isNotEmpty || selectedOccasions.isNotEmpty) {
        outfits = outfits.where((outfit) {
          if (useAndLogic) {
            // AND logic: Must match all selected filter categories
            bool matchesStyle = selectedStyles.isEmpty;
            bool matchesSeason = selectedSeasons.isEmpty;
            bool matchesOccasion = selectedOccasions.isEmpty;
            
            // Check styles - outfit must have at least one matching style
            if (selectedStyles.isNotEmpty) {
              final outfitStyles = outfit.styles ?? [];
              matchesStyle = outfitStyles.any((style) => selectedStyles.contains(style));
            }
            
            // Check seasons - outfit must have at least one matching season
            if (selectedSeasons.isNotEmpty) {
              final outfitSeasons = outfit.seasons ?? [];
              matchesSeason = outfitSeasons.any((season) => selectedSeasons.contains(season));
            }
            
            // Check occasions - outfit must have at least one matching occasion
            if (selectedOccasions.isNotEmpty) {
              final outfitOccasions = outfit.occasions ?? [];
              matchesOccasion = outfitOccasions.any((occasion) => selectedOccasions.contains(occasion));
            }
            
            return matchesStyle && matchesSeason && matchesOccasion;
          } else {
            // OR logic: Must match at least one filter from any category
            bool matchesAny = false;
            
            // Check if outfit matches any selected style
            if (selectedStyles.isNotEmpty) {
              final outfitStyles = outfit.styles ?? [];
              if (outfitStyles.any((style) => selectedStyles.contains(style))) {
                matchesAny = true;
              }
            }
            
            // Check if outfit matches any selected season
            if (selectedSeasons.isNotEmpty && !matchesAny) {
              final outfitSeasons = outfit.seasons ?? [];
              if (outfitSeasons.any((season) => selectedSeasons.contains(season))) {
                matchesAny = true;
              }
            }
            
            // Check if outfit matches any selected occasion
            if (selectedOccasions.isNotEmpty && !matchesAny) {
              final outfitOccasions = outfit.occasions ?? [];
              if (outfitOccasions.any((occasion) => selectedOccasions.contains(occasion))) {
                matchesAny = true;
              }
            }
            
            return matchesAny;
          }
        }).toList();
        
        debugPrint('Outfits after filtering: ${outfits.length}');
      }

      return outfits;
    } catch (e) {
      debugPrint('Supabase Error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      return [];
    }
  }

  void _navigateToProfile(String userId) {
    final currentUserId = supabase.auth.currentUser?.id;
    
    if (currentUserId == userId) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
      );
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FilterModal(
        selectedStyles: selectedStyles,
        selectedSeasons: selectedSeasons,
        selectedOccasions: selectedOccasions,
        useAndLogic: useAndLogic,
        styleOptions: styleOptions,
        seasonOptions: seasonOptions,
        occasionOptions: occasionOptions,
        onApply: (styles, seasons, occasions, andLogic) {
          setState(() {
            selectedStyles = styles;
            selectedSeasons = seasons;
            selectedOccasions = occasions;
            useAndLogic = andLogic;
          });
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      selectedStyles.clear();
      selectedSeasons.clear();
      selectedOccasions.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'EXPLORE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          // Filter button with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: _showFilterModal,
              ),
              if (activeFilterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2D5F4C),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$activeFilterCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          if (activeFilterCount > 0) _buildActiveFiltersBar(),
          Expanded(
            child: FutureBuilder<List<Outfit>>(
              key: ValueKey('$selectedTab-${selectedStyles.toString()}-${selectedSeasons.toString()}-${selectedOccasions.toString()}-$useAndLogic'),
              future: _fetchOutfits(selectedTab),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2D5F4C)),
                  );
                }

                final outfits = snapshot.data ?? [];

                if (outfits.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  itemCount: outfits.length,
                  itemBuilder: (context, index) {
                    return OutfitCard(
                      key: ValueKey(outfits[index].id),
                      outfit: outfits[index],
                      supabase: supabase,
                      onProfileTap: _navigateToProfile,
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

  Widget _buildTabs() {
    final tabs = ['For You', 'Following', 'Trending'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) => _buildTab(tab)).toList(),
      ),
    );
  }

  Widget _buildTab(String title) {
    final bool isSelected = selectedTab == title;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF2D5F4C) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF0A0A0A),
      child: Row(
        children: [
          // AND/OR indicator chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2D5F4C).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2D5F4C),
                width: 1,
              ),
            ),
            child: Text(
              useAndLogic ? 'AND' : 'OR',
              style: const TextStyle(
                color: Color(0xFF2D5F4C),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...selectedStyles.map((style) => _buildFilterChip(style, 'style')),
                  ...selectedSeasons.map((season) => _buildFilterChip(season, 'season')),
                  ...selectedOccasions.map((occasion) => _buildFilterChip(occasion, 'occasion')),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: Color(0xFF2D5F4C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () {
          setState(() {
            if (type == 'style') selectedStyles.remove(label);
            if (type == 'season') selectedSeasons.remove(label);
            if (type == 'occasion') selectedOccasions.remove(label);
          });
        },
        backgroundColor: const Color(0xFF2D5F4C),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        deleteIconColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.filter_alt_off, color: Colors.grey, size: 48),
          const SizedBox(height: 16),
          Text(
            activeFilterCount > 0
                ? "No outfits match your filters"
                : "No outfits yet. Check back later!",
            style: const TextStyle(color: Colors.grey),
          ),
          if (activeFilterCount > 0) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _clearFilters,
              child: const Text(
                'Clear filters',
                style: TextStyle(color: Color(0xFF2D5F4C)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterModal extends StatefulWidget {
  final Set<String> selectedStyles;
  final Set<String> selectedSeasons;
  final Set<String> selectedOccasions;
  final bool useAndLogic;
  final List<String> styleOptions;
  final List<String> seasonOptions;
  final List<String> occasionOptions;
  final Function(Set<String>, Set<String>, Set<String>, bool) onApply;

  const _FilterModal({
    required this.selectedStyles,
    required this.selectedSeasons,
    required this.selectedOccasions,
    required this.useAndLogic,
    required this.styleOptions,
    required this.seasonOptions,
    required this.occasionOptions,
    required this.onApply,
  });

  @override
  State<_FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<_FilterModal> {
  late Set<String> tempStyles;
  late Set<String> tempSeasons;
  late Set<String> tempOccasions;
  late bool tempUseAndLogic;

  @override
  void initState() {
    super.initState();
    tempStyles = Set.from(widget.selectedStyles);
    tempSeasons = Set.from(widget.selectedSeasons);
    tempOccasions = Set.from(widget.selectedOccasions);
    tempUseAndLogic = widget.useAndLogic;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      tempStyles.clear();
                      tempSeasons.clear();
                      tempOccasions.clear();
                    });
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          // AND/OR Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          tempUseAndLogic = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: tempUseAndLogic ? const Color(0xFF2D5F4C) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'AND',
                              style: TextStyle(
                                color: tempUseAndLogic ? Colors.white : Colors.grey[400],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Match all categories',
                              style: TextStyle(
                                color: tempUseAndLogic ? Colors.white70 : Colors.grey[600],
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          tempUseAndLogic = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !tempUseAndLogic ? const Color(0xFF2D5F4C) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'OR',
                              style: TextStyle(
                                color: !tempUseAndLogic ? Colors.white : Colors.grey[400],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Match any category',
                              style: TextStyle(
                                color: !tempUseAndLogic ? Colors.white70 : Colors.grey[600],
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Filters content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterSection(
                    'Style',
                    widget.styleOptions,
                    tempStyles,
                  ),
                  const SizedBox(height: 24),
                  _buildFilterSection(
                    'Season',
                    widget.seasonOptions,
                    tempSeasons,
                  ),
                  const SizedBox(height: 24),
                  _buildFilterSection(
                    'Occasion',
                    widget.occasionOptions,
                    tempOccasions,
                  ),
                  const SizedBox(height: 100), // Space for button
                ],
              ),
            ),
          ),
          // Apply button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                top: BorderSide(color: Colors.grey[800]!),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(tempStyles, tempSeasons, tempOccasions, tempUseAndLogic);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5F4C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Apply Filters${_getFilterCount()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterCount() {
    final count = tempStyles.length + tempSeasons.length + tempOccasions.length;
    return count > 0 ? ' ($count)' : '';
  }

  Widget _buildFilterSection(String title, List<String> options, Set<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    selected.add(option);
                  } else {
                    selected.remove(option);
                  }
                });
              },
              backgroundColor: const Color(0xFF2A2A2A),
              selectedColor: const Color(0xFF2D5F4C),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF2D5F4C) : Colors.grey[700]!,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class OutfitCard extends StatefulWidget {
  final Outfit outfit;
  final SupabaseClient supabase;
  final Function(String) onProfileTap;

  const OutfitCard({
    super.key,
    required this.outfit,
    required this.supabase,
    required this.onProfileTap,
  });

  @override
  State<OutfitCard> createState() => _OutfitCardState();
}

class _OutfitCardState extends State<OutfitCard> {
  final _likesService = LikesService();
  late bool isLiked;
  late bool isSaved;
  late bool isReposted;
  late int likeCount;
  late int repostCount;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    likeCount = widget.outfit.likes;
    repostCount = widget.outfit.shares;
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final liked = await _likesService.hasLikedPost(widget.outfit.id);
    final saved = await _likesService.hasSavedPost(widget.outfit.id);
    final reposted = await _likesService.hasReposted(widget.outfit.id);
    
    if (mounted) {
      setState(() {
        isLiked = liked;
        isSaved = saved;
        isReposted = reposted;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    // Optimistic update
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    final success = isLiked
        ? await _likesService.likePost(widget.outfit.id)
        : await _likesService.unlikePost(widget.outfit.id);

    // Revert if failed
    if (!success && mounted) {
      setState(() {
        isLiked = !isLiked;
        likeCount += isLiked ? 1 : -1;
      });
    }
  }

  Future<void> _toggleSave() async {
    setState(() {
      isSaved = !isSaved;
    });

    final success = isSaved
        ? await _likesService.savePost(widget.outfit.id)
        : await _likesService.unsavePost(widget.outfit.id);

    if (!success && mounted) {
      setState(() {
        isSaved = !isSaved;
      });
    }
  }

  Future<void> _toggleRepost() async {
    // Optimistic update
    setState(() {
      isReposted = !isReposted;
      repostCount += isReposted ? 1 : -1;
    });

    final success = isReposted
        ? await _likesService.repostPost(widget.outfit.id)
        : await _likesService.unrepostPost(widget.outfit.id);

    // Revert if failed
    if (!success && mounted) {
      setState(() {
        isReposted = !isReposted;
        repostCount += isReposted ? 1 : -1;
      });
    } else if (success && isReposted && mounted) {
      // Show confirmation snackbar when reposted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reposted to your profile'),
          backgroundColor: Color(0xFF2D5F4C),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OutfitDetailScreen(
                  outfit: widget.outfit,
                  onNavigateToPutOns: () {
                    mainScreenKey.currentState?.navigateToPutOns();
                  },
                ),
              ),
            ),
            child: Image.network(
              widget.outfit.imageUrl,
              width: double.infinity,
              height: 400,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 400,
                color: Colors.grey[900],
                child: const Icon(Icons.broken_image, color: Colors.white24),
              ),
            ),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GestureDetector(
        onTap: () => widget.onProfileTap(widget.outfit.userId),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF2D5F4C),
              child: Text(
                widget.outfit.userName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.outfit.userName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Like Button
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.white,
                ),
                onPressed: _toggleLike,
              ),
              Text('$likeCount', style: const TextStyle(color: Colors.white)),
              const SizedBox(width: 16),
              // Repost Button
              IconButton(
                icon: Icon(
                  Icons.repeat,
                  color: isReposted ? const Color(0xFF2D5F4C) : Colors.white,
                ),
                onPressed: _toggleRepost,
              ),
              Text('$repostCount', style: const TextStyle(color: Colors.white)),
            ],
          ),
          // Save Button
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved ? const Color(0xFF2D5F4C) : Colors.white,
            ),
            onPressed: _toggleSave,
          ),
        ],
      ),
    );
  }
}