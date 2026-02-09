
import 'package:flutter/material.dart';

// Helper function to map Icon names from the AI to Flutter Icons
IconData getIconData(String? iconName) {
const Map<String, IconData> iconMap = {
// Standard Icons
"health_and_safety": Icons.health_and_safety,
"waves": Icons.waves,
"grass": Icons.grass,
"local_fire_department": Icons.local_fire_department, // Fixed: removed _outlined for consistency
"work_outline": Icons.work_outline,
"sentiment_dissatisfied": Icons.sentiment_dissatisfied_outlined,
"opacity": Icons.opacity,
"highlight_off": Icons.highlight_off,

// --- NEW AYURVEDIC ICONS (Required for new AI Prompt) ---
"bedtime": Icons.bedtime,           // For Sleep
"restaurant": Icons.restaurant,     // For Diet
"psychology": Icons.psychology,     // For Stress
"spa": Icons.spa,                   // For Lifestyle
"healing": Icons.healing,           // For Acne/Recovery
"wb_sunny": Icons.wb_sunny,         // For Sun Sensitivity
"ac_unit": Icons.ac_unit,           // For Cooling/Pitta
"water_drop": Icons.water_drop,     // For Hydration
"warning": Icons.warning_amber_rounded, // For Allergies
"face": Icons.face,                 // For Face/Skin General
"self_improvement": Icons.self_improvement, // For Yoga/Meditation

// Default fallback
"default": Icons.info_outline,
};

// Return the mapped icon, or a default if the AI sends something unexpected
return iconMap[iconName?.toLowerCase()] ?? Icons.info_outline;
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
imageUrl: json['imageUrl'] as String? ?? '',
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
// Maps the string from JSON to an actual Flutter Icon
icon: getIconData(json['iconName'] as String?),
description: json['description'] as String? ?? 'No details available.',
);
}
}

class AssessmentReport {
// Validation Fields
final bool isSuccess;
final String failureReason;

// Analysis Fields
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
this.isSuccess = true,
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

// Factory for Failure State (Invalid Image, API Error, etc.)
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

// Helper to safely parse lists
List<T> parseList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
final list = json[key] as List<dynamic>?;
if (list == null) return [];
return list.map((item) => fromJson(item)).toList();
}

// Parse kits (can be empty from AI as we mostly use backend products)
final rawHair = parseList('recommendedHairKit', RecommendedProduct.fromJson);
final rawSkin = parseList('recommendedSkinKit', RecommendedProduct.fromJson);

// Fallback logic for kits is handled here (optional, can be removed if relying 100% on backend matching)
final defaultHairProducts = [
RecommendedProduct(name: "Hair Growth Serum", tag: "hair", description: "Promotes stronger, thicker hair", price: "499", discountedPrice: "399", imageUrl: ""),
];
final defaultSkinProducts = [
RecommendedProduct(name: "Face Cleanser", tag: "face", description: "Gentle cleanser for glowing skin", price: "399", discountedPrice: "299", imageUrl: ""),
];

final finalHair = rawHair.isNotEmpty ? rawHair : defaultHairProducts;
final finalSkin = rawSkin.isNotEmpty ? rawSkin : defaultSkinProducts;

return AssessmentReport(
isSuccess: true,
failureReason: '',

hairDiagnosis: json['hairDiagnosis'] ?? 'Analysis Incomplete',
hairTimeline: json['hairTimeline'] ?? '3-6 months',
regrowthPossibility: (json['regrowthPossibility'] is int)
? json['regrowthPossibility']
    : int.tryParse(json['regrowthPossibility'].toString()) ?? 50,

hairRootCauses: parseList('hairRootCauses', RootCause.fromJson),
recommendedHairKit: finalHair,

skinDiagnosis: json['skinDiagnosis'] ?? 'Analysis Incomplete',
skinTimeline: json['skinTimeline'] ?? '4-8 weeks',
skinRootCauses: parseList('skinRootCauses', RootCause.fromJson),
recommendedSkinKit: finalSkin,

freeAddOns: parseList('freeAddOns', RecommendedProduct.fromJson),
totalPrice: json['totalPrice'] ?? '0',
discountedTotalPrice: json['discountedTotalPrice'] ?? '0',
);
}
}
