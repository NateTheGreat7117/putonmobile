import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';
import 'dart:io';

class BrandsService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get all brands sorted by points (ascending - lowest first for "featured brands")
  Future<List<Brand>> getBrands({bool ascending = true}) async {
    try {
      final response = await _supabase
          .from('brands')
          .select()
          .order('points', ascending: ascending);

      return (response as List).map((json) => Brand.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching brands: $e');
      return [];
    }
  }

  Future<List<String>> getFeaturedBrandNames() async {
    try {
      final response = await _supabase
          .from('brands')
          .select('name')
          .order('name', ascending: true);

      return (response as List)
          .map((item) => item['name'] as String)
          .toList();
    } catch (e) {
      print('Error fetching brand names: $e');
      return [];
    }
  }

  // Get brand of the day (brand with lowest points)
  Future<Brand?> getBrandOfTheWeek() async {
    try {
      final response = await _supabase
          .from('brands')
          .select()
          .order('points', ascending: true)
          .limit(1)
          .single();

      return Brand.fromJson(response);
    } catch (e) {
      print('Error fetching brand of the day: $e');
      return null;
    }
  }

  // Get a specific brand by ID with all customization data
  Future<Brand?> getBrand(String brandId) async {
    try {
      final response = await _supabase
          .from('brands')
          .select()
          .eq('id', brandId)
          .single();

      return Brand.fromJson(response);
    } catch (e) {
      print('Error fetching brand: $e');
      return null;
    }
  }

  // Get brand products for a specific brand
  Future<List<BrandProduct>> getBrandProducts(String brandId) async {
    try {
      final response = await _supabase
          .from('brand_products')
          .select()
          .eq('brand_id', brandId)
          .order('display_order', ascending: true);

      return (response as List)
          .map((json) => BrandProduct.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching brand products: $e');
      return [];
    }
  }

  // Get custom fields for a specific brand
  Future<List<BrandCustomField>> getBrandCustomFields(String brandId) async {
    try {
      final response = await _supabase
          .from('brand_custom_fields')
          .select()
          .eq('brand_id', brandId)
          .order('display_order', ascending: true);

      return (response as List)
          .map((json) => BrandCustomField.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching brand custom fields: $e');
      return [];
    }
  }

  // Get complete brand details (brand + products + custom fields)
  Future<Map<String, dynamic>> getBrandDetails(String brandId) async {
    try {
      final results = await Future.wait([
        getBrand(brandId),
        getBrandProducts(brandId),
        getBrandCustomFields(brandId),
      ]);

      return {
        'brand': results[0] as Brand?,
        'products': results[1] as List<BrandProduct>,
        'customFields': results[2] as List<BrandCustomField>,
      };
    } catch (e) {
      print('Error fetching brand details: $e');
      return {
        'brand': null,
        'products': <BrandProduct>[],
        'customFields': <BrandCustomField>[],
      };
    }
  }

  // Increment brand points (when a post featuring the brand gets engagement)
  Future<bool> incrementBrandPoints(String brandId, int pointsToAdd) async {
    try {
      await _supabase.rpc('increment_brand_points', params: {
        'brand_id_param': brandId,
        'points_to_add': pointsToAdd,
      });
      return true;
    } catch (e) {
      print('Error incrementing brand points: $e');
      return false;
    }
  }

  // Search brands by name
  Future<List<Brand>> searchBrands(String query) async {
    if (query.isEmpty) {
      return getBrands();
    }

    try {
      final response = await _supabase
          .from('brands')
          .select()
          .ilike('name', '%$query%')
          .order('points', ascending: true);

      return (response as List).map((json) => Brand.fromJson(json)).toList();
    } catch (e) {
      print('Error searching brands: $e');
      return [];
    }
  }

  // Get top rising brands (lowest points, gaining traction)
  Future<List<Brand>> getRisingBrands({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('brands')
          .select()
          .order('points', ascending: true)
          .limit(limit);

      return (response as List).map((json) => Brand.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching rising brands: $e');
      return [];
    }
  }

  // ============================================================================
  // ADMIN METHODS - Brand Management
  // ============================================================================

  // Admin: Add a new brand
  Future<bool> addBrand({
    required String name,
    required String logoUrl,
    required String description,
    int initialPoints = 0,
    String? heroImageUrl,
    String? tagline,
    String? ctaHeading,
    String? ctaDescription,
    String? productsSectionTitle,
  }) async {
    try {
      await _supabase.from('brands').insert({
        'name': name,
        'logo_url': logoUrl,
        'description': description,
        'points': initialPoints,
        'hero_image_url': heroImageUrl ?? '',
        'tagline': tagline ?? '',
        'cta_heading': ctaHeading ?? 'Explore Our Collection',
        'cta_description': ctaDescription ??
            'Experience innovation and performance with our complete range of products',
        'products_section_title': productsSectionTitle ?? 'Iconic Products',
      });
      return true;
    } catch (e) {
      print('Error adding brand: $e');
      return false;
    }
  }

  // Admin: Update brand
  Future<bool> updateBrand({
    required String brandId,
    String? name,
    String? logoUrl,
    String? description,
    int? points,
    String? heroImageUrl,
    String? tagline,
    String? ctaHeading,
    String? ctaDescription,
    String? productsSectionTitle,
    String? shopUrl, // ADD THIS LINE
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (logoUrl != null) updates['logo_url'] = logoUrl;
      if (description != null) updates['description'] = description;
      if (points != null) updates['points'] = points;
      if (heroImageUrl != null) updates['hero_image_url'] = heroImageUrl;
      if (tagline != null) updates['tagline'] = tagline;
      if (ctaHeading != null) updates['cta_heading'] = ctaHeading;
      if (ctaDescription != null) updates['cta_description'] = ctaDescription;
      if (productsSectionTitle != null) {
        updates['products_section_title'] = productsSectionTitle;
      }
      if (shopUrl != null) updates['shop_url'] = shopUrl; // ADD THIS LINE

      if (updates.isEmpty) return true;

      await _supabase.from('brands').update(updates).eq('id', brandId);
      return true;
    } catch (e) {
      print('Error updating brand: $e');
      return false;
    }
  }

  // Admin: Delete brand
  Future<bool> deleteBrand(String brandId) async {
    try {
      await _supabase.from('brands').delete().eq('id', brandId);
      return true;
    } catch (e) {
      print('Error deleting brand: $e');
      return false;
    }
  }

  // ============================================================================
  // ADMIN METHODS - Product Management
  // ============================================================================

  // Admin: Add product to brand
  Future<bool> addBrandProduct({
    required String brandId,
    required String name,
    required String price,
    String? imageUrl,
    String? backgroundColor,
    String? productUrl,
    int? displayOrder,
  }) async {
    try {
      await _supabase.from('brand_products').insert({
        'brand_id': brandId,
        'name': name,
        'price': price,
        'image_url': imageUrl ?? '',
        'background_color': backgroundColor ?? '#EEEEEE',
        'product_url': productUrl ?? '',
        'display_order': displayOrder ?? 0,
      });
      return true;
    } catch (e) {
      print('Error adding brand product: $e');
      return false;
    }
  }

  // Admin: Update brand product
  Future<bool> updateBrandProduct({
    required String productId,
    String? name,
    String? price,
    String? imageUrl,
    String? backgroundColor,
    String? productUrl,
    int? displayOrder,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (price != null) updates['price'] = price;
      if (imageUrl != null) updates['image_url'] = imageUrl;
      if (backgroundColor != null) updates['background_color'] = backgroundColor;
      if (productUrl != null) updates['product_url'] = productUrl;
      if (displayOrder != null) updates['display_order'] = displayOrder;

      if (updates.isEmpty) return true;

      await _supabase.from('brand_products').update(updates).eq('id', productId);
      return true;
    } catch (e) {
      print('Error updating brand product: $e');
      return false;
    }
  }

  // Admin: Delete brand product
  Future<bool> deleteBrandProduct(String productId) async {
    try {
      await _supabase.from('brand_products').delete().eq('id', productId);
      return true;
    } catch (e) {
      print('Error deleting brand product: $e');
      return false;
    }
  }

  // ============================================================================
  // ADMIN METHODS - Custom Fields Management
  // ============================================================================

  // Admin: Add custom field to brand
  Future<bool> addBrandCustomField({
    required String brandId,
    required String label,
    required String value,
    int? displayOrder,
  }) async {
    try {
      await _supabase.from('brand_custom_fields').insert({
        'brand_id': brandId,
        'label': label,
        'value': value,
        'display_order': displayOrder ?? 0,
      });
      return true;
    } catch (e) {
      print('Error adding brand custom field: $e');
      return false;
    }
  }

  // Admin: Update custom field
  Future<bool> updateBrandCustomField({
    required String fieldId,
    String? label,
    String? value,
    int? displayOrder,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (label != null) updates['label'] = label;
      if (value != null) updates['value'] = value;
      if (displayOrder != null) updates['display_order'] = displayOrder;

      if (updates.isEmpty) return true;

      await _supabase
          .from('brand_custom_fields')
          .update(updates)
          .eq('id', fieldId);
      return true;
    } catch (e) {
      print('Error updating brand custom field: $e');
      return false;
    }
  }

  // Admin: Delete custom field
  Future<bool> deleteBrandCustomField(String fieldId) async {
    try {
      await _supabase.from('brand_custom_fields').delete().eq('id', fieldId);
      return true;
    } catch (e) {
      print('Error deleting brand custom field: $e');
      return false;
    }
  }

  Future<String?> uploadProductImage(File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'products/$fileName';

      await _supabase.storage
          .from('virtual_wardrobe')
          .upload(filePath, imageFile);

      final imageUrl = _supabase.storage
          .from('virtual_wardrobe')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      print('Error uploading product image: $e');
      return null;
    }
  }

  // Upload brand images (hero or logo)
  Future<String?> uploadBrandImage(File imageFile, String type) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'brands/$fileName';

      await _supabase.storage
          .from('virtual_wardrobe')
          .upload(filePath, imageFile);

      final imageUrl = _supabase.storage
          .from('virtual_wardrobe')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      print('Error uploading brand image: $e');
      return null;
    }
  }
}