// lib/services/payment_service.dart
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../screens/checkout/views/payment_success_screen.dart';
import 'package:shop/services/cart_service.dart';
import 'package:shop/services/orders_api_service.dart';

class PaymentService {
  static Razorpay? _razorpay;
  static BuildContext? _context;
  static double _currentAmount = 0.0;

  // --- Service References & Data ---
  static OrdersApiService? _ordersApi;
  static CartService? _cartService;
  static List<CartItem>? _cartItems;
  static Map<String, dynamic>? _shippingInfo;

  // --- Initialize Razorpay & Services ---
  static void initialize({
    required BuildContext context,
    required OrdersApiService ordersApi,
    required CartService cartService,
  }) {
    _context = context;
    _ordersApi = ordersApi;
    _cartService = cartService;

    _razorpay ??= Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  // --- Dispose Resources ---
  static void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _context = null;
    _ordersApi = null;
    _cartService = null;
    _cartItems = null;
    _shippingInfo = null;
  }

  // --- Start Payment Process ---
  static void startPayment({
    required String key,
    required double amount,
    required String orderId,
    required List<CartItem> cartItems,
    required Map<String, dynamic> shippingInfo,
    String? customerName,
    String? customerEmail,
    String? customerContact,
  }) {
    _currentAmount = amount;
    _cartItems = cartItems;
    _shippingInfo = shippingInfo;
    print("Amount sent to Razorpay = $amount");

    var options = {
      'key': key,
      'amount': amount.toInt(), // Amount in paise
      'name': 'Ritual App',
      'order_id': orderId,
      'description': 'Payment for Order #$orderId',
      'timeout': 300,
      'prefill': {
        'contact': customerContact ?? '',
        'email': customerEmail ?? '',
        'name': customerName ?? '',
      },
      'theme': {
        'color': '#0b3323',
      },
    };

    try {
      _razorpay?.open(options);
    } catch (e) {
      _showSnackBar('Error starting payment: ${e.toString()}', Colors.red);
    }
  }

  // --- Handle Success ---
  static void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _showSnackBar('Payment Successful! Processing Order...', Colors.green);

    if (_ordersApi == null ||
        _cartService == null ||
        _context == null ||
        _cartItems == null ||
        _shippingInfo == null) {
      _showSnackBar(
          'Error: Payment service not initialized properly.', Colors.red);
      return;
    }

    try {
      // 1. Verify Payment with Backend
      final bool isVerified = await _ordersApi!.verifyPayment(
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );

      if (isVerified) {
        // 2. Prepare Data for Create Order

        // --- FIX: Filter out items with empty Product IDs ---
        final validItems = _cartItems!.where((item) {
          return item.product.productId != null &&
              item.product.productId!.isNotEmpty;
        }).toList();

        if (validItems.isEmpty) {
          _showSnackBar(
              'Error: No valid products found to create order.', Colors.red);
          return;
        }

        // Convert valid items to API format
        List<Map<String, dynamic>> orderItems = validItems.map((item) {
          return {
            "name": item.product.title,
            "price": item.product.priceAfetDiscount ?? item.product.price,
            "quantity": item.quantity,
            "image": item.product.images.isNotEmpty
                ? item.product.images.first
                : "",
            "product": item.product.productId, // This is now guaranteed valid
          };
        }).toList();

        // Calculate totals only for valid items
        double itemsPrice =
        validItems.fold(0.0, (sum, item) => sum + item.totalPrice);
        double taxPrice = 0;
        double shippingPrice = 0;
        double totalPrice = itemsPrice + taxPrice + shippingPrice;

        // 3. Create Final Order in Database
        final orderResult = await _ordersApi!.createOrder(
          shippingInfo: _shippingInfo!,
          orderItems: orderItems,
          paymentInfo: {
            "id": response.paymentId,
            "status": "succeeded",
          },
          itemsPrice: itemsPrice,
          taxPrice: taxPrice,
          shippingPrice: shippingPrice,
          totalPrice: totalPrice,
        );

        if (orderResult != null) {
          // 4. Clear Cart (Client & Server)
          await _cartService!.clearCart();

          // 5. Navigate to Success Screen
          if (_context!.mounted) {
            Navigator.of(_context!).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => PaymentSuccessScreen(
                  paymentId: response.paymentId ?? '',
                  orderId: response.orderId ?? '',
                  amount: _currentAmount,
                ),
              ),
                  (route) => false,
            );
          }
        } else {
          _showSnackBar(
              'Payment verified, but Order creation failed.', Colors.orange);
        }
      } else {
        _showSnackBar(
            'Payment verification failed. Contact support.', Colors.red);
      }
    } catch (e) {
      print("Payment Exception: $e");
      _showSnackBar('Error processing order: $e', Colors.red);
    }
  }

  // --- Handle Failure ---
  static void _handlePaymentError(PaymentFailureResponse response) {
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      _showSnackBar('Payment cancelled', Colors.orange);
    } else {
      _showSnackBar('Payment Failed: ${response.message}', Colors.red);
    }
  }

  // --- Handle External Wallet ---
  static void _handleExternalWallet(ExternalWalletResponse response) {
    _showSnackBar(
        'External Wallet Selected: ${response.walletName}', Colors.blue);
  }

  // --- Helper: Show SnackBar ---
  static void _showSnackBar(String message, Color color) {
    if (_context != null && _context!.mounted) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}