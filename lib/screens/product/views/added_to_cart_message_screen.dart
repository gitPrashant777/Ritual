import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart'; // Ensure this matches your route constant file

class AddedToCartMessageScreen extends StatelessWidget {
  const AddedToCartMessageScreen({super.key});

  // --- Ritual Color Ritual ---
  static const Color brandPrimary = Color(0xFF0B3323); // Deep Green
  static const Color ritualCream = Color(0xFFF6EFE3);   // Cream BG
  static const Color scaffoldBg = Color(0xFFFAF9F6);    // Off-White

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            children: [
              const Spacer(),
              // Success Illustration
              Image.asset(
                isDark
                    ? "assets/Illustration/success_dark.png"
                    : "assets/Illustration/success.png",
                height: MediaQuery.of(context).size.height * 0.25,
              ),
              const Spacer(flex: 2),

              // Title
              Text(
                "Added to Cart",
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : brandPrimary,
                  fontFamily: 'Serif', // Matching your brand typography
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                "Click the checkout button to complete\nthe purchase process.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 2),

              // 1. Continue Shopping Button (Navigates to Home/EntryPoint)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    // This returns to the main dashboard/home
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      entryPointScreenRoute,
                          (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brandPrimary,
                    side: const BorderSide(color: brandPrimary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "CONTINUE SHOPPING",
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
              ),
              const SizedBox(height: defaultPadding),

              // 2. Checkout Button (Navigates to Cart Screen)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigates directly to the Cart
                    Navigator.pushNamed(context, cartScreenRoute);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "CHECKOUT",
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}