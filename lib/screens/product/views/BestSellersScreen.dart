// lib/screens/products/best_sellers_screen.dart

import 'package:flutter/material.dart';
import '../../../models/product_model.dart';
import '../../../route/route_constants.dart';
import '../../../services/products_api_service.dart';

class BestSellersScreen extends StatefulWidget {
  const BestSellersScreen({super.key});

  @override
  State<BestSellersScreen> createState() => _BestSellersScreenState();
}

class _BestSellersScreenState extends State<BestSellersScreen> {
  final ProductsApiService _apiService = ProductsApiService();
  final ScrollController _scrollController = ScrollController();

  final List<ProductModel> _products = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isInitialLoad = true;
  String? _error;

  // --- Ritual Color Ritual ---
  static const Color brandPrimary = Color(0xFF0B3323); // Deep Green
  static const Color scaffoldBg = Color(0xFFFAF9F6);    // Off-White background

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
      if (_isInitialLoad) _error = null;
    });

    try {
      final newProducts = await _apiService.getBestSellers();
      setState(() {
        if (newProducts.isEmpty) {
          _hasMore = false;
        } else {
          _products.addAll(newProducts);
          _currentPage++;
          _hasMore = false; // Set to true if your API supports pagination here
        }
        _isLoading = false;
        _isInitialLoad = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Failed to load best sellers. Please try again.";
        _isInitialLoad = false;
      });
    }
  }

  // --- FIX: Safe Navigation to prevent crash ---
  void _navigateToEntryPoint() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      entryPointScreenRoute,
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _navigateToEntryPoint();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : scaffoldBg,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0F0F0F) : scaffoldBg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDark ? Colors.white : Colors.black87,
              size: 20,
            ),
            onPressed: _navigateToEntryPoint,
          ),
          title: Text(
            "Best Sellers",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
              color: isDark ? Colors.white : brandPrimary,
              fontFamily: 'Serif',
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: Icon(Icons.tune_outlined, color: isDark ? Colors.white : Colors.black87),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _buildProductGrid(isDark, brandPrimary),
      ),
    );
  }

  Widget _buildProductGrid(bool isDark, Color primary) {
    if (_isInitialLoad && _isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: brandPrimary));
    }

    if (_error != null && _products.isEmpty) {
      return _buildErrorState(isDark, primary);
    }

    if (_products.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 16, 24, 12),
          child: Text(
            '${_products.length} Products',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              // --- FIX: Changed to 0.60 to prevent 3px overflow ---
              childAspectRatio: 0.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: _products.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _products.length) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: brandPrimary));
              }
              return _buildEnhancedProductCard(_products[index], isDark, primary);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedProductCard(ProductModel product, bool isDark, Color primary) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, productDetailsScreenRoute, arguments: product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFEBEBEB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.network(
                        product.image,
                        fit: BoxFit.contain,
                        errorBuilder: (context, e, s) => const Icon(Icons.image_outlined, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                // --- FIX: Removed null% by checking validity ---
                if (product.dicountpercent != null && product.dicountpercent! > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFF5252),
                          borderRadius: BorderRadius.circular(4)
                      ),
                      child: Text(
                        '${product.dicountpercent}% OFF',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (product.brandName ?? "RITUALS").toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: Colors.grey[600]
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      product.title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 8),
                  // --- Price Row with Strikethrough ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                          '₹${product.priceAfetDiscount ?? product.price}',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primary
                          )
                      ),
                      if (product.priceAfetDiscount != null && product.priceAfetDiscount! < product.price) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '₹${product.price}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: brandPrimary),
                      const SizedBox(width: 4),
                      Text(
                          "4.5",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600]
                          )
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("Failed to load products"),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchProducts,
            style: ElevatedButton.styleFrom(backgroundColor: primary),
            child: const Text("RETRY", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return const Center(child: Text("No Best Sellers Found"));
  }
}