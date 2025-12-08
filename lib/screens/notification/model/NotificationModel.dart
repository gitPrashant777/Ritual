import 'package:flutter/material.dart';
import 'package:shop/constants.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // e.g., 'order', 'promo', 'system'
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      isRead: json['read'] ?? false, // Backend usually sends 'read' boolean
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  // Helper to get Icon based on type
  IconData get icon {
    switch (type.toLowerCase()) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'promo':
      case 'sale':
        return Icons.local_fire_department_outlined;
      case 'payment':
        return Icons.check_circle_outline;
      case 'delivery':
        return Icons.local_shipping_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  // Helper to get Color based on type
  Color get color {
    switch (type.toLowerCase()) {
      case 'order':
        return successColor;
      case 'promo':
      case 'sale':
        return warningColor;
      case 'payment':
        return const Color(0xFF00C853);
      case 'delivery':
        return const Color(0xFF2979FF);
      default:
        return primaryColor;
    }
  }
}