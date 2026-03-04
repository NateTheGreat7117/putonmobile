import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';
import 'dart:io';

class LikesService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Check if user has liked a post
  Future<bool> hasLikedPost(String outfitId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _supabase
          .from('likes')
          .select()
          .eq('user_id', userId)
          .eq('outfit_id', outfitId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }

  // Like a post
  Future<bool> likePost(String outfitId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      // Check if already liked to prevent duplicate error
      final alreadyLiked = await hasLikedPost(outfitId);
      if (alreadyLiked) {
        print('Post already liked');
        return true; // Return true since the desired state is achieved
      }

      await _supabase.from('likes').insert({
        'user_id': userId,
        'outfit_id': outfitId,
      });

      // Increment likes count in outfits table
      try {
        await _supabase.rpc('increment_likes', params: {'outfit_id_param': outfitId});
      } catch (e) {
        print('Error incrementing likes: $e');
      }

      return true;
    } catch (e) {
      print('Error liking post: $e');
      return false;
    }
  }

  // Unlike a post
  Future<bool> unlikePost(String outfitId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      // Delete the like
      await _supabase
          .from('likes')
          .delete()
          .eq('user_id', userId.toString())
          .eq('outfit_id', outfitId);

      // Decrement likes count in outfits table
      try {
        await _supabase.rpc('decrement_likes', params: {'outfit_id_param': outfitId});
      } catch (e) {
        print('Error decrementing likes: $e');
      }

      return true;
    } catch (e) {
      print('Error unliking post: $e');
      return false;
    }
  }

  // Get posts liked by user
  Future<List<String>> getLikedPostIds() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('likes')
          .select('outfit_id')
          .eq('user_id', userId);

      return (response as List).map((item) => item['outfit_id'] as String).toList();
    } catch (e) {
      print('Error fetching liked posts: $e');
      return [];
    }
  }

  // Get like count for a post
  Future<int> getLikeCount(String outfitId) async {
    try {
      final response = await _supabase
          .from('likes')
          .select()
          .eq('outfit_id', outfitId);

      return (response as List).length;
    } catch (e) {
      print('Error fetching like count: $e');
      return 0;
    }
  }

  // Save a post
  Future<bool> savePost(String outfitId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      // Check if already saved
      final alreadySaved = await hasSavedPost(outfitId);
      if (alreadySaved) {
        return true;
      }

      await _supabase.from('saved_posts').insert({
        'user_id': userId,
        'outfit_id': outfitId,
      });
      return true;
    } catch (e) {
      print('Error saving post: $e');
      return false;
    }
  }

  // Unsave a post
  Future<bool> unsavePost(String outfitId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabase
          .from('saved_posts')
          .delete()
          .eq('user_id', userId.toString())
          .eq('outfit_id', outfitId);
      return true;
    } catch (e) {
      print('Error unsaving post: $e');
      return false;
    }
  }

  // Check if user has saved a post
  Future<bool> hasSavedPost(String outfitId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _supabase
          .from('saved_posts')
          .select()
          .eq('user_id', userId)
          .eq('outfit_id', outfitId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking saved status: $e');
      return false;
    }
  }

  // Get saved post IDs
  Future<List<String>> getSavedPostIds() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('saved_posts')
          .select('outfit_id')
          .eq('user_id', userId);

      return (response as List).map((item) => item['outfit_id'] as String).toList();
    } catch (e) {
      print('Error fetching saved posts: $e');
      return [];
    }
  }

  // Check if user has reposted
  Future<bool> hasReposted(String outfitId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _supabase
          .from('reposts')
          .select()
          .eq('user_id', userId)
          .eq('outfit_id', outfitId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking repost status: $e');
      return false;
    }
  }

  // Repost a post
  Future<bool> repostPost(String outfitId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      // Check if already reposted
      final alreadyReposted = await hasReposted(outfitId);
      if (alreadyReposted) {
        return true;
      }

      await _supabase.from('reposts').insert({
        'user_id': userId,
        'outfit_id': outfitId,
      });

      // Increment reposts count (shares column)
      try {
        await _supabase.rpc('increment_reposts', params: {'outfit_id_param': outfitId});
      } catch (e) {
        print('Error incrementing reposts: $e');
      }

      return true;
    } catch (e) {
      print('Error reposting post: $e');
      return false;
    }
  }

  // Unrepost a post
  Future<bool> unrepostPost(String outfitId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabase
          .from('reposts')
          .delete()
          .eq('user_id', userId.toString())
          .eq('outfit_id', outfitId);

      // Decrement reposts count (shares column)
      try {
        await _supabase.rpc('decrement_reposts', params: {'outfit_id_param': outfitId});
      } catch (e) {
        print('Error decrementing reposts: $e');
      }

      return true;
    } catch (e) {
      print('Error unreposting post: $e');
      return false;
    }
  }

  // Get reposted post IDs
  Future<List<String>> getRepostedPostIds() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('reposts')
          .select('outfit_id')
          .eq('user_id', userId);

      return (response as List).map((item) => item['outfit_id'] as String).toList();
    } catch (e) {
      print('Error fetching reposted posts: $e');
      return [];
    }
  }

  // Add to Put Ons (Wishlist)
  Future<bool> addToPutOns(ClothingItem item) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      // Check if already in Put Ons
      final alreadyAdded = await isInPutOns(item.id);
      if (alreadyAdded) {
        return true;
      }

      await _supabase.from('putons').insert({
        'user_id': userId,
        'item_id': item.id,
        'name': item.name,
        'brand': item.brand,
        'color': item.color,
        'size': item.size,
        'category': item.category,
        'image_url': item.imageUrl,
        'min_price': item.minPrice,
        'max_price': item.maxPrice,
        'purchase_url': item.purchaseUrl,
      });
      return true;
    } catch (e) {
      print('Error adding to Put Ons: $e');
      return false;
    }
  }

  // Remove from Put Ons
  Future<bool> removeFromPutOns(String itemId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabase
          .from('putons')
          .delete()
          .eq('user_id', userId.toString())
          .eq('item_id', itemId);
      return true;
    } catch (e) {
      print('Error removing from Put Ons: $e');
      return false;
    }
  }

  // Check if item is in Put Ons
  Future<bool> isInPutOns(String itemId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _supabase
          .from('putons')
          .select()
          .eq('user_id', userId)
          .eq('item_id', itemId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking Put Ons status: $e');
      return false;
    }
  }

  // Get all Put Ons items for user
  Future<List<ClothingItem>> getPutOnsItems() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('putons')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        return ClothingItem(
          id: json['item_id'],
          name: json['name'],
          brand: json['brand'],
          color: json['color'],
          size: json['size'],
          category: json['category'],
          imageUrl: json['image_url'],
          minPrice: (json['min_price'] as num).toDouble(),
          maxPrice: (json['max_price'] as num).toDouble(),
          purchaseUrl: json['purchase_url'],
          notes: json['notes'], // ADD THIS LINE (even though Put Ons may not use it)
        );
      }).toList();
    } catch (e) {
      print('Error fetching Put Ons items: $e');
      return [];
    }
  }

  // Add to Wardrobe
  Future<bool> addToWardrobe(ClothingItem item, {String? notes}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      // Check if already in wardrobe
      final alreadyAdded = await isInWardrobe(item.id);
      if (alreadyAdded) {
        return true;
      }

      await _supabase.from('wardrobe').insert({
        'user_id': userId,
        'item_id': item.id,
        'name': item.name,
        'brand': item.brand,
        'color': item.color,
        'size': item.size,
        'category': item.category,
        'image_url': item.imageUrl,
        'min_price': item.minPrice,
        'max_price': item.maxPrice,
        'purchase_url': item.purchaseUrl,
        'notes': notes,
      });
      return true;
    } catch (e) {
      print('Error adding to wardrobe: $e');
      return false;
    }
  }

  // Remove from Wardrobe
  Future<bool> removeFromWardrobe(String itemId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabase
          .from('wardrobe')
          .delete()
          .eq('user_id', userId.toString())
          .eq('item_id', itemId);
      return true;
    } catch (e) {
      print('Error removing from wardrobe: $e');
      return false;
    }
  }

  // Check if item is in Wardrobe
  Future<bool> isInWardrobe(String itemId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _supabase
          .from('wardrobe')
          .select()
          .eq('user_id', userId)
          .eq('item_id', itemId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking wardrobe status: $e');
      return false;
    }
  }

  // Get all Wardrobe items for user
  Future<List<ClothingItem>> getWardrobeItems() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('wardrobe')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        return ClothingItem(
          id: json['item_id'],
          name: json['name'],
          brand: json['brand'],
          color: json['color'],
          size: json['size'],
          category: json['category'],
          imageUrl: json['image_url'],
          minPrice: (json['min_price'] as num).toDouble(),
          maxPrice: (json['max_price'] as num).toDouble(),
          purchaseUrl: json['purchase_url'],
          notes: json['notes'], // ADD THIS LINE
        );
      }).toList();
    } catch (e) {
      print('Error fetching wardrobe items: $e');
      return [];
    }
  }

  // Move item from Put Ons to Wardrobe
  Future<bool> movePutOnToWardrobe(ClothingItem item) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      // Add to wardrobe
      final addSuccess = await addToWardrobe(item);
      if (!addSuccess) return false;

      // Remove from put ons
      final removeSuccess = await removeFromPutOns(item.id);
      return removeSuccess;
    } catch (e) {
      print('Error moving to wardrobe: $e');
      return false;
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/putons/$fileName';

      await _supabase.storage
          .from('virtual_wardrobe')
          .upload(filePath, imageFile);

      final imageUrl = _supabase.storage
          .from('virtual_wardrobe')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Update an existing Put On item
    /// Update an existing Put On item
    /// Update an existing Put On item
  Future<bool> updatePutOnItem({
    required String itemId,
    String? name,
    String? category,
    String? brand,
    String? color,
    String? size,
    double? minPrice,
    double? maxPrice,
    String? purchaseUrl,
    String? imageUrl,
    File? imageFile,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('ERROR: No user ID');
      return false;
    }

    try {
      Map<String, dynamic> updates = {};

      if (name != null) updates['name'] = name;
      if (category != null) updates['category'] = category;
      if (brand != null) updates['brand'] = brand;
      if (color != null) updates['color'] = color;
      if (size != null) updates['size'] = size;
      if (minPrice != null) updates['min_price'] = minPrice;
      if (maxPrice != null) updates['max_price'] = maxPrice;
      if (purchaseUrl != null) updates['purchase_url'] = purchaseUrl;

      // Upload new image if provided
      if (imageFile != null) {
        print('Uploading new image...');
        final uploadedUrl = await uploadImage(imageFile);
        if (uploadedUrl != null) {
          updates['image_url'] = uploadedUrl;
          print('Image uploaded: $uploadedUrl');
        } else {
          print('Image upload failed');
        }
      } else if (imageUrl != null) {
        updates['image_url'] = imageUrl;
      }

      print('Updates to apply: $updates');
      print('User ID: $userId');
      print('Item ID: $itemId (type: ${itemId.runtimeType})');

      if (updates.isEmpty) {
        print('No updates to apply');
        return true;
      }

      // Try converting itemId to int if it's a numeric string
      dynamic itemIdValue = itemId;
      final parsedInt = int.tryParse(itemId);
      if (parsedInt != null) {
        itemIdValue = parsedInt;
        print('Converting item_id to int: $itemIdValue');
      }

      final result = await _supabase
          .from('putons')
          .update(updates)
          .eq('user_id', userId)
          .eq('item_id', itemIdValue) // Use the converted value
          .select();

      print('Update result: $result');
      
      if (result.isEmpty) {
        print('WARNING: No rows were updated! Check if item exists.');
        
        // Let's verify the item exists
        final existingItem = await _supabase
            .from('putons')
            .select()
            .eq('user_id', userId)
            .eq('item_id', itemIdValue)
            .maybeSingle();
        
        print('Existing item check: $existingItem');
        return existingItem != null;
      }

      return true;
    } catch (e) {
      print('Error updating Put On item: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }
}