import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/components/network_image_with_loader.dart';
import 'package:shop/services/cart_service.dart';
import 'package:shop/models/cart_item_model.dart';
import 'package:shop/constants.dart';

// Ensure these imports match your project structure
import 'package:shop/services/orders_api_service.dart';
import 'package:shop/services/address_api_service.dart';
import 'package:shop/models/AddressModel.dart';
import 'package:shop/services/payment_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late OrdersApiService _ordersApi;
  // Assumes you have an AddressApiService. If not, you need to create one.
  final AddressApiService _addressApi = AddressApiService();

  // --- COLOR RITUAL ---
  static const brandPrimary = Color(0xFF0b3323); // Deep Green
  static const creamColor = Color(0xFFf6efe3);   // Cream BG
  static const lightGreen = Color(0xFF81C784);   // Light Green Accent
  // --------------------

  @override
  void initState() {
    super.initState();
    _ordersApi = Provider.of<OrdersApiService>(context, listen: false);

    // --- FIX: Get the CartService, NOT CartApiService ---
    final cartService = Provider.of<CartService>(context, listen: false);

    // Initialize Payment Service
    PaymentService.initialize(
      context: context,
      ordersApi: _ordersApi,
      cartService: cartService, // Pass the full service here
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartService>(context, listen: false).fetchCart();
    });
  }

  @override
  void dispose() {
    PaymentService.dispose();
    super.dispose();
  }

  // --- 1. CHECKOUT FLOW START ---
  Future<void> _handleCheckout() async {
    final cartService = Provider.of<CartService>(context, listen: false);
    if (cartService.items.isEmpty) {
      _showSnack('Your cart is empty!', Colors.red);
      return;
    }

    // Show loading while fetching addresses
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(
          child: CircularProgressIndicator(color: brandPrimary)),
    );

    try {
      final addresses = await _addressApi.getAddresses();
      if (mounted) Navigator.pop(context); // Close loading

      if (addresses.isEmpty) {
        _showAddAddressDialog();
      } else {
        _showSelectAddressSheet(addresses);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      // In case Address API isn't ready, you can uncomment this to bypass for testing:
      // _processPayment(AddressModel(street: "Test St", city: "Test City", state: "ST", country: "IN", postalCode: "110001", isDefault: true, id: "1"));
      _showSnack('Failed to load addresses: $e', Colors.red);
    }
  }

  // --- 2. ADDRESS SELECTION SHEET ---
  void _showSelectAddressSheet(List<AddressModel> addresses) {
    showModalBottomSheet(
      context: context,
      backgroundColor: creamColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Shipping Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: brandPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final addr = addresses[index];
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: brandPrimary.withOpacity(0.1)),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(Icons.location_on_outlined,
                            color: brandPrimary),
                        title: Text(
                          "${addr.street}, ${addr.city}",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: brandPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          "${addr.state}, ${addr.country} - ${addr.postalCode}",
                          style:
                          TextStyle(color: brandPrimary.withOpacity(0.6)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.pop(context); // Close sheet
                          _processPayment(addr); // Proceed to Payment
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/add_address');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add New Address"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brandPrimary,
                    side: const BorderSide(color: brandPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _showAddAddressDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("No Address Found"),
        content: const Text("Please add a shipping address to continue."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/add_address');
            },
            style: ElevatedButton.styleFrom(backgroundColor: brandPrimary),
            child: const Text("Add Address",
                style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- 3. PAYMENT PROCESSING ---
  Future<void> _processPayment(AddressModel selectedAddress) async {
    final cartService = Provider.of<CartService>(context, listen: false);
    final totalAmount = cartService.totalPrice;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              CircularProgressIndicator(
                color: isDark ? Colors.white : brandPrimary,
              ),
              const SizedBox(width: 20),
              Text(
                'Initializing Payment...',
                style: TextStyle(
                  color: isDark ? Colors.white : brandPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      // 1. Get Key
      final String? razorpayKey = await _ordersApi.getRazorpayKey();
      if (razorpayKey == null) throw Exception('Failed to get Razorpay key.');

      // 2. Create Order on Backend
      final orderData = await _ordersApi.createRazorpayOrder(totalAmount);
      if (orderData == null || orderData['id'] == null) {
        throw Exception('Failed to create order on backend.');
      }

      final String razorpayOrderId = orderData['id'];

      // Ensure we parse the amount correctly as double
      double serverAmount = 0.0;
      if (orderData['amount'] is int) {
        serverAmount = (orderData['amount'] as int).toDouble();
      } else if (orderData['amount'] is double) {
        serverAmount = orderData['amount'];
      } else if (orderData['amount'] is String) {
        serverAmount = double.parse(orderData['amount']);
      }

      if (mounted) Navigator.of(context).pop(); // Dismiss loading

      // 3. Prepare Shipping Info Map
      final shippingInfoMap = {
        "address": selectedAddress.street,
        "city": selectedAddress.city,
        "state": selectedAddress.state,
        "country": selectedAddress.country,
        "pinCode": int.tryParse(selectedAddress.postalCode) ?? 000000,
        "phoneNo": 9999999999,
      };

      // 4. Start Payment
      PaymentService.startPayment(
        key: razorpayKey,
        amount: serverAmount, // Backend usually returns amount in Paise
        orderId: razorpayOrderId,
        cartItems: cartService.items,
        shippingInfo: shippingInfoMap,
        customerName: 'Customer', // You can fetch this from UserSession if available
        customerEmail: 'customer@example.com',
      );
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Dismiss loading
      _showSnack('Error: ${e.toString()}', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, CartService cartService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 12),
            Text(
              'Clear Cart',
              style: TextStyle(
                color: isDark ? Colors.white : brandPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove all items from cart?',
          style: TextStyle(
            color: isDark ? Colors.white70 : brandPrimary.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white70 : brandPrimary.withOpacity(0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Close dialog first
              Navigator.pop(dialogContext);

              final bool success = await cartService.clearCart();

              if (success && mounted) {
                _showSnack('Cart cleared successfully', brandPrimary);
              } else if (!success && mounted) {
                _showSnack('Failed to clear cart', Colors.red);
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme Variables
    final backgroundColor = isDark ? const Color(0xFF0F0F0F) : creamColor;
    final textColor = isDark ? Colors.white : brandPrimary;
    final subTextColor = isDark ? Colors.white60 : brandPrimary.withOpacity(0.6);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Consumer<CartService>(
      builder: (context, cartService, child) {
        final allItems = cartService.items;
        final isLoading = cartService.isLoading;

        // Filter out "Ghost" Items (items with missing IDs)
        final validCartItems = allItems.where((item) {
          final hasId = item.product.productId != null &&
              item.product.productId!.isNotEmpty;
          return hasId;
        }).toList();

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: textColor,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Cart (${validCartItems.length})',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: textColor,
              ),
            ),
            actions: [
              if (validCartItems.isNotEmpty)
                IconButton(
                  onPressed: () => _showClearCartDialog(context, cartService),
                  icon: Icon(
                    Icons.delete_outline,
                    color: textColor,
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: isLoading && validCartItems.isEmpty
              ? Center(child: CircularProgressIndicator(color: brandPrimary))
              : validCartItems.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 100,
                  color: isDark
                      ? Colors.white24
                      : brandPrimary.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Cart is Empty',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add items to your cart to see them here',
                  style: TextStyle(
                    color: subTextColor,
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
                      horizontal: 16, vertical: 16),
                  itemCount: validCartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = validCartItems[index];
                    final String? productId = cartItem.product.productId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : brandPrimary.withOpacity(0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                                    : creamColor,
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
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (cartItem.product.brandName ??
                                      "Rituals")
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                    color: subTextColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cartItem.product.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (cartItem.product.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    cartItem.product.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subTextColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 12),

                                // Price and Controls
                                Row(
                                  children: [
                                    Text(
                                      '₹${cartItem.product.priceAfetDiscount ?? cartItem.product.price}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const Spacer(),

                                    // Quantity Controls
                                    Container(
                                      height: 36,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white12
                                              : brandPrimary.withOpacity(0.2),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: (isLoading ||
                                                cartItem.quantity <= 1)
                                                ? null
                                                : () async {
                                              if (productId != null) {
                                                await cartService.updateQuantity(
                                                  productId: productId,
                                                  newQuantity: cartItem.quantity - 1,
                                                );
                                              }
                                            },
                                            icon: Icon(Icons.remove,
                                                size: 16,
                                                color: textColor),
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                          ),
                                          Container(
                                            alignment: Alignment.center,
                                            constraints: const BoxConstraints(minWidth: 20),
                                            child: Text(
                                              '${cartItem.quantity}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: textColor,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: (isLoading ||
                                                cartItem.quantity >= cartItem.product.getMaxAllowedQuantity())
                                                ? null
                                                : () async {
                                              if (productId != null) {
                                                await cartService.updateQuantity(
                                                  productId: productId,
                                                  newQuantity: cartItem.quantity + 1,
                                                );
                                              }
                                            },
                                            icon: Icon(Icons.add,
                                                size: 16,
                                                color: textColor),
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Delete Button
                                    IconButton(
                                      onPressed: isLoading
                                          ? null
                                          : () async {
                                        if (productId != null) {
                                          await cartService.removeFromCart(
                                            productId: productId,
                                          );
                                        }
                                      },
                                      icon: Icon(
                                          Icons.delete_outline,
                                          size: 22,
                                          color: Colors.red[400]),
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
                  color: cardColor,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: brandPrimary.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total (${validCartItems.length} items)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: subTextColor,
                            ),
                          ),
                          Text(
                            '₹${cartService.totalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleCheckout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandPrimary,
                            foregroundColor: creamColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: creamColor,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            'PROCEED TO CHECKOUT',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
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