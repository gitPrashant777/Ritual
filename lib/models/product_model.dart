// lib/models/product_model.dart

import 'dart:convert';

class ProductModel {
  final String? productId;
  final String title;
  final String? brandName;
  final String description;
  final String category;
  final double price;
  final double? priceAfetDiscount;
  final int? dicountpercent;
  final int stockQuantity;
  final int maxOrderQuantity; // ✅ Field definition
  final bool isOutOfStock;
  final String image;
  final List<String> images;

  // New product flags
  final bool? isOnSale;
  final bool? isPopular;
  final bool? isBestSeller;
  final bool? isFlashSale;
  final DateTime? flashSaleEnd;

  static const String _placeholderImage = 'https://placehold.co/300x300/png?text=No+Image';

  ProductModel({
    this.productId,
    required this.title,
    this.brandName,
    required this.description,
    required this.category,
    required this.price,
    this.priceAfetDiscount,
    this.dicountpercent,
    required this.stockQuantity,
    required this.maxOrderQuantity, // ✅ Required in constructor
    required this.isOutOfStock,
    required this.image,
    required this.images,
    this.isOnSale,
    this.isPopular,
    this.isBestSeller,
    this.isFlashSale,
    this.flashSaleEnd,
  });

  // // Helper to safely extract images from any format (String, Map, etc.)
  // static List<String> _parseImages(dynamic imagesData) {
  //   List<String> parsed = [];
  //   if (imagesData != null && imagesData is List) {
  //     for (var item in imagesData) {
  //       if (item is String && item.isNotEmpty) {
  //         parsed.add(item);
  //       } else if (item is Map) {
  //         // Check typical keys for image URL
  //         final url = item['url'] ?? item['secure_url'] ?? item['link'] ?? item['src'];
  //         if (url != null && url.toString().isNotEmpty) {
  //           parsed.add(url.toString());
  //         }
  //       }
  //     }
  //   }
  //   // Ensure at least one image exists
  //   if (parsed.isEmpty) {
  //     parsed.add(_placeholderImage);
  //   }
  //   return parsed;
  // }

  // Create from API response (backend data)
  factory ProductModel.fromApi(Map<String, dynamic> json) {
    final imagesList = _parseImages(json['images']);

    return ProductModel(
      productId: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['name'] ?? json['title'] ?? 'Unknown Product',
      brandName: json['brand'] ?? json['brandName'] ?? 'BAETOWN',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      price: ((double.tryParse(json['price']?.toString() ?? '0') ?? 0.0) ),
      priceAfetDiscount: json['salePrice'] != null
          ? (double.tryParse(json['salePrice'].toString()) ?? 0.0)
          : (double.tryParse(json['discountPrice']?.toString() ?? '0') ?? 0.0) ,


      // Handle stock mapping (backend often uses 'stock')
      stockQuantity: int.tryParse(json['stock']?.toString() ?? '') ?? int.tryParse(json['stockQuantity']?.toString() ?? '0') ?? 0,

      // ✅ FIX: Safely parse Max Order Quantity from API (default 5)
      maxOrderQuantity: int.tryParse(json['maxOrderQuantity']?.toString() ?? '5') ?? 5,

      isOutOfStock: json['isOutOfStock'] ?? false,

      image: imagesList.first,
      images: imagesList,

      isOnSale: json['isOnSale'] ?? false,
      isPopular: json['isPopular'] ?? false,
      isBestSeller: json['isBestSeller'] ?? false,
      isFlashSale: json['isFlashSale'] ?? false,
      flashSaleEnd: json['flashSaleEnd'] != null
          ? DateTime.tryParse(json['flashSaleEnd'].toString())
          : null,
    );
  }

  // Convert to API JSON for sending (Create/Update)
  Map<String, dynamic> toApiJson() {
    return {
      'name': title,
      'description': description,
      'category': category,
      'price': price,
      'stock': stockQuantity,

      // ✅ FIX: Ensure Max Order Quantity is sent to backend
      'maxOrderQuantity': maxOrderQuantity,

      'isOutOfStock': isOutOfStock,
      'images': images,
      'isOnSale': isOnSale,
      'isPopular': isPopular,
      'isBestSeller': isBestSeller,
      'isFlashSale': isFlashSale,
      if (flashSaleEnd != null) 'flashSaleEnd': flashSaleEnd!.toIso8601String(),
    };
  }

