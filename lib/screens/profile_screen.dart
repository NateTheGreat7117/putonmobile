import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/profile_service.dart';
import 'settings_screen.dart';
import 'outfit_detail_screen.dart';
import '../services/likes_service.dart';
import 'create_post_screen.dart';
import 'followers_screen.dart';
import '../main.dart'; // Import to access mainScreenKey


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String selectedTab = 'My Posts';
  final supabase = Supabase.instance.client;
  final _profileService = ProfileService();
  // ignore: unused_field
  final _likesService = LikesService();
  
  Map<String, dynamic>? _profileData;
  Map<String, int> _stats = {
    'posts': 0,
    'followers': 0,
    'following': 0,
  };
  bool _isLoadingProfile = true;
  bool _isLoadingPosts = false;
  List<Outfit> _currentPosts = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoadingPosts = true);
    
    try {
      final posts = await _fetchProfileData();
      if (mounted) {
        setState(() {
          _currentPosts = posts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      print('Error loading posts: $e');
      if (mounted) {
        setState(() => _isLoadingPosts = false);
      }
    }
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoadingProfile = true);

    try {
      final profile = await _profileService.getCurrentUserProfile();
      final userId = supabase.auth.currentUser?.id;
      
      if (userId != null) {
        final stats = await _profileService.getUserStats(userId);
        setState(() {
          _profileData = profile;
          _stats = stats;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() => _isLoadingProfile = false);
    }
  }

  // This function fetches data based on which tab is clicked
  Future<List<Outfit>> _fetchProfileData() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      if (selectedTab == 'My Posts') {
        final response = await supabase
            .from('outfits')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        return (response as List).map((json) => Outfit.fromJson(json)).toList();
      } else if (selectedTab == 'Liked') {
        // Get liked outfit IDs
        final likedIds = await _likesService.getLikedPostIds();
        if (likedIds.isEmpty) return [];
        
        // Fetch the actual outfits
        final response = await supabase
            .from('outfits')
            .select()
            .inFilter('id', likedIds);
        
        return (response as List).map((json) => Outfit.fromJson(json)).toList();
      } else if (selectedTab == 'Favorited') {
        // Get saved outfit IDs
        final savedIds = await _likesService.getSavedPostIds();
        if (savedIds.isEmpty) return [];
        
        // Fetch the actual outfits
        final response = await supabase
            .from('outfits')
            .select()
            .inFilter('id', savedIds);
        
        return (response as List).map((json) => Outfit.fromJson(json)).toList();
      } else if (selectedTab == 'Reposted') {
        // Get reposted outfit IDs
        final repostedIds = await _likesService.getRepostedPostIds();
        if (repostedIds.isEmpty) return [];
        
        // Fetch the actual outfits
        final response = await supabase
            .from('outfits')
            .select()
            .inFilter('id', repostedIds);
        
        return (response as List).map((json) => Outfit.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching outfits: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5F4C),
        elevation: 0,
        title: const Text(
          'PROFILE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePostScreen()),
              );
              // Reload profile if post was created
              if (result == true) {
                _loadProfileData();
                _loadPosts();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              // Reload profile if settings were changed
              if (result == true) {
                _loadProfileData();
              }
            },
          ),
        ],
      ),
      body: _isLoadingProfile
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2D5F4C),
              ),
            )
          : Column(
              children: [
                _buildHeader(),
                _buildTabSystem(),
                Expanded(
                  child: _isLoadingPosts
                      ? _buildLoadingGrid()
                      : _buildPostsGrid(),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.7,
      ),
      itemCount: 12, // Show 12 placeholder boxes
      itemBuilder: (context, index) {
        return _buildLoadingPlaceholder();
      },
    );
  }

  Widget _buildPostsGrid() {
    if (_currentPosts.isEmpty && selectedTab == 'My Posts') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your first outfit!',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                );
                if (result == true) {
                  _loadProfileData();
                  _loadPosts();
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF2D5F4C),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Create Post',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_currentPosts.isEmpty) {
      return Center(
        child: Text(
          'No posts in $selectedTab',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.7,
      ),
      itemCount: _currentPosts.length + (selectedTab == 'My Posts' ? 1 : 0),
      itemBuilder: (context, index) {
        if (selectedTab == 'My Posts' && index == 0) {
          return _buildAddPostButton();
        }
        final outfitIndex = selectedTab == 'My Posts' ? index - 1 : index;
        return _buildPostItem(_currentPosts[outfitIndex]);
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: const Color(0xFF2D5F4C).withOpacity(0.5),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final fullName = _profileData?['full_name'] ?? 'User';
    final username = _profileData?['username'] ?? 'username';
    final avatarUrl = _profileData?['avatar_url'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(color: Color(0xFF2D5F4C)),
      child: Column(
        children: [
          // Profile Picture
          GestureDetector(
            onTap: () {
              // TODO: Implement image picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Photo upload coming soon!'),
                  backgroundColor: Color(0xFF2D5F4C),
                ),
              );
            },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          fullName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D5F4C),
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Color(0xFF2D5F4C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '@$username',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat(_stats['posts'].toString(), 'Posts'),
              _buildStat(_stats['followers'].toString(), 'Followers'),
              _buildStat(_stats['following'].toString(), 'Following'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSystem() {
    final tabs = ['My Posts', 'Liked', 'Favorited', 'Reposted'];
    return Container(
      color: const Color(0xFF1A1A1A),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) => _buildTab(tab)).toList(),
        ),
      ),
    );
  }

  Widget _buildTab(String title) {
    final isSelected = selectedTab == title;
    return GestureDetector(
      onTap: () {
        setState(() => selectedTab = title);
        _loadPosts();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF2D5F4C) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAddPostButton() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        );
        if (result == true) {
          _loadProfileData();
          _loadPosts();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2D5F4C),
            width: 2,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 40, color: Color(0xFF2D5F4C)),
            SizedBox(height: 8),
            Text(
              'Create',
              style: TextStyle(
                color: Color(0xFF2D5F4C),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostItem(Outfit outfit) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OutfitDetailScreen(
            outfit: outfit,
            onNavigateToPutOns: () {
              mainScreenKey.currentState?.navigateToPutOns();
            },
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: outfit.imageUrl,
          fit: BoxFit.cover,
          // Add thumbnail URL if you have one for faster loading
          // imageUrl: outfit.thumbnailUrl ?? outfit.imageUrl,
          memCacheWidth: 400, // Resize for grid (saves memory)
          placeholder: (context, url) => Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: const Color(0xFF2D5F4C).withOpacity(0.5),
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey.shade900,
            child: const Icon(
              Icons.broken_image,
              color: Colors.white24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    final userId = supabase.auth.currentUser?.id;
    final username = _profileData?['username'] ?? 'username';
    
    return GestureDetector(
      onTap: () async {
        if (label == 'Followers' || label == 'Following') {
          // Navigate and wait for result
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FollowersScreen(
                userId: userId!,
                initialTab: label.toLowerCase(),
                username: username,
              ),
            ),
          );
          // Reload profile data when returning
          _loadProfileData();
        }
      },
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}