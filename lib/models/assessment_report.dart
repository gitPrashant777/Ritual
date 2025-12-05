// lib/models/assessment_report.dart
import 'package:flutter/material.dart';

// Helper function to map Icon names
IconData getIconData(String? iconName) {
  const Map<String, IconData> iconMap = {
    "health_and_safety": Icons.health_and_safety,
    "waves": Icons.waves,
    "grass": Icons.grass,
    "local_fire_department": Icons.local_fire_department_outlined,
    "work_outline": Icons.work_outline,
    "sentiment_dissatisfied": Icons.sentiment_dissatisfied_outlined,
    "opacity": Icons.opacity_outlined,
    "highlight_off": Icons.highlight_off,
    "default": Icons.help_outline,
  };
  return iconMap[iconName?.toLowerCase()] ?? Icons.help_outline;
}

class RecommendedProduct {
  final String name;
  final String tag;
  final String description;
  final String price;
  final String discountedPrice;
  final String imageUrl;

  RecommendedProduct({
    required this.name,
    required this.tag,
    required this.description,
    required this.price,
    required this.discountedPrice,
    required this.imageUrl,
  });

  factory RecommendedProduct.fromJson(Map<String, dynamic> json) {
    return RecommendedProduct(
      name: json['name'] as String? ?? 'Unnamed Product',
      tag: json['tag'] as String? ?? '',
      description: json['description'] as String? ?? 'No description available.',
      price: json['price'] as String? ?? '0',
      discountedPrice: json['discountedPrice'] as String? ?? '0',
      imageUrl: json['imageUrl'] as String? ?? 'assets/images/placeholder.png',
    );
  }
}

class RootCause {
  final String name;
  final IconData icon;
  final String description;

  RootCause({
    required this.name,
    required this.icon,
    required this.description,
  });

  factory RootCause.fromJson(Map<String, dynamic> json) {
    return RootCause(
      name: json['name'] as String? ?? 'Unknown Cause',
      icon: getIconData(json['iconName'] as String?),
      description: json['description'] as String? ?? 'No details available.',
    );
  }
}

class AssessmentReport {
  // --- NEW: Validation Fields ---
  final bool isSuccess;
  final String failureReason;

  // Existing Fields
  final String hairDiagnosis;
  final String hairTimeline;
  final int regrowthPossibility;
  final List<RootCause> hairRootCauses;
  final List<RecommendedProduct> recommendedHairKit;
  final String skinDiagnosis;
  final String skinTimeline;
  final List<RootCause> skinRootCauses;
  final List<RecommendedProduct> recommendedSkinKit;
  final List<RecommendedProduct> freeAddOns;
  final String totalPrice;
  final String discountedTotalPrice;

  AssessmentReport({
    this.isSuccess = true, // Default to true for backward compatibility
    this.failureReason = '',
    required this.hairDiagnosis,
    required this.hairTimeline,
    required this.regrowthPossibility,
    required this.hairRootCauses,
    required this.recommendedHairKit,
    required this.skinDiagnosis,
    required this.skinTimeline,
    required this.skinRootCauses,
    required this.recommendedSkinKit,
    required this.freeAddOns,
    required this.totalPrice,
    required this.discountedTotalPrice,
  });

  // --- NEW: Factory for Failure State ---
  factory AssessmentReport.failure(String reason) {
    return AssessmentReport(
      isSuccess: false,
      failureReason: reason,
      // Provide empty defaults so the UI doesn't crash before checking isSuccess
      hairDiagnosis: '', hairTimeline: '', regrowthPossibility: 0,
      hairRootCauses: [], recommendedHairKit: [],
      skinDiagnosis: '', skinTimeline: '', skinRootCauses: [], recommendedSkinKit: [],
      freeAddOns: [], totalPrice: '', discountedTotalPrice: '',
    );
  }

  factory AssessmentReport.fromJson(Map<String, dynamic> json) {
    // 1. CHECK FOR VALIDATION FAILURE FROM AI
    if (json['isValidImage'] == false) {
      return AssessmentReport.failure(
          json['validationError'] ?? "We could not detect a clear skin or scalp image."
      );
    }

    List<T> parseList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final list = json[key] as List<dynamic>?;
      if (list == null) return [];
      return list.map((item) => fromJson(item)).toList();
    }

    // (Existing parsing logic)
    final rawHair = parseList('recommendedHairKit', RecommendedProduct.fromJson);
    final rawSkin = parseList('recommendedSkinKit', RecommendedProduct.fromJson);

    final filteredHair = rawHair.where((product) {
      final text = (product.name + product.tag + product.description).toLowerCase();
      return text.contains("hair");
    }).toList();

    final filteredSkin = rawSkin.where((product) {
      final text = (product.name + product.tag + product.description).toLowerCase();
      return text.contains("face");
    }).toList();

    final defaultHairProducts = [
      RecommendedProduct(name: "Hair Growth Serum", tag: "hair", description: "Promotes stronger, thicker hair", price: "499", discountedPrice: "399", imageUrl: "https://via.placeholder.com/400x400.png?text=Hair+Serum"),
      RecommendedProduct(name: "Anti-Hairfall Shampoo", tag: "hair", description: "Reduces hair breakage", price: "299", discountedPrice: "249", imageUrl: "https://via.placeholder.com/400x400.png?text=Hair+Shampoo"),
    ];

    final defaultSkinProducts = [
      RecommendedProduct(name: "Face Cleanser", tag: "face", description: "Gentle cleanser for glowing skin", price: "399", discountedPrice: "299", imageUrl: "https://via.placeholder.com/400x400.png?text=Face+Wash"),
      RecommendedProduct(name: "Vitamin C Serum", tag: "face", description: "Brightens and repairs skin barrier", price: "699", discountedPrice: "499", imageUrl: "https://via.placeholder.com/400x400.png?text=Face+Serum"),
    ];

    final finalHair = filteredHair.isNotEmpty ? filteredHair : rawHair.isNotEmpty ? rawHair : defaultHairProducts;
    final finalSkin = filteredSkin.isNotEmpty ? filteredSkin : rawSkin.isNotEmpty ? rawSkin : defaultSkinProducts;

    return AssessmentReport(
      isSuccess: true,
      failureReason: '',
      hairDiagnosis: json['hairDiagnosis'] ?? 'Analysis Incomplete',
      hairTimeline: json['hairTimeline'] ?? 'N/A',
      regrowthPossibility: json['regrowthPossibility'] ?? 0,
      hairRootCauses: parseList('hairRootCauses', RootCause.fromJson),
      recommendedHairKit: finalHair,
      skinDiagnosis: json['skinDiagnosis'] ?? 'Analysis Incomplete',
      skinTimeline: json['skinTimeline'] ?? 'N/A',
      skinRootCauses: parseList('skinRootCauses', RootCause.fromJson),
      recommendedSkinKit: finalSkin,
      freeAddOns: parseList('freeAddOns', RecommendedProduct.fromJson),
      totalPrice: json['totalPrice'] ?? '0',
      discountedTotalPrice: json['discountedTotalPrice'] ?? '0',
    );
  }
}