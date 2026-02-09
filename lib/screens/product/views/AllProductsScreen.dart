// lib/screens/products/all_products_screen.dart

import 'package:flutter/material.dart';
import '../../../components/product/product_card.dart' show ProductCard;
import '../../../constants.dart';
import '../../../models/product_model.dart';
import '../../../route/route_constants.dart';
import '../../../services/products_api_service.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  final ProductsApiService _apiService = ProductsApiService();
  final ScrollController _scrollController = ScrollController();

  final List<ProductModel> _products = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isInitialLoad = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProducts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      if (_isInitialLoad) {
        _error = null;
      }
    });

    try {
      final newProducts = await _apiService.getAllProducts(page: _currentPage);

      setState(() {
        if (newProducts.isEmpty) {
          _hasMore = false;
        } else {
          _products.addAll(newProducts);
          _currentPage++;
        }
        _isLoading = false;
        _isInitialLoad = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Failed to load products. Please try again.";
        _isInitialLoad = false;
      });
      print("Error fetching products: $e");
    }
  }

  // 1. --- CREATED HELPER FUNCTION ---
  // This function navigates back to the EntryPoint and clears all other routes.
  void _navigateToEntryPoint() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      entryPointScreenRoute, // Your dashboard route
          (route) => false, // Remove all previous routes
    );
  }
  // --- END OF CHANGE ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 2. --- WRAPPED SCAFFOLD IN POPSCOPE ---
    // This intercepts the system back button.
    return PopScope(
      canPop: false, // Prevents default back navigation
      onPopInvoked: (didPop) {
        // This is called when the system back button is pressed
        if (didPop) return; // If it already popped, do nothing
        _navigateToEntryPoint(); // Call our custom navigation function
      },
      child: Scaffold(
        backgroundColor:
        isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAF9F6),
        appBar: AppBar(
          backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAF9F6),
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDark ? Colors.white : Colors.black87,
              size: 20,
            ),
            // 3. --- UPDATED ONPRESSED ---
            // Now the app bar button and system button do the same thing.
            onPressed: _navigateToEntryPoint,
          ),
          title: Text(
            "All Products",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              fontFamily: 'Serif',
            ),
          ),
          centerTitle: false,
          actions: [
            // Optional: Add filter/sort icon
            IconButton(
              icon: Icon(
                Icons.tune_outlined,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onPressed: () {
                // TODO: Add filter/sort functionality
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _buildProductGrid(isDark),
      ),
    );
    // --- END OF CHANGE ---
  }

  Widget _buildProductGrid(bool isDark) {
    if (_isInitialLoad && _isLoading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
      );
    }

    if (_error != null && _products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDark ? Colors.white24 : Colors.black12,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    isDark ? Colors.white : const Color(0xFF1A1A2E),
                    foregroundColor:
                    isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                  ),
                  onPressed: () {
                    setState(() {
                      _isInitialLoad = true;
                      _products.clear();
                      _currentPage = 1;
                      _hasMore = true;
                      _error = null;
                    });
                    _fetchProducts();
                  },
                  child: const Text(
                    "RETRY",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              "No Products Found",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: isDark ? Colors.white : Colors.black87,
                fontFamily: 'Serif',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Check back later for new arrivals",
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product count header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Text(
            '${_products.length} ${_products.length == 1 ? 'Product' : 'Products'}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),

        // Product Grid
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 16,
              mainAxisSpacing: 24,
            ),
            itemCount: _products.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _products.length) {
                return _isLoading
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                      isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                )
                    : const SizedBox.shrink();
              }

              final product = _products[index];
              return _buildEnhancedProductCard(product, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedProductCard(ProductModel product, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          productDetailsScreenRoute,
          arguments: product,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F0F0F)
                        : const Color(0xFFE8E6E3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    child: Image.network(
                      product.image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDark
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFFE8E6E3),
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Discount badge
                if (product.priceAfetDiscount != null &&
                    product.dicountpercent != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${product.dicountpercent}% OFF',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                // Out of stock overlay
                if (product.isOutOfStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'OUT OF STOCK',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand name
                    Text(
                      (product.brandName ?? "Rituals").toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Product title
                    Expanded(
                      child: Text(
                        product.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Price
                    Row(
                      children: [
                        Text(
                          '₹${product.priceAfetDiscount ?? product.price}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                          ),
                        ),
                        if (product.priceAfetDiscount != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '₹${product.price}',
                              style: TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color:
                                isDark ? Colors.white38 : Colors.black38,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Rating or Stock indicator
                    if (!product.isOutOfStock)
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: isDark
                                ? Colors.amber
                                : const Color(0xFF1A1A2E),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.5',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color:
                              isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          if (product.stockQuantity < 10 &&
                              product.stockQuantity > 0)
                            Text(
                              'Only ${product.stockQuantity} left',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}