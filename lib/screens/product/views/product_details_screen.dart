import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_svg/svg.dart'; // Unused
import 'package:provider/provider.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/components/custom_modal_bottom_sheet.dart';
// import 'package:shop/components/free_delivery_banner.dart'; // Unused
// import 'package:shop/components/product/product_card.dart'; // Unused
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/cart_service.dart';
import 'package:shop/services/products_api_service.dart';
import 'package:shop/services/cart_wishlist_api_service.dart';
import 'package:shop/models/product_model.dart';

// import 'components/notify_me_card.dart'; // Unused
import 'components/product_images.dart';
import 'product_buy_now_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final ProductModel product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late CartApiService _cartApi;
  late WishlistApiService _wishlistApi;
  late CartService _cartService;
  final ProductsApiService _productsApi = ProductsApiService();
  Future<List<Map<String, dynamic>>>? _reviewsFuture;
  bool _isInWishlist = false;
  double _reviewRating = 5.0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmittingReview = false;

  final String currentUserId = "CURRENT_USER_ID";

  @override
  void initState() {
    super.initState();
    _cartApi = Provider.of<CartApiService>(context, listen: false);
    _wishlistApi = Provider.of<WishlistApiService>(context, listen: false);
    _cartService = Provider.of<CartService>(context, listen: false);
    _checkWishlist();
    _reviewsFuture = fetchReviews();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> deleteReview(String reviewId) async {
    final productId = widget.product.productId ?? '';
    final result = await _productsApi.deleteReview(productId, reviewId);
    if (result['success'] == true) {
      setState(() {
        _reviewsFuture = fetchReviews();
      });
      _showSnackBar('Review deleted successfully', isError: false);
    } else {
      _showSnackBar('Failed to delete review', isError: true);
    }
  }

  Future<void> submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      _showSnackBar('Please write a review', isError: true);
      return;
    }

    setState(() => _isSubmittingReview = true);
    final productId = widget.product.productId ?? '';
    final result = await _productsApi.submitReview(
      productId,
      _reviewRating,
      _reviewController.text.trim(),
    );
    setState(() => _isSubmittingReview = false);

    if (result['success'] == true) {
      _reviewController.clear();
      setState(() => _reviewRating = 5.0);
      _reviewsFuture = fetchReviews();
      _showSnackBar('Review submitted!', isError: false);
    } else {
      _showSnackBar('Failed to submit review', isError: true);
    }
  }

  Future<List<Map<String, dynamic>>> fetchReviews() async {
    final productId = widget.product.productId ?? '';
    return await _productsApi.fetchReviews(productId);
  }

  Future<void> _checkWishlist() async {
    final productId = widget.product.productId ?? '';
    final isWish = await _wishlistApi.isInWishlist(productId);
    setState(() => _isInWishlist = isWish);
  }

  Future<void> _toggleWishlist() async {
    HapticFeedback.lightImpact();
    final productId = widget.product.productId ?? '';
    if (_isInWishlist) {
      await _wishlistApi.removeFromWishlist(productId);
      _showSnackBar('Removed from wishlist', isError: true);
    } else {
      await _wishlistApi.addToWishlist(productId);
      _showSnackBar('Added to wishlist', isError: false);
    }
    _checkWishlist();
  }

  Future<void> _addToCart() async {
    HapticFeedback.mediumImpact();
    await _cartService.addToCart(widget.product, quantity: 1);
    _showSnackBar('Added to cart!', isError: false);
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : const Color(0xFF020953),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool get isProductAvailable =>
      !widget.product.isOutOfStock && widget.product.stockQuantity > 0;

  @override
  Widget build(BuildContext context) {
    final bool isCartLoading = context.watch<CartService>().isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FB),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: isTablet ? 60 : 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF020953),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: isCartLoading ? null : _addToCart,
                    child: isCartLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      'ADD TO CART',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: SizedBox(
                  height: isTablet ? 60 : 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF020953),
                      side: const BorderSide(
                        color: Color(0xFF020953),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      customModalBottomSheet(
                        context,
                        height: MediaQuery.of(context).size.height * 0.92,
                        child: ProductBuyNowScreen(product: widget.product),
                      );
                    },
                    child: Text(
                      'BUY NOW',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor:
              isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FB),
              elevation: 0,
              floating: true,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : const Color(0xFF020953),
                    size: isTablet ? 24 : 22,
                  ),
                  // ✅ FIX 2: Use pop() to return to the list instead of reloading Home
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _toggleWishlist,
                    icon: Icon(
                      _isInWishlist ? Icons.favorite : Icons.favorite_border,
                      color: _isInWishlist
                          ? Colors.red
                          : (isDark ? Colors.white : const Color(0xFF020953)),
                      size: isTablet ? 24 : 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            ProductImages(
              images: widget.product.images.isNotEmpty
                  ? widget.product.images
                  : [productDemoImg1, productDemoImg2, productDemoImg3],
            ),
            SliverPadding(
              padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF020953).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (widget.product.brandName ?? "RITUAL").toUpperCase(),
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: const Color(0xFF020953),
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    Text(
                      widget.product.title ?? "Product Title",
                      style: TextStyle(
                        fontSize: isTablet ? 32 : 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        height: 1.2,
                        color: isDark ? Colors.white : const Color(0xFF020953),
                      ),
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    Row(
                      children: [
                        Text(
                          '₹${widget.product.priceAfetDiscount ?? widget.product.price}',
                          style: TextStyle(
                            fontSize: isTablet ? 28 : 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF020953),
                          ),
                        ),
                        if (widget.product.priceAfetDiscount != null) ...[
                          SizedBox(width: isTablet ? 16 : 12),
                          Text(
                            '₹${widget.product.price}',
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 18,
                              decoration: TextDecoration.lineThrough,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          SizedBox(width: isTablet ? 12 : 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${((1 - (widget.product.priceAfetDiscount! / widget.product.price)) * 100).toInt()}% OFF',
                              style: TextStyle(
                                fontSize: isTablet ? 12 : 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: isTablet ? 24 : 20),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 14 : 12,
                        vertical: isTablet ? 8 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: isProductAvailable
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isProductAvailable ? Colors.green : Colors.red,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isProductAvailable
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined,
                            size: isTablet ? 18 : 16,
                            color: isProductAvailable ? Colors.green : Colors.red,
                          ),
                          SizedBox(width: isTablet ? 8 : 6),
                          Text(
                            isProductAvailable
                                ? 'IN STOCK (${widget.product.stockQuantity})'
                                : 'OUT OF STOCK',
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: isProductAvailable ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isTablet ? 32 : 24),
                    Text(
                      'DESCRIPTION',
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    Text(
                      widget.product.description ?? "No description available",
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 15,
                        height: 1.6,
                        letterSpacing: 0.3,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 20,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Free Delivery',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                'On orders over ₹500',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isProductAvailable) ...[
                      const SizedBox(height: 16),
                      Divider(
                        height: 1,
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 20,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Return Policy',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  '99 days return period',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'YOU MAY ALSO LIKE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: FutureBuilder<List<ProductModel>>(
                future: _productsApi.getAllProducts(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final relatedProducts = snapshot.data!
                        .where((p) => p.productId != widget.product.productId)
                        .take(4)
                        .toList();

                    return SizedBox(
                      height: 300,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: relatedProducts.length,
                        itemBuilder: (context, index) => Container(
                          width: 180,
                          margin: EdgeInsets.only(
                            right: index == relatedProducts.length - 1 ? 0 : 16,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                productDetailsScreenRoute,
                                arguments: relatedProducts[index],
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
                                  Stack(
                                    children: [
                                      Container(
                                        height: 150,
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFE8E6E3),
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
                                            relatedProducts[index].image,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE8E6E3),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.image_outlined,
                                                    size: 38,
                                                    color: isDark ? Colors.white24 : Colors.black12,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      if (relatedProducts[index].priceAfetDiscount != null)
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
                                            child: const Text(
                                              'SALE',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (relatedProducts[index].brandName ?? "Rituals").toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.5,
                                            color: isDark ? Colors.white60 : Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          relatedProducts[index].title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? Colors.white : Colors.black87,
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              '₹${relatedProducts[index].priceAfetDiscount ?? relatedProducts[index].price}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                              ),
                                            ),
                                            if (relatedProducts[index].priceAfetDiscount != null) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                '₹${relatedProducts[index].price}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  decoration: TextDecoration.lineThrough,
                                                  color: isDark ? Colors.white38 : Colors.black38,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            if (!relatedProducts[index].isOutOfStock)
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.star,
                                                    size: 14,
                                                    color: isDark ? Colors.amber : const Color(0xFF1A1A2E),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '4.5',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: isDark ? Colors.white70 : Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            const Spacer(),
                                            if (relatedProducts[index].isOutOfStock)
                                              const Text(
                                                'OUT OF STOCK',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.red,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REVIEWS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _reviewsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final reviews = snapshot.data ?? [];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (reviews.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    "No reviews yet. Be the first to review!",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ...reviews.map((review) {
                              int ratingStars = 5;
                              final ratingRaw = review['rating'];
                              double? ratingValue;
                              if (ratingRaw is num) {
                                ratingValue = ratingRaw.toDouble();
                              } else if (ratingRaw is String) {
                                ratingValue = double.tryParse(ratingRaw);
                              }
                              if (ratingValue != null && ratingValue > 0 && ratingValue.isFinite) {
                                ratingStars = ratingValue.floor();
                              }
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
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
                                    Row(
                                      children: [
                                        Row(
                                          children: List.generate(
                                            ratingStars,
                                                (i) => Icon(
                                              Icons.star,
                                              color: isDark ? Colors.amber : const Color(0xFF1A1A2E),
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          review['createdAt'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.white54 : Colors.black54,
                                          ),
                                        ),
                                        if (review['user'] != null &&
                                            ((review['user'] is Map && review['user']['_id'] == currentUserId) ||
                                                (review['user'] is String && review['user'] == currentUserId)))
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                            onPressed: () async {
                                              await deleteReview(review['_id']);
                                            },
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      review['user'] != null && (review['user'] is Map && review['user']['name'] != null)
                                          ? review['user']['name']
                                          : ((review['user'] != null &&
                                          ((review['user'] is Map && review['user']['_id'] == currentUserId) ||
                                              (review['user'] is String && review['user'] == currentUserId)))
                                          ? "You"
                                          : "Anonymous"),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      review['comment'] ?? "",
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 32),
                            Text(
                              'ADD YOUR REVIEW',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: List.generate(
                                5,
                                    (i) => GestureDetector(
                                  onTap: () => setState(() => _reviewRating = i + 1.0),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Icon(
                                      Icons.star,
                                      color: i < _reviewRating
                                          ? (isDark ? Colors.amber : const Color(0xFF1A1A2E))
                                          : (isDark ? Colors.white24 : Colors.black12),
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _reviewController,
                              maxLines: 4,
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: "Write your review...",
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white30 : Colors.black26,
                                ),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white12 : Colors.black12,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white12 : Colors.black12,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                  foregroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _isSubmittingReview ? null : submitReview,
                                child: _isSubmittingReview
                                    ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                                  ),
                                )
                                    : const Text(
                                  "SUBMIT REVIEW",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }
}