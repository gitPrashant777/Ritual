import 'package:shop/services/api_service.dart';
import 'package:shop/services/api_config.dart';

import 'NotificationModel.dart';

class NotificationService {
  final ApiService _apiService = ApiService();

  // Fetch all notifications for logged-in user
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _apiService.get(
        ApiConfig.notificationsEndpoint,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final List<dynamic> data = response.data['notifications'] ?? [];
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        throw Exception(response.error ?? 'Failed to load notifications');
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      return []; // Return empty list on error to prevent crash
    }
  }

  // Mark a single notification as read
  Future<bool> markAsRead(String id) async {
    try {
      // Construct endpoint: /notifications/{id}/read
      final endpoint = ApiConfig.notificationReadStatusEndpoint.replaceAll('{id}', id);

      final response = await _apiService.put(
        endpoint,
        requiresAuth: true,
      );

      return response.success;
    } catch (e) {
      print('❌ Error marking notification read: $e');
      return false;
    }
  }
  Future<bool> sendNotification({
    required String title,
    required String message,
    String type = 'system',
    String? userId, // Optional: if you want to target a specific user
  }) async {
    try {
      final Map<String, dynamic> body = {
        'title': title,
        'message': message,
        'type': type,
      };

      // If targeting a specific user, add ID to body
      if (userId != null && userId.isNotEmpty) {
        body['userId'] = userId;
      }

      final response = await _apiService.post(
        ApiConfig.notificationCreateEndpoint,
        body: body,
        requiresAuth: true,
      );

      return response.success;
    } catch (e) {
      print('❌ Error sending notification: $e');
      return false;
    }
  }
}