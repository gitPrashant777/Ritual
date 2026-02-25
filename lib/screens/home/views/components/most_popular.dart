import 'package:flutter/material.dart';
// 1. CHANGED: Imported ProductCard instead of SecondaryProductCard
import 'package:shop/components/product/product_card.dart';
import 'package:shop/models/product_model.dart';
// 2. CHANGED: Imported AllProductsScreen for navigation
import 'package:shop/screens/product/views/AllProductsScreen.dart';
import 'package:shop/screens/product/views/MostPopularScreen.dart';
import 'package:shop/services/products_api_service.dart';
import '../../../../constants.dart';
import '../../../../route/route_constants.dart';

class MostPopular extends StatefulWidget {
  const MostPopular({super.key});

  @override
  State<MostPopular> createState() => _MostPopularState();
}

class _MostPopularState extends State<MostPopular> {
  final ProductsApiService _apiService = ProductsApiService();

  List<ProductModel> _mostPopularProducts = [];
  bool _isLoading = true;
  bool _hasError = false;
  final titleStyle = const TextStyle(
      color: Color(0xFF0b3323), fontWeight: FontWeight.bold, fontSize: 18);
  List<ProductModel> _firstRowProducts = [];
  List<ProductModel> _secondRowProducts = [];

  double get listHeight {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600 ? 220.0 : 240.0;
  }

  double get totalHeight {
    if (_isLoading || _hasError || _mostPopularProducts.isEmpty) {
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
    _fetchMostPopularProducts();
  }

  Future<void> _fetchMostPopularProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final allProducts = await _apiService.getAllProducts();
      final popularProducts =
      allProducts.where((product) => product.isPopular == true).toList();

      if (popularProducts.isEmpty && allProducts.isNotEmpty) {
        _mostPopularProducts = allProducts.take(12).toList();
      } else {
        _mostPopularProducts = popularProducts.take(12).toList();
      }

      if (_mostPopularProducts.length > 6) {
        _firstRowProducts = _mostPopularProducts.sublist(0, 6);
        _secondRowProducts = _mostPopularProducts.sublist(
          6,
          _mostPopularProducts.length > 12 ? 12 : _mostPopularProducts.length,
        );
      } else {
        _firstRowProducts = _mostPopularProducts;
        _secondRowProducts = [];
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
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
      color: const Color(0xFFFAFAFA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: defaultPadding),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Most Popular Products", style: titleStyle),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (builder) => const MostPopularScreen()),
                    );
                  },
                  child: const Text(
                    "SEE ALL",
                    style: TextStyle(
                      color: Color(0xFF0b3323),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0b3323)));
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              "Failed to load products",
              style:
              Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _fetchMostPopularProducts,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0b3323)),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_mostPopularProducts.isEmpty) {
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
                right:
                index == _firstRowProducts.length - 1 ? defaultPadding : 0,
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
                  right:
                  index == _secondRowProducts.length - 1 ? defaultPadding : 0,
                ),
                child: SizedBox(
                  width: screenWidth < 600 ? 140 : 160,
                  child: ProductCard(
                    image: _secondRowProducts[index].image,
                    brandName:
                    _secondRowProducts[index].brandName ?? "Rituals",
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