  // Convert to JSON for local storage & Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': productId, // ✅ Includes ID for Kit Saving
      'title': title,
      'brandName': brandName,
      'description': description,
      'category': category,
      'price': price,
      'priceAfetDiscount': priceAfetDiscount,
      'dicountpercent': dicountpercent,
      'stockQuantity': stockQuantity,
      'maxOrderQuantity': maxOrderQuantity, // ✅ Included in local storage
      'isOutOfStock': isOutOfStock,
      'image': image,
      'images': images,
      'isOnSale': isOnSale,
      'isPopular': isPopular,
      'isBestSeller': isBestSeller,
      'isFlashSale': isFlashSale,
      'flashSaleEnd': flashSaleEnd?.toIso8601String(),
    };
  }
// Location: lib/models/product_model.dart (or wherever ProductModel is defined)

  static List<String> _parseImages(dynamic input) {
    List<String> result = [];

    if (input == null) return [];

    if (input is List) {
      for (var item in input) {
        // Case A: Simple String (Old Data)
        if (item is String && item.isNotEmpty) {
          result.add(item);
        }
        // Case B: Map/Object (New Cloudinary Data)
        else if (item is Map) {
          // --- ADDED FIX: Check common MERN keys 'image' and 'imageUrl' ---
          var url = item['url'] ?? item['secure_url'] ?? item['downloadUrl'] ?? item['image'] ?? item['imageUrl'];
          // --- END OF ADDED FIX ---

          if (url != null) {
            result.add(url.toString());
          }
        }
      }
    }

    if (result.isNotEmpty) {
      return result;
    }

    // FALLBACK:
    return ['https://placehold.co/600x400/F5F5F5/CCC?text=No+Image'];
  }
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // This now handles both Strings and Objects correctly
    final imagesList = _parseImages(json['images']);

    return ProductModel(
      productId: json['productId']?.toString() ?? json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? '', // Backend usually sends 'name'
      brandName: json['brandName'] ?? json['brand'] ?? 'BAETOWN', // Check for 'brand' too
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      stockQuantity: int.tryParse(json['stock']?.toString() ?? json['stockQuantity']?.toString() ?? '0') ?? 0, // Check for 'stock'

      maxOrderQuantity: int.tryParse(json['maxOrderQuantity']?.toString() ?? '5') ?? 5,

      isOutOfStock: json['isOutOfStock'] ?? false,

      // Safely handle the first image
      image: imagesList.isNotEmpty ? imagesList.first : '',
      images: imagesList,

      // Handle sale price logic if backend sends 'salePrice'
      priceAfetDiscount: json['salePrice'] != null
          ? double.tryParse(json['salePrice'].toString())
          : double.tryParse(json['priceAfetDiscount']?.toString() ?? ''),

      dicountpercent: int.tryParse(json['dicountpercent']?.toString() ?? json['discount']?.toString() ?? '0'), // Check for 'discount'

      isOnSale: json['isOnSale'] ?? false,
      isPopular: json['isPopular'] ?? false,
      isBestSeller: json['isBestSeller'] ?? false,
      isFlashSale: json['isFlashSale'] ?? false,

      flashSaleEnd: json['flashSaleEnd'] != null
          ? DateTime.tryParse(json['flashSaleEnd'].toString())
          : null,
    );
  }

  int getMaxAllowedQuantity() {
    return maxOrderQuantity;
  }

  ProductModel copyWith({
    String? productId,
    String? title,
    String? brandName,
    String? description,
    String? category,
    double? price,
    double? priceAfetDiscount,
    int? dicountpercent,
    int? stockQuantity,
    int? maxOrderQuantity,
    bool? isOutOfStock,
    String? image,
    List<String>? images,
    bool? isOnSale,
    bool? isPopular,
    bool? isBestSeller,
    bool? isFlashSale,
    DateTime? flashSaleEnd,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      title: title ?? this.title,
      brandName: brandName ?? this.brandName,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      priceAfetDiscount: priceAfetDiscount ?? this.priceAfetDiscount,
      dicountpercent: dicountpercent ?? this.dicountpercent,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      maxOrderQuantity: maxOrderQuantity ?? this.maxOrderQuantity, // ✅ Updated via copyWith
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
      image: image ?? this.image,
      images: images ?? this.images,
      isOnSale: isOnSale ?? this.isOnSale,
      isPopular: isPopular ?? this.isPopular,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      isFlashSale: isFlashSale ?? this.isFlashSale,
      flashSaleEnd: flashSaleEnd ?? this.flashSaleEnd,
    );
  }
}