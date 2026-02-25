import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/products_api_service.dart';

class OnSaleScreen extends StatefulWidget {
  const OnSaleScreen({super.key});

  @override
  State<OnSaleScreen> createState() => _OnSaleScreenState();
}

class _OnSaleScreenState extends State<OnSaleScreen> {
  final ProductsApiService _apiService = ProductsApiService();
  List<ProductModel> _saleProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSaleProducts();
  }

  Future<void> _fetchSaleProducts() async {
    try {
      final allProducts = await _apiService.getAllProducts();
      setState(() {
        // Filter for products on sale
        _saleProducts = allProducts.where((p) => p.isOnSale == true).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          // 1. Dynamic App Bar with Banner from Firebase
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                "Special Offers",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
                ),
              ),
              background: StreamBuilder<QuerySnapshot>(
                // Fetch ONLY banners meant for this page
                stream: FirebaseFirestore.instance
                    .collection('banners')
                    .where('type', isEqualTo: 'Sale Page Header')
                    .orderBy('createdAt', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    // Fallback if no banner is set
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0b3323), Color(0xFF04076B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.local_offer_outlined, size: 60, color: Colors.white24),
                      ),
                    );
                  }

                  final banner = snapshot.data!.docs.first;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        banner['imageUrl'],
                        fit: BoxFit.cover,
                      ),
                      // Dark overlay for text readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // 2. Product Grid
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: primaryColor)),
            )
          else if (_saleProducts.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text("No items on sale right now", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(defaultPadding),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  mainAxisSpacing: defaultPadding,
                  crossAxisSpacing: defaultPadding,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return ProductCard(
                      image: _saleProducts[index].image,
                      brandName: _saleProducts[index].brandName ?? "Rituals",
                      title: _saleProducts[index].title,
                      price: _saleProducts[index].price,
                      priceAfetDiscount: _saleProducts[index].priceAfetDiscount,
                      dicountpercent: _saleProducts[index].dicountpercent,
                      product: _saleProducts[index],
                      press: () {
                        Navigator.pushNamed(
                          context,
                          productDetailsScreenRoute,
                          arguments: _saleProducts[index],
                        );
                      },
                    );
                  },
                  childCount: _saleProducts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}