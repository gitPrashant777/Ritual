// ignore_for_file: avoid_print
import 'package:shop/services/api_config.dart';
import 'package:shop/services/api_service.dart';

class OrdersApiService {
  final ApiService _apiService; // <-- No new instance

  // Add this constructor
  OrdersApiService(this._apiService);

  // --- ADDED: Method to get Razorpay key ---
  /// Fetches the Razorpay Key from your backend
  Future<String?> getRazorpayKey() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConfig.getRazorpayKeyEndpoint,
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        return response.data!['key']; // Assumes backend returns { "key": "..." }
      }
      print('Failed to get Razorpay key: ${response.error}');
      return null;
    } catch (e) {
      print('Error fetching Razorpay key: $e');
      return null;
    }
  }

  // --- ADDED: Method to create Razorpay order ---
  /// Creates a new Razorpay order on your backend
  Future<Map<String, dynamic>?> createRazorpayOrder(double amount) async {
    try {
      // This endpoint creates the Razorpay order and returns its details
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.processPaymentsEndpoint,
        body: {'amount': (amount).toInt()}, // Send amount in paise
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        // Assumes backend returns { "success": true, "order": { "id": "razorpay_order_id", "amount": ... } }
        return response.data!['order'];
      }
      print('Failed to create razorpay order: ${response.error}');
      return null;
    } catch (e) {
      print('Error creating razorpay order: $e');
      return null;
    }
  }

  // --- ADDED: Method to verify payment ---
  /// Verifies the payment with your backend
  Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.verifyPaymentEndpoint,
        body: {
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        },
        requiresAuth: true,
      );
      // Assumes backend returns { "success": true } on valid payment
      return response.success;
    } catch (e) {
      print('Error verifying payment: $e');
      return false;
    }
  }

  // 🧾 Get all orders of the current logged-in user
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConfig.getAllOrdersOfUserEndpoint,
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data!['orders'] ?? []);
      }
      print('Failed to get user orders: ${response.error}');
      return [];
    } catch (e) {
      print('Error getting user orders: $e');
      return [];
    }
  }

  // 📦 Get order by ID
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final endpoint = ApiConfig.getOrderByIdEndpoint.replaceAll('{id}', orderId);
      final response = await _apiService.get<Map<String, dynamic>>(
        endpoint,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return response.data!;
      }
      print('Failed to get order: ${response.error}');
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  // 🛍️ Create a new order (Saves the final order to DB)
  Future<Map<String, dynamic>?> createOrder({
    required Map<String, dynamic> shippingInfo,
    required List<Map<String, dynamic>> orderItems,
    required Map<String, dynamic> paymentInfo,
    required double itemsPrice,
    required double taxPrice,
    required double shippingPrice,
    required double totalPrice,
  }) async {
    try {
      final orderData = {
        'shippingInfo': shippingInfo,
        'orderItems': orderItems,
        'paymentInfo': paymentInfo,
        'itemsPrice': itemsPrice,
        'taxPrice': taxPrice,
        'shippingPrice': shippingPrice,
        'totalPrice': totalPrice,
      };

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.newOrderEndpoint,
        body: orderData,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return response.data!;
      }
      print('Failed to create order: ${response.error}');
      return null;
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }

  // 🧑‍💼 Update order status (admin only)
  Future<Map<String, dynamic>?> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      final endpoint = ApiConfig.updateOrderStatusEndpoint.replaceAll('{id}', orderId);
      final updateData = {'status': status};

      final response = await _apiService.put<Map<String, dynamic>>(
        endpoint,
        body: updateData,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return response.data!;
      }
      print('Failed to update order status: ${response.error}');
      return null;
    } catch (e) {
      print('Error updating order status: $e');
      return null;
    }
  }

  // ❌ Delete an order (admin only)
  Future<bool> deleteOrder(String orderId) async {
    try {
      final endpoint = ApiConfig.deleteOrderEndpoint.replaceAll('{id}', orderId);

      final response = await _apiService.delete<Map<String, dynamic>>(
        endpoint,
        requiresAuth: true,
      );

      return response.success;
    } catch (e) {
      print('Error deleting order: $e');
      return false;
    }
  }

  // 📜 Get all orders (admin only)
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConfig.getAllOrdersEndpoint,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data!['orders'] ?? []);
      }
      print('Failed to get all orders: ${response.error}');
      return [];
    } catch (e) {
      print('Error getting all orders: $e');
      return [];
    }
  }

  // 🔄 Process order return/refund
  Future<Map<String, dynamic>?> processReturn({
    required String orderId,
    required String reason,
    List<String>? itemIds,
  }) async {
    try {
      final returnData = {
        'reason': reason,
        if (itemIds != null) 'itemIds': itemIds,
      };

      final endpoint = '/order/$orderId/return'; // not in ApiConfig, manually constructed
      final response = await _apiService.post<Map<String, dynamic>>(
        endpoint,
        body: returnData,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return response.data!;
      }
      print('Failed to process return: ${response.error}');
      return null;
    } catch (e) {
      print('Error processing return: $e');
      return null;
    }
  }

  // 🚚 Cancel order (user)
  Future<bool> cancelOrder(String orderId) async {
    try {
      final endpoint = '/order/$orderId/cancel'; // manual path if not in ApiConfig
      final response = await _apiService.put<Map<String, dynamic>>(
        endpoint,
        body: {},
        requiresAuth: true,
      );
      return response.success;
    } catch (e) {
      print('Error canceling order: $e');
      return false;
    }
  }
}