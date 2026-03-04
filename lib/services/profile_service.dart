import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class ProfileService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get current user's profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return response;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  // Get user stats (posts, followers, following)
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      // Count user's posts
      final postsResponse = await _supabase
          .from('outfits')
          .select('id')
          .eq('user_id', userId);

      final postsCount = (postsResponse as List).length;

      // Count followers
      final followersResponse = await _supabase
          .from('followers')
          .select('id')
          .eq('following_id', userId);

      final followersCount = (followersResponse as List).length;

      // Count following
      final followingResponse = await _supabase
          .from('followers')
          .select('id')
          .eq('follower_id', userId);

      final followingCount = (followingResponse as List).length;

      return {
        'posts': postsCount,
        'followers': followersCount,
        'following': followingCount,
      };
    } catch (e) {
      print('Error fetching stats: $e');
      return {
        'posts': 0,
        'followers': 0,
        'following': 0,
      };
    }
  }

  // Update profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Upload profile picture
  Future<String?> uploadProfilePicture(Uint8List fileBytes, String fileName) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '$userId-$timestamp-$fileName';
      
      await _supabase.storage
          .from('avatars')
          .uploadBinary(uniqueFileName, fileBytes);

      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(uniqueFileName);

      // Update profile with new avatar URL
      await updateProfile({'avatar_url': publicUrl});

      return publicUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  // Delete profile picture
  Future<bool> deleteProfilePicture(String avatarUrl) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      // Extract file name from URL
      final uri = Uri.parse(avatarUrl);
      final fileName = uri.pathSegments.last;

      await _supabase.storage
          .from('avatars')
          .remove([fileName]);

      // Update profile to remove avatar URL
      await updateProfile({'avatar_url': null});

      return true;
    } catch (e) {
      print('Error deleting profile picture: $e');
      return false;
    }
  }
}