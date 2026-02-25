import 'package:flutter/material.dart';
import '../../../../route/route_constants.dart';
import '../../../../services/products_api_service.dart';
// REMOVED: import '../../../product/views/AllProductsScreen.dart';
import '../../../product/views/flash_sale_screen.dart';
import '/components/Banner/M/banner_m_with_counter.dart';
import '../../../../components/product/product_card.dart';
import '../../../../constants.dart';
import '../../../../models/product_model.dart';

// ADDED: Import for the 'See All' screen


class FlashSale extends StatefulWidget {
  const FlashSale({super.key});

  @override
  State<FlashSale> createState() => _FlashSaleState();
}

class _FlashSaleState extends State<FlashSale> {
  final ProductsApiService _apiService = ProductsApiService();
  List<ProductModel> _flashSaleProducts = [];
  bool _isLoading = true;
  bool _hasError = false;
  final titleStyle = TextStyle(
      color: Color(0xFF0b3323), fontWeight: FontWeight.bold, fontSize: 16);
  @override
  void initState() {
    super.initState();
    _fetchFlashSaleProducts();
  }

  // --- THIS IS THE FIX ---
  Future<void> _fetchFlashSaleProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // 1. Call the correct, dedicated API endpoint
      final products = await _apiService.getFlashSaleProducts();

      // 2. Take the first 6 for the home screen
      _flashSaleProducts = products.take(6).toList();


      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching flash sale products: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }
  // --- END OF FIX ---


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0b3323).withOpacity(0.03),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: defaultPadding),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Flash Sale",
                      style: titleStyle,

                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Sale is Live",
                      style: TextStyle(
                        color: const Color(0xFF0b3323).withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                // Timer could be added here if needed

                // --- THIS IS THE FIX ---
                // Wrapped the "SEE ALL" button in a GestureDetector
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FlashSaleScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: defaultPadding,
                      vertical: defaultPadding / 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0b3323),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "SEE ALL",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                // --- END OF FIX ---
              ],
            ),
          ),
          const SizedBox(height: defaultPadding),
          SizedBox(
            height: 240,
            child: _buildProductList(),
          ),
          const SizedBox(height: defaultPadding),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0b3323)),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              "Failed to load flash sale",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchFlashSaleProducts,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0b3323)),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_flashSaleProducts.isEmpty) {
      return Center(
        child: Text(
          "No flash sale products available",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _flashSaleProducts.length,
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(
          right: index == _flashSaleProducts.length - 1 ? 0 : defaultPadding,
        ),
        child: SizedBox(
          width: 160,
          child: ProductCard(
            image: _flashSaleProducts[index].image,
            brandName: _flashSaleProducts[index].brandName ?? "Rituals",
            title: _flashSaleProducts[index].title,
            price: _flashSaleProducts[index].price,
            priceAfetDiscount: _flashSaleProducts[index].priceAfetDiscount,
            dicountpercent: _flashSaleProducts[index].dicountpercent,
            product: _flashSaleProducts[index],
            press: () {
              Navigator.pushNamed(
                context,
                productDetailsScreenRoute,
                arguments: _flashSaleProducts[index],
              );
            },
          ),
        ),
      ),
    );
  }
}