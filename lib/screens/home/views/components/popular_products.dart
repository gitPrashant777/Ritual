import 'package:flutter/material.dart';
import 'package:shop/screens/product/views/AllProductsScreen.dart';
import '../../../../components/product/product_card.dart';
import '../../../../models/product_model.dart';
import '../../../../route/route_constants.dart';
import '../../../../constants.dart';
import '../../../../services/products_api_service.dart';

class PopularProducts extends StatefulWidget {
  const PopularProducts({super.key});

  @override
  State<PopularProducts> createState() => _PopularProductsState();
}

class _PopularProductsState extends State<PopularProducts> {
  final ProductsApiService _apiService = ProductsApiService();
  List<ProductModel> _popularProducts = [];
  bool _isLoading = true;
  bool _hasError = false;
  final titleStyle = TextStyle(
      color: Color(0xFF0b3323), fontWeight: FontWeight.bold, fontSize: 16);
  List<ProductModel> _firstRowProducts = [];
  List<ProductModel> _secondRowProducts = [];

  double get listHeight {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600 ? 220.0 : 240.0;
  }

  double get totalHeight {
    if (_isLoading || _hasError || _popularProducts.isEmpty) {
      return listHeight;
    }
    if (_secondRowProducts.isNotEmpty) {
      return (listHeight * 2) + defaultPadding;
    }
    return listHeight;
  }

  @override
  void initState() {
    super.initState();
    _fetchPopularProducts();
  }

  Future<void> _fetchPopularProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final allProducts = await _apiService.getAllProducts();
      final popularProducts = allProducts.where((product) => product.isPopular == true).toList();

      if (popularProducts.isEmpty && allProducts.isNotEmpty) {
        _popularProducts = allProducts.take(12).toList();
      } else {
        _popularProducts = popularProducts.take(12).toList();
      }

      if (_popularProducts.length > 6) {
        _firstRowProducts = _popularProducts.sublist(0, 6);
        _secondRowProducts = _popularProducts.sublist(
          6,
          _popularProducts.length > 12 ? 12 : _popularProducts.length,
        );
      } else {
        _firstRowProducts = _popularProducts;
        _secondRowProducts = [];
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching popular products: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      color: const Color(0xFFFAFAFA), // Light background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: defaultPadding),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "All Products",
                  style: titleStyle
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (builder) => AllProductsScreen()),
                    );
                  },
                  child: Text(
                    "SEE ALL",
                    style: TextStyle(
                      color: const Color(0xFF0b3323),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: defaultPadding / 2),
          SizedBox(
            height: totalHeight,
            child: _buildContent(screenWidth),
          ),
          const SizedBox(height: defaultPadding),
        ],
      ),
    );
  }

  Widget _buildContent(double screenWidth) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0b3323)));
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              "Failed to load products",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchPopularProducts,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0b3323)),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_popularProducts.isEmpty) {
      return Center(
        child: Text(
          "No popular products available",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // First Row
        SizedBox(
          height: listHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _firstRowProducts.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(
                left: defaultPadding,
                right: index == _firstRowProducts.length - 1 ? defaultPadding : 0,
              ),
              child: SizedBox(
                width: screenWidth < 600 ? 140 : 160,
                child: ProductCard(
                  image: _firstRowProducts[index].image,
                  brandName: _firstRowProducts[index].brandName ?? "Rituals",
                  title: _firstRowProducts[index].title,
                  price: _firstRowProducts[index].price,
                  priceAfetDiscount: _firstRowProducts[index].priceAfetDiscount,
                  dicountpercent: _firstRowProducts[index].dicountpercent,
                  product: _firstRowProducts[index],
                  press: () {
                    Navigator.pushNamed(
                      context,
                      productDetailsScreenRoute,
                      arguments: _firstRowProducts[index],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (_secondRowProducts.isNotEmpty) const SizedBox(height: defaultPadding),
        if (_secondRowProducts.isNotEmpty)
        // Second Row
          SizedBox(
            height: listHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _secondRowProducts.length,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(
                  left: defaultPadding,
                  right: index == _secondRowProducts.length - 1 ? defaultPadding : 0,
                ),
                child: SizedBox(
                  width: screenWidth < 600 ? 140 : 160,
                  child: ProductCard(
                    image: _secondRowProducts[index].image,
                    brandName: _secondRowProducts[index].brandName ?? "Rituals",
                    title: _secondRowProducts[index].title,
                    price: _secondRowProducts[index].price,
                    priceAfetDiscount: _secondRowProducts[index].priceAfetDiscount,
                    dicountpercent: _secondRowProducts[index].dicountpercent,
                    product: _secondRowProducts[index],
                    press: () {
                      Navigator.pushNamed(
                        context,
                        productDetailsScreenRoute,
                        arguments: _secondRowProducts[index],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
