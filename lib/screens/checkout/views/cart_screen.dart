// lib/screens/cart/views/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/components/network_image_with_loader.dart';
import 'package:shop/services/cart_service.dart';
import 'package:shop/services/cart_wishlist_api_service.dart';
import 'package:shop/models/cart_item_model.dart';
import 'package:shop/services/payment_service.dart';
import 'package:shop/constants.dart';
import '../../../services/orders_api_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late OrdersApiService _ordersApi;

  @override
  void initState() {
    super.initState();
    _ordersApi = Provider.of<OrdersApiService>(context, listen: false);
    final cartApi = Provider.of<CartApiService>(context, listen: false);

    // PaymentService.initialize(
    //   context: context,
    //   ordersApi: _ordersApi,
    //   cartApi: cartApi,
    // );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartService>(context, listen: false).fetchCart();
    });
  }

  @override
  void dispose() {
    //  PaymentService.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final cartService = Provider.of<CartService>(context, listen: false);
    if (cartService.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Your cart is empty!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final Map<String, dynamic> shippingInfo = {
      "address": "123 Test Street",
      "city": "Test City",
      "state": "Test State",
      "country": "India",
      "pinCode": 110001,
      "phoneNo": 9999999999,
    };

    final totalAmount = cartService.totalPrice;
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              CircularProgressIndicator(
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
              const SizedBox(width: 20),
              Text(
                'Creating your order...',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      final String? razorpayKey = await _ordersApi.getRazorpayKey();
      if (razorpayKey == null) throw Exception('Failed to get Razorpay key.');

      final orderData = await _ordersApi.createRazorpayOrder(totalAmount);
      if (orderData == null || orderData['id'] == null) {
        throw Exception('Failed to create order on backend.');
      }

      final String razorpayOrderId = orderData['id'];
      final double serverAmount = (orderData['amount'] as num).toDouble() /
          100.0;
      Navigator.of(context).pop();

      // PaymentService.startPayment(
      //   key: razorpayKey,
      //   amount: serverAmount,
      //   orderId: razorpayOrderId,
      //   cartItems: cartService.items,
      //   shippingInfo: shippingInfo,
      //   customerName: 'Customer',
      //   customerEmail: 'customer@example.com',
      //   customerContact: '9999999999',

    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showClearCartDialog(BuildContext context, CartService cartService) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 12),
                Text(
                  'Clear Cart',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to remove all items from cart?',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final bool success = await cartService.clearCart();
                  Navigator.pop(dialogContext);

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Cart cleared successfully'),
                        backgroundColor: const Color(0xFF1A1A2E),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  } else if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Failed to clear cart'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    return Consumer<CartService>(
      builder: (context, cartService, child) {
        final allItems = cartService.items;
        final isLoading = cartService.isLoading;

        // --- FIX START: Filter out "Ghost" Items ---
        // We only keep items that have a valid ID and a price/title
        final validCartItems = allItems.where((item) {
          final hasId = item.product.productId != null &&
              item.product.productId!.isNotEmpty;
          // You can also check if title is not the default "Product" if your model defaults to that
          final isNotDefault = item.product.title != 'Product';
          return hasId && isNotDefault;
        }).toList();
        // --- FIX END ---

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(
              0xFFFAF9F6),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(
                0xFFFAF9F6),
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            // Use validCartItems.length instead of cartItems.length
            title: Text(
              'Cart (${validCartItems.length})',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                fontFamily: 'Serif',
              ),
            ),
            actions: [
              if (validCartItems.isNotEmpty)
                IconButton(
                  onPressed: () => _showClearCartDialog(context, cartService),
                  icon: Icon(
                    Icons.delete_outline,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: isLoading && validCartItems.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : validCartItems.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 100,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Cart is Empty',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Serif',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add items to your cart to see them here',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
              : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 24),
                  // Use validCartItems count
                  itemCount: validCartItems.length,
                  itemBuilder: (context, index) {
                    // Get item from valid list
                    final cartItem = validCartItems[index];
                    final String? productId = cartItem.product.productId;

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
                      child: Row(
                        children: [
                          // Product Image
                          if (cartItem.product.images.isNotEmpty &&
                              cartItem.product.images.first.isNotEmpty)
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F0F0F)
                                    : const Color(0xFFE8E6E3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: NetworkImageWithLoader(
                                  cartItem.product.images.first,
                                  radius: 8,
                                ),
                              ),
                            ),
                          const SizedBox(width: 16),

                          // Product Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (cartItem.product.brandName ?? "BAETOWN")
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                    color: isDark ? Colors.white60 : Colors
                                        .black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cartItem.product.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : Colors
                                        .black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cartItem.product.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white54 : Colors
                                        .black54,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Category: ${cartItem.product.category}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white38 : Colors
                                        .black38,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      '₹${cartItem.product.priceAfetDiscount ??
                                          cartItem.product.price}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    const Spacer(),

                                    // Quantity Controls
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white12
                                              : Colors.black12,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: (isLoading ||
                                                cartItem.quantity <= 1)
                                                ? null
                                                : () async {
                                              if (productId != null) {
                                                await cartService
                                                    .updateQuantity(
                                                  productId: productId,
                                                  newQuantity: cartItem
                                                      .quantity - 1,
                                                );
                                              }
                                            },
                                            icon: const Icon(
                                                Icons.remove, size: 20),
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            child: Text(
                                              '${cartItem.quantity}',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: (isLoading ||
                                                cartItem.quantity >=
                                                    cartItem.product
                                                        .getMaxAllowedQuantity())
                                                ? null
                                                : () async {
                                              if (productId != null) {
                                                await cartService
                                                    .updateQuantity(
                                                  productId: productId,
                                                  newQuantity: cartItem
                                                      .quantity + 1,
                                                );
                                              }
                                            },
                                            icon: const Icon(
                                                Icons.add, size: 20),
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: isLoading
                                                ? null
                                                : () async {
                                              if (productId != null) {
                                                await cartService
                                                    .removeFromCart(
                                                  productId: productId,
                                                );
                                              }
                                            },
                                            icon: const Icon(
                                                Icons.delete_outline, size: 20,
                                                color: Colors.red),
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Cart Summary
              Container(
                padding: const EdgeInsets.all(20),
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
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total (${validCartItems.length} items)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            '₹${cartService.totalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(
                                  0xFF1A1A2E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _processPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                            foregroundColor: isDark
                                ? const Color(0xFF1A1A2E)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: isDark ? const Color(0xFF1A1A2E) : Colors
                                  .white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            'PROCEED TO CHECKOUT',
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
              ),
            ],
          ),
        );
      },
    );
  }
}