import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shop/models/product_model.dart';
import 'package:shop/models/user_session.dart';
import 'package:shop/services/auth_api_service.dart';
import 'package:shop/services/api_config.dart';

class ProductsApiService {
  final AuthApiService _authService = AuthApiService();

  // Helper to get the auth token
  Future<String?> _getValidToken() async {
    // Get token from UserSession first
    final userSession = await UserSession.getUserSession();
    String? token = userSession?['token'] ?? UserSession.authToken;

    if (token == null || token.isEmpty) {
      log('❌ No token available for authentication');
      return null;
    }

    log('✅ Using existing session token');
    return token;
  }

  // Helper to get standard auth headers
  // lib/services/products_api_service.dart

  Map<String, String> _getAuthHeaders(String token) {
    final cleanToken = token.replaceFirst('Bearer ', '').trim();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $cleanToken',
    };
  }

  // Helper to get standard non-auth headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  // === Review Endpoints ===

  // Delete a review
  Future<Map<String, dynamic>> deleteReview(String productId,
      String reviewId) async {
    final String? token = await _getValidToken();
    if (token == null) {
      return {'success': false, 'message': 'No authentication token available'};
    }

    final url = Uri.parse(
        '${ApiConfig.currentBaseUrl}${ApiConfig.deleteReview
            .replaceAll('{productId}', productId)
            .replaceAll('{reviewId}', reviewId)}');

    log('🌐 DELETE $url');

    final response = await http.delete(
      url,
      headers: _getAuthHeaders(token),
    );

    if (response.statusCode == 200) {
      return {'success': true, ...jsonDecode(response.body)};
    } else {
      log('❌ Error deleting review: ${response.statusCode} ${response.body}');
      return {'success': false, 'message': response.body};
    }
  }

  // Submit a review
  Future<Map<String, dynamic>> submitReview(String productId, double rating,
      String comment) async {
    final String? token = await _getValidToken();
    if (token == null) {
      return {'success': false, 'message': 'No authentication token available'};
    }

    final url = Uri.parse('${ApiConfig.currentBaseUrl}${ApiConfig.reviewsEndpoint}');
    log('🌐 PUT $url');

    final response = await http.put(
      url,
      headers: _getAuthHeaders(token),
      body: jsonEncode({
        'productId': productId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, ...jsonDecode(response.body)};
    } else {
      log('❌ Error submitting review: ${response.statusCode} ${response.body}');
      return {'success': false, 'message': response.body};
    }
  }

  // Fetch reviews for a product
  Future<List<Map<String, dynamic>>> fetchReviews(String productId) async {
    final url = Uri.parse(
        '${ApiConfig.currentBaseUrl}${ApiConfig.allReviewEndpoint.replaceAll(
            '{id}', productId)}');
    log('🌐 GET $url');

    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['reviews'] is List) {
        return List<Map<String, dynamic>>.from(data['reviews']);
      }
    }
    log('❌ Error fetching reviews: ${response.statusCode} ${response.body}');
    return [];
  }

  // === Product Endpoints ===

  // Get all products (with pagination for "See All" screen)
  Future<List<ProductModel>> getAllProducts({
    int page = 1,
    String keyword = '',
    String category = '',
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        if (keyword.isNotEmpty) 'keyword': keyword,
        if (category.isNotEmpty) 'category': category,
      };

      final url = Uri.parse('${ApiConfig.currentBaseUrl}${ApiConfig.productsEndpoint}')
          .replace(queryParameters: queryParams);

      log('🌐 GET $url');
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // The API returns { success: true, products: [...] }
        final productsData = data['products'] ?? data;

        if (productsData is List) {
          log('✅ Loaded ${productsData.length} products for page $page');
          return productsData.map((item) => ProductModel.fromApi(item)).toList();
        } else {
          log('❌ Products data is not a list: $productsData');
          return [];
        }
      } else {
        log('❌ API Error in getAllProducts: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      log('❌ Exception in getAllProducts: $e');
      return [];
    }
  }
  Future<List<ProductModel>> getAllProductsForAdmin() async {
    List<ProductModel> allProducts = [];
    int currentPage = 1;
    bool hasMorePages = true;
    log('🔄 [Admin] Starting full product load...');

    while (hasMorePages) {
      try {
        final queryParams = {'page': currentPage.toString()};
        final url =
        Uri.parse('${ApiConfig.currentBaseUrl}${ApiConfig.productsEndpoint}')
            .replace(queryParameters: queryParams);

        log('🌐 [Admin] GET $url (Page $currentPage)');
        final response = await http.get(url, headers: _headers);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Check for 'products' key, fall back to data itself
          final productsData = data['products'] ?? data;

          if (productsData is List && productsData.isNotEmpty) {
            // Convert list items to ProductModel
            final pageProducts =
            productsData.map((item) => ProductModel.fromApi(item)).toList();

            allProducts.addAll(pageProducts);
            log('✅ [Admin] Loaded ${pageProducts.length} products from page $currentPage. Total: ${allProducts.length}');

            // Increment page for next loop
            currentPage++;
          } else {
            // If list is empty, we've reached the end
            log('🏁 [Admin] No more products found on page $currentPage. Stopping loop.');
            hasMorePages = false;
          }
        } else {
          // If API fails on a page, stop and return what we have
          log('❌ [Admin] API Error on page $currentPage: ${response.statusCode} - ${response.body}');
          hasMorePages = false;
        }
      } catch (e) {
        log('❌ [Admin] Exception during pagination: $e');
        hasMorePages = false; // Stop loop on error
      }
    }

    log('✅ [Admin] Total products loaded: ${allProducts.length}');
    return allProducts;
  }
  // Get popular products (for "PopularProducts" widget)
  Future<List<ProductModel>> getPopularProducts() async {
    try {
      final url = Uri.parse('${ApiConfig.currentBaseUrl}${ApiConfig.popularProductsEndpoint}');
      log('🌐 GET $url');

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final productsData = data['products'] ?? data;

        if (productsData is List) {
          log('✅ Loaded ${productsData.length} popular products');
          return productsData.map((item) => ProductModel.fromApi(item)).toList();
        } else {
          log('❌ Popular products data is not a list: $productsData');
          return [];
        }
      } else {
        log('❌ API Error in getPopularProducts: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      log('❌ Exception in getPopularProducts: $e');
      return [];
    }
  }

  // Get single product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final url = Uri.parse(
          '${ApiConfig.currentBaseUrl}${ApiConfig.productId.replaceAll(
              '{id}', productId)}');
      log('🌐 GET $url');

      final response = await http.get(url, headers: _headers);

      log('🔍 Product details response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Handle different response structures
        if (jsonData['success'] == true && jsonData['product'] != null) {
          // Response format: { success: true, product: {...} }
          return ProductModel.fromApi(jsonData['product']);
        } else if (jsonData is Map<String, dynamic> && jsonData.containsKey('_id')) {
          // Direct product object
          return ProductModel.fromApi(jsonData);
        } else {
          log('❌ Unexpected response format for product details');
          return null;
        }
      } else {
        log('❌ Failed to fetch product details: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      log('❌ Error fetching product details: $e');
      return null;
    }
  }

  // Get products by category
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final url = Uri.parse(
          '${ApiConfig.currentBaseUrl}${ApiConfig.productCategoriesEndpoint
              .replaceAll('{category}', category)}');
      log('🌐 GET $url');

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Assuming format { success: true, products: [...] }
        final productsData = data['products'] ?? [];

        if (productsData is List) {
          log('✅ Found ${productsData.length} products for category: $category');
          return productsData.map((item) => ProductModel.fromApi(item)).toList();
        }
      }
      log('❌ Failed to fetch products by category: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      log('❌ Error fetching products by category: $e');
      return [];
    }
  }

  // === Admin Endpoints ===

  // Create a new product
  Future<Map<String, dynamic>> createProduct(ProductModel product) async {
    log('🚀 Starting product creation...');

    final String? token = await _getValidToken();
    if (token == null) {
      return {'success': false, 'message': 'No valid authentication token available'};
    }

    final url = Uri.parse('${ApiConfig.currentBaseUrl}${ApiConfig.createNewProduct}');
    final productData = product.toApiJson();
    final bodyString = jsonEncode(productData);

    log('🌐 POST $url');
    log('📦 Creating product with data: $bodyString');

    try {
      final response = await http.post(
        url,
        headers: _getAuthHeaders(token),
        body: bodyString,
      );

      log('📡 API Response Status: ${response.statusCode}');
      log('📡 API Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Product created successfully',
          'data': responseData
        };
      } else {
        log('❌ Error creating product: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to create product: ${response.statusCode} - ${response.body}'
        };
      }
    } catch (e) {
      log('❌ Exception creating product: $e');
      return {'success': false, 'message': 'Error creating product: $e'};
    }
  }

  // Delete product
  Future<Map<String, dynamic>> deleteProduct(String productId) async {
    final String? token = await _getValidToken();
    if (token == null) {
      return {'success': false, 'message': 'No authentication token available'};
    }

    try {
      final url = Uri.parse(
          '${ApiConfig.currentBaseUrl}${ApiConfig.deleteProduct.replaceAll(
              '{id}', productId)}');
      log('🌐 DELETE $url');

      final response = await http.delete(
        url,
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Product deleted successfully',
          ...jsonDecode(response.body)
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to delete product: ${response.statusCode} - ${response.body}'
        };
      }
    } catch (e) {
      log('❌ Error deleting product: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
// lib/services/products_api_service.dart
// ... (inside the ProductsApiService class)

  // ... (after getPopularProducts)

  // Get best-seller products
  Future<List<ProductModel>> getBestSellers() async {
    try {
      final url = Uri.parse('${ApiConfig.currentBaseUrl}${ApiConfig.bestSellersProductsEndpoint}');
      log('🌐 GET $url');

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final productsData = data['products'] ?? data;

        if (productsData is List) {
          log('✅ Loaded ${productsData.length} best-seller products');
          return productsData.map((item) => ProductModel.fromApi(item)).toList();
        } else {
          log('❌ Best-seller products data is not a list: $productsData');
          return [];
        }
      } else {
        log('❌ API Error in getBestSellers: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      log('❌ Exception in getBestSellers: $e');
      return [];
    }
  }

  // Get flash-sale products
  Future<List<ProductModel>> getFlashSaleProducts() async {
    try {
      final url = Uri.parse('${ApiConfig.currentBaseUrl}${ApiConfig.flashSale}');
      log('🌐 GET $url');

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final productsData = data['products'] ?? data;

        if (productsData is List) {
          log('✅ Loaded ${productsData.length} flash-sale products');
          return productsData.map((item) => ProductModel.fromApi(item)).toList();
        } else {
          log('❌ Flash-sale products data is not a list: $productsData');
          return [];
        }
      } else {
        log('❌ API Error in getFlashSaleProducts: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      log('❌ Exception in getFlashSaleProducts: $e');
      return [];
    }
  }

  // ... (rest of the class)
  // Update product
  Future<Map<String, dynamic>> updateProduct(String productId,
      ProductModel product) async {
    final String? token = await _getValidToken();
    if (token == null) {
      return {'success': false, 'message': 'No authentication token available'};
    }

    try {
      final url = Uri.parse(
          '${ApiConfig.currentBaseUrl}${ApiConfig.updateProduct.replaceAll(
              '{id}', productId)}');
      log('🌐 PUT $url');

      final response = await http.put(
        url,
        headers: _getAuthHeaders(token),
        body: jsonEncode(product.toApiJson()),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Product updated successfully',
          'data': jsonDecode(response.body)
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update product: ${response.statusCode} - ${response.body}'
        };
      }
    } catch (e) {
      log('❌ Error updating product: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}