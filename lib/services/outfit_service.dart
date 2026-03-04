import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';

class OutfitService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final _uuid = Uuid();

  // Create a new outfit
  Future<bool> createOutfit({
    required String name,
    required List<String> itemIds,
    File? coverImageFile,
    String? description,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      String? coverImageUrl;
      
      // Upload cover image if provided
      if (coverImageFile != null) {
        coverImageUrl = await _uploadCoverImage(coverImageFile);
        if (coverImageUrl == null) {
          print('Failed to upload cover image');
          return false;
        }
      }

      final outfitId = _uuid.v4();

      await _supabase.from('saved_outfits').insert({
        'id': outfitId,
        'user_id': userId,
        'name': name,
        'description': description ?? '',
        'cover_image_url': coverImageUrl ?? '',
        'item_ids': itemIds,
      });

      return true;
    } catch (e) {
      print('Error creating outfit: $e');
      return false;
    }
  }

  // Get all outfits for the current user
  Future<List<Map<String, dynamic>>> getUserOutfits() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('saved_outfits')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching outfits: $e');
      return [];
    }
  }

  // Get a single outfit with all item details
  Future<Map<String, dynamic>?> getOutfitWithItems(String outfitId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final outfitResponse = await _supabase
          .from('saved_outfits')
          .select()
          .eq('id', outfitId)
          .eq('user_id', userId)
          .single();

      final itemIds = List<String>.from(outfitResponse['item_ids'] ?? []);
      List<ClothingItem> items = [];

      // Fetch items from wardrobe
      if (itemIds.isNotEmpty) {
        final wardrobeResponse = await _supabase
            .from('wardrobe')
            .select()
            .eq('user_id', userId)
            .inFilter('item_id', itemIds);

        items.addAll((wardrobeResponse as List).map((json) {
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
            notes: json['notes'],
          );
        }).toList());

        // Fetch items from putons
        final putOnsResponse = await _supabase
            .from('putons')
            .select()
            .eq('user_id', userId)
            .inFilter('item_id', itemIds);

        items.addAll((putOnsResponse as List).map((json) {
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
            notes: json['notes'],
          );
        }).toList());
      }

      return {
        'outfit': outfitResponse,
        'items': items,
      };
    } catch (e) {
      print('Error fetching outfit with items: $e');
      return null;
    }
  }

  // Update an outfit
  Future<bool> updateOutfit({
    required String outfitId,
    String? name,
    String? description,
    List<String>? itemIds,
    File? newCoverImageFile,
    String? coverImageUrl,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      Map<String, dynamic> updates = {};

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (itemIds != null) updates['item_ids'] = itemIds;

      // Handle cover image update
      if (coverImageUrl != null) {
        // User explicitly set cover image URL (empty string means remove)
        updates['cover_image_url'] = coverImageUrl;
      } else if (newCoverImageFile != null) {
        // Upload new cover image if provided
        final imageUrl = await _uploadCoverImage(newCoverImageFile);
        if (imageUrl != null) {
          updates['cover_image_url'] = imageUrl;
        }
      }

      if (updates.isEmpty) return true;

      await _supabase
          .from('saved_outfits')
          .update(updates)
          .eq('id', outfitId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error updating outfit: $e');
      return false;
    }
  }

  // Delete an outfit
  Future<bool> deleteOutfit(String outfitId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabase
          .from('saved_outfits')
          .delete()
          .eq('id', outfitId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error deleting outfit: $e');
      return false;
    }
  }

  // Upload cover image to Supabase storage
  Future<String?> _uploadCoverImage(File imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final fileExt = imageFile.path.split('.').last;
      final fileName = '${_uuid.v4()}.$fileExt';
      final filePath = 'saved_outfits/$userId/$fileName';

      await _supabase.storage
          .from('virtual_wardrobe')
          .upload(filePath, imageFile);

      final imageUrl = _supabase.storage
          .from('virtual_wardrobe')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      print('Error uploading cover image: $e');
      return null;
    }
  }
}