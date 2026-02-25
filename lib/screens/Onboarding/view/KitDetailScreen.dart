// lib/screens/Onboarding/view/kit_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/models/SavedKitModel.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/cart_service.dart';

class KitDetailScreen extends StatefulWidget {
  final SavedKitModel kit;

  const KitDetailScreen({super.key, required this.kit});

  @override
  State<KitDetailScreen> createState() => _KitDetailScreenState();
}

class _KitDetailScreenState extends State<KitDetailScreen> {
  final String _imageBaseUrl = "https://mern-backend-t3h8.onrender.com";
  String? _addingProductId;

  // --- SAFE IMAGE BUILDER ---
  String? _buildProductImageUrl(ProductModel product) {
    try {
      String imageUrl = product.image;
      if (imageUrl.isEmpty && product.images.isNotEmpty) {
        imageUrl = product.images.first;
      }
      if (imageUrl.isEmpty) return null;

      if (imageUrl.startsWith('http')) return imageUrl;
      if (imageUrl.startsWith('/')) return '$_imageBaseUrl$imageUrl';
      return '$_imageBaseUrl/$imageUrl';
    } catch (e) {
      return null;
    }
  }

  // --- ADD TO CART LOGIC ---
  Future<void> _addToCart(BuildContext context, ProductModel product) async {
    setState(() => _addingProductId = product.productId);

    try {
      final cartService = Provider.of<CartService>(context, listen: false);
      bool success = await cartService.addToCart(product, quantity: 1);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${product.title} added to cart!"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Could not add to cart."),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _addingProductId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build list items manually to avoid Layout/Index errors
    List<Widget> listItems = [];

    // 1. Header
    listItems.add(_buildDiagnosisCard(context));
    listItems.add(const SizedBox(height: 24));
    listItems.add(Text(
      "Products in this Kit",
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ));
    listItems.add(const SizedBox(height: 16));

    // 2. Products
    if (widget.kit.products.isEmpty) {
      listItems.add(const Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: Text("No products found."),
      )));
    } else {
      for (var product in widget.kit.products) {
        listItems.add(_buildProductCard(context, product));
      }
    }

    // 3. Bottom Padding
    listItems.add(const SizedBox(height: 40));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.kit.kitName.isNotEmpty ? widget.kit.kitName : "Saved Kit",
            style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // Use standard ListView (not builder) for stability
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: listItems,
      ),
    );
  }

  Widget _buildDiagnosisCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Your Diagnosis", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[900])),
          const SizedBox(height: 8),
          Text(widget.kit.diagnosis, style: TextStyle(fontSize: 15, color: Colors.blue[800])),
          const SizedBox(height: 12),
          Text("Assessed on ${widget.kit.assessmentDate}", style: TextStyle(fontSize: 13, color: Colors.blue[700])),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final imageUrl = _buildProductImageUrl(product);
    final price = product.priceAfetDiscount ?? product.price;
    final isLoading = _addingProductId == product.productId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 70, height: 70, color: Colors.grey[100],
              child: imageUrl != null
                  ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image_not_supported))
                  : const Icon(Icons.image_not_supported),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text("₹${price.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0b3323))),
              ],
            ),
          ),
          // Button
          ElevatedButton(
            onPressed: isLoading ? null : () => _addToCart(context, product),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0b3323),
              minimumSize: const Size(60, 36),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("ADD", style: TextStyle(color: Colors.white, fontSize: 12)),
          )
        ],
      ),
    );
  }
}