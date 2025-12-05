import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart'; // Ensure this has your defaultPadding
import 'package:shop/models/product_model.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/cart_service.dart';
import 'package:shop/services/cart_wishlist_api_service.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _wishlistItems = [];

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
  }

  Future<void> _fetchWishlist() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<WishlistApiService>(context, listen: false);
      final items = await api.getWishlist();
      if (mounted) {
        setState(() {
          _wishlistItems = items;
        });
      }
    } catch (e) {
      print("Error loading wishlist: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromWishlist(String productId) async {
    final api = Provider.of<WishlistApiService>(context, listen: false);

    // Optimistic update: Remove from UI immediately
    setState(() {
      _wishlistItems.removeWhere((item) {
        final prod = item['product'] ?? item;
        return (prod['_id'] ?? prod['productId']) == productId;
      });
    });

    final success = await api.removeFromWishlist(productId);

    if (!success) {
      // Revert if failed
      await _fetchWishlist();
      if (mounted) _showSnackBar("Failed to remove item", isError: true);
    } else {
      if (mounted) _showSnackBar("Removed from wishlist", isError: false);
    }
  }

  Future<void> _moveToCart(String productId, Map<String, dynamic> productData) async {
    final wishlistApi = Provider.of<WishlistApiService>(context, listen: false);
    final cartService = Provider.of<CartService>(context, listen: false);

    // Show loading indicator logic if needed, or just optimistic UI
    final result = await wishlistApi.moveToCart(productId: productId);

    if (result != null) {
      // 1. Remove from local wishlist UI
      setState(() {
        _wishlistItems.removeWhere((item) {
          final prod = item['product'] ?? item;
          return (prod['_id'] ?? prod['productId']) == productId;
        });
      });

      // 2. Refresh Cart Service (Critical for Badge Update)
      await cartService.fetchCart();

      if (mounted) _showSnackBar("Moved to cart", isError: false);
    } else {
      if (mounted) _showSnackBar("Failed to move to cart", isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : const Color(0xFF020953),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAF9F6),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Wishlist (${_wishlistItems.length})',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            fontFamily: 'Serif',
          ),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: isDark ? Colors.white : const Color(0xFF020953),
        ),
      )
          : _wishlistItems.isEmpty
          ? _buildEmptyState(isDark)
          : RefreshIndicator(
        onRefresh: _fetchWishlist,
        color: const Color(0xFF020953),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _wishlistItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65, // Adjusts height of card
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final item = _wishlistItems[index];
            // Handle nested structure from API (sometimes item is the product, sometimes item['product'])
            final productData = item['product'] is Map ? item['product'] : item;

            return _buildWishlistCard(productData, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            'Your Wishlist is Empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: isDark ? Colors.white : Colors.black87,
              fontFamily: 'Serif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save items you love to view them here',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, entryPointScreenRoute, (route) => false),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF020953),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              "Start Shopping",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
  Widget _buildWishlistCard(Map<String, dynamic> productData, bool isDark) {
    // Parse fields safely
    final String productId = productData['_id'] ?? productData['id'] ?? '';
    final String title = productData['title'] ?? productData['name'] ?? 'Unknown Product';
    final String brand = productData['brandName'] ?? productData['brand'] ?? 'BAETOWN';
    final dynamic priceRaw = productData['price'];
    final dynamic discountPriceRaw = productData['priceAfetDiscount'] ?? productData['salePrice'];

    // Convert to double safely
    final double price = (priceRaw is num) ? priceRaw.toDouble() : 0.0;
    final double? discountPrice = (discountPriceRaw is num) ? discountPriceRaw.toDouble() : null;
    final double finalPrice = (discountPrice != null && discountPrice > 0) ? discountPrice : price;

    // Handle Image (Map or String)
    String imageUrl = "";
    final images = productData['images'];

    if (images != null && images is List && images.isNotEmpty) {
      final firstImage = images[0];
      if (firstImage is String) {
        imageUrl = firstImage;
      } else if (firstImage is Map) {
        imageUrl = firstImage['url'] ?? firstImage['secure_url'] ?? '';
      }
    } else if (productData['image'] != null) {
      if (productData['image'] is String) {
        imageUrl = productData['image'];
      }
    }

    // Fallback image
    if (imageUrl.isEmpty) {
      imageUrl = 'https://placehold.co/300x300/png?text=No+Image';
    }

    // Try to create a ProductModel for navigation
    ProductModel? productModel;
    try {
      final cleanData = Map<String, dynamic>.from(productData);
      if (cleanData['id'] == null) cleanData['id'] = productId;
      productModel = ProductModel.fromJson(cleanData);
    } catch (e) {
      print("Error creating model: $e");
    }

    return GestureDetector(
      onTap: () {
        if (productModel != null) {
          Navigator.pushNamed(
            context,
            productDetailsScreenRoute,
            arguments: productModel,
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: SizedBox(
                      width: double.infinity,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: isDark ? Colors.grey[900] : Colors.grey[200],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                  // Delete Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _removeFromWishlist(productId),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '₹${finalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                      ),
                      if (discountPrice != null && discountPrice > 0 && discountPrice < price) ...[
                        const SizedBox(width: 6),
                        Text(
                          '₹${price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                      ]
                    ],
                  ),
                  // --- "Move to Bag" Button Removed Here ---
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}