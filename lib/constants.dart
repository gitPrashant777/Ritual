import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'models/product_model.dart';

// Just for demo - High quality jewelry images
const productDemoImg1 = "https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80";
const productDemoImg2 = "https://images.unsplash.com/photo-1606760227091-3dd870d97f1d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80";
const productDemoImg3 = "https://images.unsplash.com/photo-1601821765780-754fa98637c1?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80";
const productDemoImg4 = "https://images.unsplash.com/photo-1588444645841-9d4e0022cbd3?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80";
const productDemoImg5 = "https://images.unsplash.com/photo-1611591437281-460bfbe1220a?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80";
const productDemoImg6 = "https://images.unsplash.com/photo-1596944924616-7b38e7cfac36?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80";
// End For demo

// --- FONT CONSTANTS ---
// ❗️IMPORTANT: You must add these fonts to your pubspec.yaml
const kSerifFont = "Playfair Display";
const kSansSerifFont = "Montserrat";
const grandisExtendedFont = "Grandis Extended";

// --- RITUAL THEME COLORS ---
// Primary Dark Green: #0b3323
// Background Beige: #f6efe3
// Light Green Accent: #D6E4D9 (Soft Sage)

const Color primaryColor = Color(0xFF0B3323);
const Color kPrimaryColor = Color(0xFF0B3323);

// New Ritual Backgrounds
const Color kRitualBeige = Color(0xFFF6EFE3); // Main BG color
const Color kLightGreen = Color(0xFFD6E4D9);  // Accent BG color

// Mapped specific UI colors
const Color kLightBeigeColor = kRitualBeige;
const Color kBorderColor = Color(0xFFEAEBEE);

// Swatch generated based on #0b3323
const MaterialColor primaryMaterialColor =
MaterialColor(0xFF0B3323, <int, Color>{
  50: Color(0xFFE2E7E4),
  100: Color(0xFFB6C2BC),
  200: Color(0xFF869990),
  300: Color(0xFF567064),
  400: Color(0xFF325243),
  500: Color(0xFF0B3323), // Primary
  600: Color(0xFF0A2E1F),
  700: Color(0xFF08271A),
  800: Color(0xFF062015),
  900: Color(0xFF03140C),
});

// Text & Icon Colors (Harmonized with Dark Green)
const Color blackColor = Color(0xFF0B3323); // Replacing pure black with Deep Green
const Color blackColor80 = Color(0xFF3C5C4F);
const Color blackColor60 = Color(0xFF6D857B);
const Color blackColor40 = Color(0xFF9DAEA7);
const Color blackColor20 = Color(0xFFCED6D3);
const Color blackColor10 = Color(0xFFE6EAE9);
const Color blackColor5 = Color(0xFFF2F5F4);

const Color whiteColor = Color(0xFFFFFFFF);
const Color whileColor80 = Color(0xFFCCCCCC);
const Color whileColor60 = Color(0xFF999999);
const Color whileColor40 = Color(0xFF666666);
const Color whileColor20 = Color(0xFF333333);
const Color whileColor10 = Color(0xFF191919);
const Color whileColor5 = Color(0xFF0D0D0D);

const Color greyColor = Color(0xFF6D857B); // Muted green-grey
const Color lightGreyColor = kRitualBeige; // Updated to your Beige BG
const Color darkGreyColor = Color(0xFF0B3323);

const Color purpleColor = Color(0xFF0B3323); // Replaced with theme color
const Color successColor = Color(0xFF2ED573);
const Color warningColor = Color(0xFFFFBE21);
const Color errorColor = Color(0xFFEA5B5B);
// --- END COLORS ---

const double defaultPadding = 20.0;
const double defaultBorderRadious = 12.0;
const Duration defaultDuration = Duration(milliseconds: 300);

// On color 80, 60.... those means opacity
const Color pinkColor = primaryColor; // Kept variable name for compatibility, mapped to primary

final passwordValidator = MultiValidator([
  RequiredValidator(errorText: 'Password is required'),
  MinLengthValidator(8, errorText: 'password must be at least 8 digits long'),
]);

final emaildValidator = MultiValidator([
  RequiredValidator(errorText: 'Email is required'),
  EmailValidator(errorText: "Enter a valid email address"),
]);

const pasNotMatchErrorText = "passwords do not match";

// Demo products list
final List<ProductModel> demoPopularProducts = [
  ProductModel(
    productId: "demo1",
    title: "Diamond Ring",
    brandName: "BAETOWN",
    description: "Beautiful diamond ring",
    category: "Jewelry",
    price: 299.99,
    stockQuantity: 10,
    maxOrderQuantity: 2,
    isOutOfStock: false,
    image: productDemoImg1,
    images: [productDemoImg1, productDemoImg2],
  ),
  ProductModel(
    productId: "demo2",
    title: "Night Cream",
    brandName: "Ritual",
    description: "Elegant gold bracelet",
    category: "Cream",
    price: 199.99,
    stockQuantity: 5,
    maxOrderQuantity: 1,
    isOutOfStock: false,
    image: productDemoImg3,
    images: [productDemoImg3, productDemoImg4],
  ),
  ProductModel(
    productId: "demo3",
    title: "Face Wash",
    brandName: "Ritual",
    description: "Classic silver necklace",
    category: "Jewelry",
    price: 149.99,
    stockQuantity: 8,
    maxOrderQuantity: 3,
    isOutOfStock: false,
    image: productDemoImg5,
    images: [productDemoImg5, productDemoImg6],
  ),
];