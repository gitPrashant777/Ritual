// lib/services/cart_wishlist_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/services/api_config.dart';
import 'package:shop/services/api_service.dart';

class CartApiService {
  final ApiService _apiService;
  CartApiService(this._apiService);

  // ... (getCart and addToCart are fine) ...
  Future<Map<String, dynamic>?> getCart() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConfig.cartEndpoint,
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        return response.data!;
      }
      print('Failed to get cart: ${response.error}');
      return null;
    } catch (e) {
      print('Error getting cart: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> addToCart({
    required String productId,
    required int quantity,
    String? size,
    String? color,
  }) async {
    try {
      final cartData = {
        'productId': productId,
        'quantity': quantity,
        if (size != null) 'size': size,
        if (color != null) 'color': color,
      };

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.addProductToCartEndpoint,
        body: cartData,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return response.data!;
      }
      print('Failed to add to cart: ${response.error}');
      return null;
    } catch (e) {
      print('Error adding to cart: $e');
      return null;
    }
  }


  // Update cart item quantity
  // --- FIX: Changed from itemId to productId ---
  Future<bool> updateCartItem({
    required String productId,
    required int quantity,
  }) async {
    try {
      final updateData = {'quantity': quantity};
      // --- FIX: Replace {productId} in the endpoint string ---
      final endpoint = ApiConfig.updateCartItemQuantityEndpoint.replaceFirst('{productId}', productId);

      final response = await _apiService.put<Map<String, dynamic>>(
        endpoint,
        body: updateData,
        requiresAuth: true,
      );

      return response.success;
    } catch (e) {
      print('Error updating cart item: $e');
      return false;
    }
  }

  // Remove item from cart
  // --- FIX: Changed from cartItemId to productId ---
  Future<bool> removeFromCart(String productId) async {
    try {
      // --- FIX: Replace {productId} in the endpoint string ---
      final endpoint = ApiConfig.deleteCartItemEndpoint.replaceFirst('{productId}', productId);

      final response = await _apiService.delete<Map<String, dynamic>>(
        endpoint,
        requiresAuth: true,
      );

      return response.success;
    } catch (e) {
      print('Error removing from cart: $e');
      return false;
    }
  }

  // Clear entire cart
  Future<bool> clearCart() async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiConfig.cartEndpoint, // This endpoint is correct for "clear all"
        requiresAuth: true,
      );

      return response.success;
    } catch (e) {
      print('Error clearing cart: $e');
      return false;
    }
  }

// ... (Rest of CartApiService and WishlistApiService are fine) ...
}

class WishlistApiService {
  final ApiService _apiService;
  WishlistApiService(this._apiService);
// --- FIX START: Robust Get Wishlist (Added 'bookmarks' check) ---
  Future<List<Map<String, dynamic>>> getWishlist() async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiConfig.wishlistEndpoint,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final data = response.data;
        print("📦 Wishlist API Data: $data");

        // Case A: The response IS the list
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }

        // Case B: The response is a Map
        if (data is Map<String, dynamic>) {
          // --- THIS WAS MISSING ---
          if (data['bookmarks'] is List) {
            return List<Map<String, dynamic>>.from(data['bookmarks']);
          }
          // ------------------------

          if (data['wishlist'] is List) {
            return List<Map<String, dynamic>>.from(data['wishlist']);
          }
          if (data['items'] is List) {
            return List<Map<String, dynamic>>.from(data['items']);
          }
          if (data['products'] is List) {
            return List<Map<String, dynamic>>.from(data['products']);
          }
        }

        return [];
      }
      return [];
    } catch (e) {
      print('Error getting wishlist: $e');
      return [];
    }
  }
  // Add item to wishlist
  Future<Map<String, dynamic>?> addToWishlist(String productId) async {
    try {
      final wishlistData = {'productId': productId};
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.addProductToWishlistEndpoint,
        body: wishlistData,
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        return response.data!;
      }
      return null;
    } catch (e) {
      print('Error adding to wishlist: $e');
      return null;
    }
  }

  // Remove item from wishlist
  Future<bool> removeFromWishlist(String productId) async {
    try {
      final endpoint = ApiConfig.deleteWishlistProductEndpoint.replaceFirst('{productId}', productId);
      final response = await _apiService.delete<Map<String, dynamic>>(
        endpoint,
        requiresAuth: true,
      );
      return response.success;
    } catch (e) {
      print('Error removing from wishlist: $e');
      return false;
    }
  }

  // --- FIX START: Update isInWishlist to match robustness ---
  Future<bool> isInWishlist(String productId) async {
    try {
      final items = await getWishlist(); // Reuse the robust logic above

      return items.any((item) {
        // Check standard ID locations
        final String? id = item['productId'] ?? item['_id'];

        // Check nested product object
        final String? nestedId = (item['product'] is Map) ? item['product']['_id'] : null;

        return id == productId || nestedId == productId;
      });
    } catch (e) {
      print('Error checking wishlist: $e');
      return false;
    }
  }
  // --- FIX END ---

  // Move item from wishlist to cart
  Future<Map<String, dynamic>?> moveToCart({
    required String productId,
    int quantity = 1,
  }) async {
    try {
      final moveData = {
        'productId': productId,
        'quantity': quantity,
      };

      final response = await _apiService.post<Map<String, dynamic>>(
        '${ApiConfig.wishlistEndpoint}/move-to-cart',
        body: moveData,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return response.data!;
      }
      return null;
    } catch (e) {
      print('Error moving to cart: $e');
      return null;
    }
  }
}