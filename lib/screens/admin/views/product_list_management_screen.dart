import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/screens/admin/views/product_management_screen_with_cloudinary.dart';
import 'package:shop/services/products_api_service.dart';

class ProductListManagementScreen extends StatefulWidget {
  const ProductListManagementScreen({super.key});

  @override
  State<ProductListManagementScreen> createState() => _ProductListManagementScreenState();
}

class _ProductListManagementScreenState extends State<ProductListManagementScreen> {
  List<ProductModel> products = [];
  bool _isLoading = true;
  String selectedFilter = 'All';
  final List<String> filterOptions = ['All', 'In Stock', 'Out of Stock', 'Low Stock'];
  final ProductsApiService _productsApiService = ProductsApiService();

  // 1. Search Controller
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    // 2. Listen to search input changes
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // 3. Dispose controller
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    print('🔄 Loading products from API...');
    setState(() => _isLoading = true);
    try {
      // ---------------------------------------------------------
      // FIX: Changed from getAllProducts() to getAllProductsForAdmin()
      // This fetches all products (high limit) instead of just 8
      // ---------------------------------------------------------
      final loadedProducts = await _productsApiService.getAllProductsForAdmin();

      print('📦 Products loaded: ${loadedProducts.length}');
      setState(() {
        products = loadedProducts;
        _isLoading = false;
      });
      print('✅ Products updated in UI: ${products.length}');
    } catch (e) {
      print('❌ Error loading products: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  // Find this part in your code and REPLACE it
  List<ProductModel> get filteredProducts {
    List<ProductModel> result;

    // 1. Filter by Status (Tabs)
    switch (selectedFilter) {
      case 'In Stock':
        result = products.where((p) => !p.isOutOfStock && p.stockQuantity > 5).toList();
        break;
      case 'Out of Stock':
        result = products.where((p) => p.isOutOfStock || p.stockQuantity <= 0).toList();
        break;
      case 'Low Stock':
        result = products.where((p) => p.stockQuantity > 0 && p.stockQuantity <= 5).toList();
        break;
      default:
        result = List.from(products);
    }

    // 2. Filter by Search Text
    // Change: Added .trim() to ignore spaces at start/end
    String query = _searchController.text.toLowerCase().trim();

    if (query.isNotEmpty) {
      result = result.where((p) {
        final title = p.title.toLowerCase();
        // Change: Handle null brand names safely
        final brand = (p.brandName ?? '').toLowerCase();

        return title.contains(query) || brand.contains(query);
      }).toList();
    }

    return result;
  }
  void _addNewProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductManagementScreenWithCloudinary(
          onProductSaved: (product) {
            _loadProducts(); // Reload products from API
          },
        ),
      ),
    );
  }

  void _editProduct(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductManagementScreenWithCloudinary(
          product: product,
          onProductSaved: (updatedProduct) {
            _loadProducts(); // Reload products from API
          },
        ),
      ),
    );
  }

  void _deleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _productsApiService.deleteProduct(product.productId!);
                _loadProducts(); // Reload products from API
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully'),
                      backgroundColor: successColor,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting product: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Product Management",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 5. Added Search Bar UI
          Container(
            padding: const EdgeInsets.fromLTRB(defaultPadding, defaultPadding, defaultPadding, 0),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {}); // This forces the screen to redraw every time you type a letter
              },
              decoration: InputDecoration(
                hintText: "Search by name or brand...",
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  },
                )
                    : null,
              ),
            ),
          ),

          // Filter Section
          Container(
            padding: const EdgeInsets.all(defaultPadding),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Filter Products",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "${filteredProducts.length} found",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
                    _searchController.text.isNotEmpty
                        ? "No products match your search"
                        : "No products found",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  if (_searchController.text.isEmpty) ...[
                    Text(
                      "Add some products to get started",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                    const SizedBox(height: defaultPadding),
                    ElevatedButton.icon(
                      onPressed: _addNewProduct,
                      icon: const Icon(Icons.add),
                      label: const Text("Add Product"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
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
                  child: ProductManagementCard(
                    product: product,
                    onEdit: () => _editProduct(product),
                    onDelete: () => _deleteProduct(product),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewProduct,
        backgroundColor: primaryColor,
        label: const Text(
          "Add Product",
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}

class ProductManagementCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductManagementCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getStockStatusColor() {
    if (product.isOutOfStock || product.stockQuantity <= 0) {
      return errorColor;
    } else if (product.stockQuantity <= 5) {
      return warningColor;
    } else {
      return successColor;
    }
  }

  String _getStockStatusText() {
    if (product.isOutOfStock || product.stockQuantity <= 0) {
      return "OUT OF STOCK";
    } else if (product.stockQuantity <= 5) {
      return "LOW STOCK";
    } else {
      return "IN STOCK";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            Row(
              children: [
                // Product Images Carousel
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.withOpacity(0.1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: product.images.isNotEmpty
                        ? PageView.builder(
                      itemCount: product.images.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          product.images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.withOpacity(0.2),
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            );
                          },
                        );
                      },
                    )
                        : Container(
                      color: Colors.grey.withOpacity(0.2),
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),

                const SizedBox(width: defaultPadding),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Title
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Brand Name
                      Text(
                        product.brandName ?? "Rituals",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Images count badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_library,
                              size: 12,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${product.images.length} image${product.images.length != 1 ? 's' : ''}",
                              style: const TextStyle(
                                color: primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Stock Information
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Stock Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStockStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _getStockStatusColor().withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _getStockStatusText(),
                        style: TextStyle(
                          color: _getStockStatusColor(),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Stock Quantity
                    Text(
                      "Stock: ${product.stockQuantity}",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _getStockStatusColor(),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Price
                    Text(
                      "₹${product.price.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: defaultPadding),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: const BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: errorColor,
                      side: const BorderSide(color: errorColor),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}