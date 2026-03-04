import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/user_service.dart';
import '../services/likes_service.dart';
import 'outfit_detail_screen.dart';
import 'followers_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _userService = UserService();
  // ignore: unused_field
  final _likesService = LikesService();
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? _profileData;
  bool _isFollowing = false;
  int _followerCount = 0;
  int _followingCount = 0;
  int _postsCount = 0;
  bool _isLoading = true;
  bool _isLoadingPosts = false;
  List<Outfit> _currentPosts = [];
  String selectedTab = 'Posts';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoadingPosts = true);
    
    try {
      final posts = await _fetchUserPosts();
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
    setState(() => _isLoading = true);

    try {
      final profile = await _userService.getUserProfile(widget.userId);
      final isFollowing = await _userService.isFollowing(widget.userId);
      final followerCount = await _userService.getFollowerCount(widget.userId);
      final followingCount = await _userService.getFollowingCount(widget.userId);
      final postsCount = await _userService.getUserPostsCount(widget.userId);

      if (mounted) {
        setState(() {
          _profileData = profile;
          _isFollowing = isFollowing;
          _followerCount = followerCount;
          _followingCount = followingCount;
          _postsCount = postsCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    setState(() {
      _isFollowing = !_isFollowing;
      _followerCount += _isFollowing ? 1 : -1;
    });

    final success = _isFollowing
        ? await _userService.followUser(widget.userId)
        : await _userService.unfollowUser(widget.userId);

    if (!success && mounted) {
      setState(() {
        _isFollowing = !_isFollowing;
        _followerCount += _isFollowing ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update follow status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<Outfit>> _fetchUserPosts() async {
    try {
      final response = await supabase
          .from('outfits')
          .select()
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Outfit.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching user posts: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2D5F4C)),
        ),
      );
    }

    final fullName = _profileData?['full_name'] ?? 'User';
    final username = _profileData?['username'] ?? 'username';
    final avatarUrl = _profileData?['avatar_url'];
    final bio = _profileData?['bio'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5F4C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '@$username',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: const BoxDecoration(color: Color(0xFF2D5F4C)),
            child: Column(
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
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
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat(_postsCount.toString(), 'Posts'),
                    _buildStat(_followerCount.toString(), 'Followers'),
                    _buildStat(_followingCount.toString(), 'Following'),
                  ],
                ),
                const SizedBox(height: 20),
                // Follow Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing ? Colors.white : const Color(0xFFFF6B35),
                        foregroundColor: _isFollowing ? const Color(0xFF2D5F4C) : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        _isFollowing ? 'Following' : 'Follow',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tabs
          Container(
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                _buildTab('Posts'),
                _buildTab('Liked'),
              ],
            ),
          ),
          // Posts Grid
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
    if (_currentPosts.isEmpty) {
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
          ],
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
      itemCount: _currentPosts.length,
      itemBuilder: (context, index) {
        return _buildPostItem(_currentPosts[index]);
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

  Widget _buildStat(String value, String label) {
    final username = _profileData?['username'] ?? 'username';
    
    return GestureDetector(
      onTap: () async {
        if (label == 'Followers' || label == 'Following') {
          // Navigate and wait for result
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FollowersScreen(
                userId: widget.userId,
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

  Widget _buildTab(String title) {
    final isSelected = selectedTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedTab = title);
          _loadPosts();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostItem(Outfit outfit) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OutfitDetailScreen(outfit: outfit),
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
}