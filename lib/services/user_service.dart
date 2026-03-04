import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class UserService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get user profile by ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Get user profile by username
  Future<Map<String, dynamic>?> getUserProfileByUsername(String username) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('username', username)
          .single();
      
      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Search users by username or full name
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Check if current user is following another user
  Future<bool> isFollowing(String userId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    try {
      final response = await _supabase
          .from('followers')
          .select()
          .eq('follower_id', currentUserId)
          .eq('following_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  // Follow a user
  Future<bool> followUser(String userId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    try {
      // Check if already following
      final alreadyFollowing = await isFollowing(userId);
      if (alreadyFollowing) return true;

      await _supabase.from('followers').insert({
        'follower_id': currentUserId,
        'following_id': userId,
      });

      return true;
    } catch (e) {
      print('Error following user: $e');
      return false;
    }
  }

  // Unfollow a user
  Future<bool> unfollowUser(String userId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    try {
      await _supabase
          .from('followers')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', userId);

      return true;
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }

  // Get follower count for a user
  Future<int> getFollowerCount(String userId) async {
    try {
      final response = await _supabase
          .from('followers')
          .select()
          .eq('following_id', userId);

      return (response as List).length;
    } catch (e) {
      print('Error getting follower count: $e');
      return 0;
    }
  }

  // Get following count for a user
  Future<int> getFollowingCount(String userId) async {
    try {
      final response = await _supabase
          .from('followers')
          .select()
          .eq('follower_id', userId);

      return (response as List).length;
    } catch (e) {
      print('Error getting following count: $e');
      return 0;
    }
  }

  // Get user's posts count
  Future<int> getUserPostsCount(String userId) async {
    try {
      final response = await _supabase
          .from('outfits')
          .select()
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      print('Error getting posts count: $e');
      return 0;
    }
  }

  // Get list of followers for a user
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      final response = await _supabase
          .from('followers')
          .select('follower_id')
          .eq('following_id', userId);

      final followerIds = (response as List)
          .map((item) => item['follower_id'] as String)
          .toList();

      if (followerIds.isEmpty) return [];

      // Fetch profile data for all followers
      final profiles = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', followerIds);

      return List<Map<String, dynamic>>.from(profiles);
    } catch (e) {
      print('Error fetching followers: $e');
      return [];
    }
  }

  // Get list of users that a user is following
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      final response = await _supabase
          .from('followers')
          .select('following_id')
          .eq('follower_id', userId);

      final followingIds = (response as List)
          .map((item) => item['following_id'] as String)
          .toList();

      if (followingIds.isEmpty) return [];

      // Fetch profile data for all following
      final profiles = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', followingIds);

      return List<Map<String, dynamic>>.from(profiles);
    } catch (e) {
      print('Error fetching following: $e');
      return [];
    }
  }
}