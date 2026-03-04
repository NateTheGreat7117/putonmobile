import 'dart:convert';

class ClothingItem {
  final String id;
  final String name;
  final String brand;
  final String color;
  final String size;
  final String category;
  final String imageUrl;
  final double minPrice;
  final double maxPrice;
  final String purchaseUrl;
  final String? notes; // Add notes field

  ClothingItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.color,
    required this.size,
    required this.category,
    required this.imageUrl,
    required this.minPrice,
    required this.maxPrice,
    required this.purchaseUrl,
    this.notes, // Optional notes parameter
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'].toString(),
      name: json['name'],
      brand: json['brand'],
      color: json['color'],
      size: json['size'],
      category: json['category'],
      imageUrl: json['imageUrl'],
      minPrice: (json['minPrice'] as num).toDouble(),
      maxPrice: (json['maxPrice'] as num).toDouble(),
      purchaseUrl: json['purchaseUrl'],
      notes: json['notes'], // Parse notes from JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'color': color,
      'size': size,
      'category': category,
      'imageUrl': imageUrl,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'purchaseUrl': purchaseUrl,
      'notes': notes,
    };
  }

  // Helper method to create a copy with updated fields
  ClothingItem copyWith({
    String? id,
    String? name,
    String? brand,
    String? color,
    String? size,
    String? category,
    String? imageUrl,
    double? minPrice,
    double? maxPrice,
    String? purchaseUrl,
    String? notes,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      color: color ?? this.color,
      size: size ?? this.size,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      purchaseUrl: purchaseUrl ?? this.purchaseUrl,
      notes: notes ?? this.notes,
    );
  }
}

class Outfit {
  final String id;
  final String userId;
  final String userName;
  final String imageUrl;
  final List<ClothingItem> items;
  final int likes;
  final int comments;
  final int shares;
  final List<String>? styles;
  final List<String>? seasons;
  final List<String>? occasions;

  Outfit({
    required this.id,
    required this.userId,
    required this.userName,
    required this.imageUrl,
    required this.items,
    required this.likes,
    required this.comments,
    required this.shares,
    this.styles,
    this.seasons,
    this.occasions,
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    // Helper function to parse array fields that might be stored as JSON strings
    List<String>? parseArrayField(dynamic field) {
      if (field == null) return null;
      if (field is List) {
        return field.map((e) => e.toString()).toList();
      }
      if (field is String) {
        // It's a JSON string, parse it
        try {
          final decoded = jsonDecode(field);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return Outfit(
      id: json['id'].toString(),
      userId: json['user_id'] ?? '',
      userName: json['user_name'],
      imageUrl: json['image_url'],
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ClothingItem.fromJson(item as Map<String, dynamic>))
              .toList() ?? [],
      styles: parseArrayField(json['styles']),
      seasons: parseArrayField(json['seasons']),
      occasions: parseArrayField(json['occasions']),
    );
  }
}

// Brand model
class Brand {
  final String id;
  final String name;
  final String logoUrl;
  final String description;
  final int points;
  final String heroImageUrl;
  final String tagline;
  final String ctaHeading;
  final String ctaDescription;
  final String productsSectionTitle;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String shopUrl;

  Brand({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.description,
    required this.points,
    required this.heroImageUrl,
    required this.tagline,
    required this.ctaHeading,
    required this.ctaDescription,
    required this.productsSectionTitle,
    required this.createdAt,
    required this.updatedAt,
    required this.shopUrl,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      points: json['points'] as int? ?? 0,
      heroImageUrl: json['hero_image_url'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      ctaHeading: json['cta_heading'] as String? ?? 'Explore Our Collection',
      ctaDescription: json['cta_description'] as String? ??
          'Experience innovation and performance with our complete range of products',
      productsSectionTitle: json['products_section_title'] as String? ?? 'Iconic Products',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      shopUrl: json['shop_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
      'description': description,
      'points': points,
      'hero_image_url': heroImageUrl,
      'tagline': tagline,
      'cta_heading': ctaHeading,
      'cta_description': ctaDescription,
      'products_section_title': productsSectionTitle,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'shop_url': shopUrl,
    };
  }
}

// Brand Product model
class BrandProduct {
  final String id;
  final String brandId;
  final String name;
  final String price;
  final String imageUrl;
  final String backgroundColor;
  final String productUrl;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  BrandProduct({
    required this.id,
    required this.brandId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.backgroundColor,
    required this.productUrl,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BrandProduct.fromJson(Map<String, dynamic> json) {
    return BrandProduct(
      id: json['id'] as String,
      brandId: json['brand_id'] as String,
      name: json['name'] as String,
      price: json['price'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      backgroundColor: json['background_color'] as String? ?? '#EEEEEE',
      productUrl: json['product_url'] as String? ?? '',
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand_id': brandId,
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'background_color': backgroundColor,
      'product_url': productUrl,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// Brand Custom Field model
class BrandCustomField {
  final String id;
  final String brandId;
  final String label;
  final String value;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  BrandCustomField({
    required this.id,
    required this.brandId,
    required this.label,
    required this.value,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BrandCustomField.fromJson(Map<String, dynamic> json) {
    return BrandCustomField(
      id: json['id'] as String,
      brandId: json['brand_id'] as String,
      label: json['label'] as String,
      value: json['value'] as String,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand_id': brandId,
      'label': label,
      'value': value,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}