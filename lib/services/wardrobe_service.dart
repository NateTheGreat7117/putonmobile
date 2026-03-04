import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';

class WardrobeService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final _uuid = Uuid();

  // Add a single item to user's wardrobe
  Future<bool> addWardrobeItem({
    required String name,
    required String category,
    String? brand,
    String? color,
    String? size,
    String? material,
    double? price,
    String? purchaseUrl,
    File? imageFile,
    String? notes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      String? imageUrl;
      
      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile);
        if (imageUrl == null) {
          print('Failed to upload image');
          return false;
        }
      }

      final itemId = _uuid.v4();

      await _supabase.from('wardrobe').insert({
        'user_id': userId,
        'item_id': itemId,
        'name': name,
        'brand': brand ?? '',
        'color': color ?? '',
        'size': size ?? '',
        'category': category,
        'image_url': imageUrl ?? '',
        'min_price': price ?? 0,
        'max_price': price ?? 0,
        'purchase_url': purchaseUrl ?? '',
        'notes': notes,
      });

      return true;
    } catch (e) {
      print('Error adding wardrobe item: $e');
      return false;
    }
  }

  // Bulk add items (just images, minimal info)
  Future<List<String>> bulkAddItems(List<File> imageFiles) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    List<String> addedItemIds = [];

    for (var imageFile in imageFiles) {
      try {
        final imageUrl = await _uploadImage(imageFile);
        if (imageUrl == null) continue;

        final itemId = _uuid.v4();

        await _supabase.from('wardrobe').insert({
          'user_id': userId,
          'item_id': itemId,
          'name': 'Untitled Item',
          'brand': '',
          'color': '',
          'size': '',
          'category': 'Uncategorized',
          'image_url': imageUrl,
          'min_price': 0,
          'max_price': 0,
          'purchase_url': '',
          'notes': 'Added via bulk upload - needs editing',
        });

        addedItemIds.add(itemId);
      } catch (e) {
        print('Error adding item in bulk: $e');
      }
    }

    return addedItemIds;
  }

  // Update an existing wardrobe item
  Future<bool> updateWardrobeItem({
    required String itemId,
    String? name,
    String? category,
    String? brand,
    String? color,
    String? size,
    String? material,
    double? minPrice,
    double? maxPrice,
    String? purchaseUrl,
    File? newImageFile,
    String? notes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

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
      if (notes != null) updates['notes'] = notes;

      // Upload new image if provided
      if (newImageFile != null) {
        final imageUrl = await _uploadImage(newImageFile);
        if (imageUrl != null) {
          updates['image_url'] = imageUrl;
        }
      }

      if (updates.isEmpty) return true;

      await _supabase
          .from('wardrobe')
          .update(updates)
          .eq('user_id', userId)
          .eq('item_id', itemId);

      return true;
    } catch (e) {
      print('Error updating wardrobe item: $e');
      return false;
    }
  }

  // Delete a wardrobe item
  Future<bool> deleteWardrobeItem(String itemId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabase
          .from('wardrobe')
          .delete()
          .eq('user_id', userId)
          .eq('item_id', itemId);
      return true;
    } catch (e) {
      print('Error deleting wardrobe item: $e');
      return false;
    }
  }

  // Get all wardrobe items for the current user
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

  // Get a single wardrobe item
  Future<ClothingItem?> getWardrobeItem(String itemId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('wardrobe')
          .select()
          .eq('user_id', userId)
          .eq('item_id', itemId)
          .single();

      return ClothingItem(
        id: response['item_id'],
        name: response['name'],
        brand: response['brand'],
        color: response['color'],
        size: response['size'],
        category: response['category'],
        imageUrl: response['image_url'],
        minPrice: (response['min_price'] as num).toDouble(),
        maxPrice: (response['max_price'] as num).toDouble(),
        purchaseUrl: response['purchase_url'],
        notes: response['notes'], // ADD THIS LINE
      );
    } catch (e) {
      print('Error fetching wardrobe item: $e');
      return null;
    }
  }

  // Upload image to Supabase storage
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final fileExt = imageFile.path.split('.').last;
      final fileName = '${_uuid.v4()}.$fileExt';
      final filePath = '$userId/$fileName';

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
}