import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_service.dart';
import 'user_profile_screen.dart';
import 'profile_screen.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;
  final String initialTab; // 'followers' or 'following'
  final String username;

  const FollowersScreen({
    super.key,
    required this.userId,
    required this.initialTab,
    required this.username,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen>
    with SingleTickerProviderStateMixin {
  final _userService = UserService();
  final supabase = Supabase.instance.client;
  
  late TabController _tabController;
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];
  Map<String, bool> _followingStatus = {};
  bool _isLoadingFollowers = true;
  bool _isLoadingFollowing = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'following' ? 1 : 0,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadFollowers(),
      _loadFollowing(),
    ]);
    await _loadFollowingStatus();
  }

  Future<void> _loadFollowers() async {
    setState(() => _isLoadingFollowers = true);
    final followers = await _userService.getFollowers(widget.userId);
    if (mounted) {
      setState(() {
        _followers = followers;
        _isLoadingFollowers = false;
      });
    }
  }

  Future<void> _loadFollowing() async {
    setState(() => _isLoadingFollowing = true);
    final following = await _userService.getFollowing(widget.userId);
    if (mounted) {
      setState(() {
        _following = following;
        _isLoadingFollowing = false;
      });
    }
  }

  Future<void> _loadFollowingStatus() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    // Get following status for all users in both lists
    final allUsers = {..._followers, ..._following};
    
    for (var user in allUsers) {
      final userId = user['id'] as String;
      if (userId != currentUserId) {
        final isFollowing = await _userService.isFollowing(userId);
        if (mounted) {
          setState(() {
            _followingStatus[userId] = isFollowing;
          });
        }
      }
    }
  }

  Future<void> _toggleFollow(String userId) async {
    final currentStatus = _followingStatus[userId] ?? false;
    
    // Optimistic update
    setState(() {
      _followingStatus[userId] = !currentStatus;
    });

    final success = !currentStatus
        ? await _userService.followUser(userId)
        : await _userService.unfollowUser(userId);

    if (!success && mounted) {
      // Revert on failure
      setState(() {
        _followingStatus[userId] = currentStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update follow status'),
          backgroundColor: Colors.red,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
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
          '@${widget.username}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: '${_followers.length} Followers'),
            Tab(text: '${_following.length} Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFollowersList(),
          _buildFollowingList(),
        ],
      ),
    );
  }

  Widget _buildFollowersList() {
    if (_isLoadingFollowers) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2D5F4C)),
      );
    }

    if (_followers.isEmpty) {
      return _buildEmptyState('No followers yet');
    }

    return ListView.builder(
      itemCount: _followers.length,
      itemBuilder: (context, index) {
        return _buildUserTile(_followers[index]);
      },
    );
  }

  Widget _buildFollowingList() {
    if (_isLoadingFollowing) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2D5F4C)),
      );
    }

    if (_following.isEmpty) {
      return _buildEmptyState('Not following anyone yet');
    }

    return ListView.builder(
      itemCount: _following.length,
      itemBuilder: (context, index) {
        return _buildUserTile(_following[index]);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final userId = user['id'] as String;
    final username = user['username'] as String;
    final fullName = user['full_name'] as String?;
    final avatarUrl = user['avatar_url'] as String?;
    final currentUserId = supabase.auth.currentUser?.id;
    final isCurrentUser = userId == currentUserId;
    final isFollowing = _followingStatus[userId] ?? false;

    return InkWell(
      onTap: () => _navigateToProfile(userId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade900),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF2D5F4C),
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      (fullName ?? username)[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName ?? username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@$username',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Follow button
            if (!isCurrentUser)
              SizedBox(
                width: 100,
                child: OutlinedButton(
                  onPressed: () => _toggleFollow(userId),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isFollowing ? Colors.transparent : const Color(0xFF2D5F4C),
                    foregroundColor: isFollowing ? Colors.white : Colors.white,
                    side: BorderSide(
                      color: isFollowing ? Colors.white : const Color(0xFF2D5F4C),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}