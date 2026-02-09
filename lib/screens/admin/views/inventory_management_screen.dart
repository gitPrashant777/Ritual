import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/models/user_session.dart';
import 'package:shop/screens/admin/views/components/inventory_product_card.dart';
import 'package:shop/screens/admin/views/components/stock_update_dialog.dart';
import 'package:shop/screens/admin/views/product_management_screen.dart';
import 'package:shop/services/products_api_service.dart';
import 'package:shop/services/auth_api_service.dart';
import 'package:shop/services/api_service.dart';

class InventoryManagementScreen extends StatefulWidget {
  final VoidCallback? onProductUpdated;

  const InventoryManagementScreen({
    super.key,
    this.onProductUpdated,
  });

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  List<ProductModel> products = [];
  bool _isLoading = true;
  String selectedFilter = 'All';
  final List<String> filterOptions = ['All', 'In Stock', 'Out of Stock', 'Low Stock'];
  final ProductsApiService _productsApiService = ProductsApiService();
  final AuthApiService _authApiService = AuthApiService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadProducts();
  }

  Future<void> _checkAuthAndLoadProducts() async {
    setState(() => _isLoading = true);
    
    try {
      // Check if we have an auth token and valid admin session
      final token = await _apiService.getAuthToken();
      final userSession = await UserSession.getUserSession();
      
      if (token == null || userSession == null || 
          userSession['userData'] == null ||
          userSession['userData']['role']?.toString().toLowerCase() != 'admin') {
        throw Exception('Admin authentication required. Please log out and log back in as an administrator.');
      }
      
      print('✅ Admin authentication verified, loading products...');
      
      // Now try to load products
      await _loadProducts();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing admin panel: $e')),
        );
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final loadedProducts = await _productsApiService.getAllProductsForAdmin();
      setState(() {
        products = loadedProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  List<ProductModel> get filteredProducts {
    switch (selectedFilter) {
      case 'In Stock':
        return products.where((p) => !p.isOutOfStock && p.stockQuantity > 5).toList();
      case 'Out of Stock':
        return products.where((p) => p.isOutOfStock || p.stockQuantity <= 0).toList();
      case 'Low Stock':
        return products.where((p) => p.stockQuantity > 0 && p.stockQuantity <= 5).toList();
      default:
        return products;
    }
  }

  void _updateProductStock(ProductModel product, int newStock, int newMaxOrder, bool outOfStock) async {
    try {
      // Create updated product
      final updatedProduct = product.copyWith(
        stockQuantity: newStock,
        maxOrderQuantity: newMaxOrder,
        isOutOfStock: outOfStock,
      );

      // Update via API
      await _productsApiService.updateProduct(product.productId!, updatedProduct);
      
      // Update local state
      setState(() {
        int index = products.indexWhere((p) => p.productId == product.productId);
        if (index != -1) {
          products[index] = updatedProduct;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
      }

      // Notify parent about the update
      widget.onProductUpdated?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
        );
      }
    }
  }

  void _showStockUpdateDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => StockUpdateDialog(
        product: product,
        onUpdate: _updateProductStock,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Inventory Management",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _checkAuthAndLoadProducts,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Products',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(defaultPadding),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Filter Products",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: defaultPadding / 2),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filterOptions.map((filter) {
                      bool isSelected = selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedFilter = filter;
                            });
                          },
                          backgroundColor: Colors.grey.withOpacity(0.1),
                          selectedColor: primaryColor.withOpacity(0.2),
                          checkmarkColor: primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? primaryColor : null,
                            fontWeight: isSelected ? FontWeight.w600 : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Products List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              "assets/icons/Category.svg",
                              height: 64,
                              width: 64,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).disabledColor,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(height: defaultPadding),
                            Text(
                              "No products found",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).disabledColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(defaultPadding),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: defaultPadding),
                            child: InventoryProductCard(
                              product: product,
                              onTap: () => _showStockUpdateDialog(product),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),

    );
  }
}
