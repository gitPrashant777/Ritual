import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart'; // <-- 1. ADD IMPORT
import 'package:shop/components/cart_button.dart';
import 'package:shop/components/custom_modal_bottom_sheet.dart';
import 'package:shop/components/network_image_with_loader.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/screens/product/views/added_to_cart_message_screen.dart';
import 'package:shop/screens/product/views/components/product_list_tile.dart';
import 'package:shop/screens/product/views/location_permission_store_availability_screen.dart';
import 'package:shop/services/cart_service.dart';
import 'package:shop/services/cart_wishlist_api_service.dart'; // <-- 2. ADD IMPORT
import 'components/product_quantity.dart';
import 'components/selected_colors.dart';
import 'components/selected_size.dart';
import 'components/unit_price.dart';

class ProductBuyNowScreen extends StatefulWidget {
  const ProductBuyNowScreen({super.key, required this.product});

  final ProductModel product;

  @override
  _ProductBuyNowScreenState createState() => _ProductBuyNowScreenState();
}

class _ProductBuyNowScreenState extends State<ProductBuyNowScreen> {
  int quantity = 1;
  int selectedColorIndex = 2;
  int selectedSizeIndex = 1;
  final List<String> sizes = ["S", "M", "L", "XL", "XXL"];
  final List<Color> colors = [
    const Color(0xFFEA6262),
    const Color(0xFFB1CC63),
    const Color(0xFFFFBF5F),
    const Color(0xFF9FE1DD),
    const Color(0xFFC482DB),
  ];

  late ProductModel currentProduct;

  @override
  void initState() {
    super.initState();
    currentProduct = widget.product;
  }

  double get totalPrice => (currentProduct.priceAfetDiscount ?? currentProduct.price) * quantity;

  @override
  Widget build(BuildContext context) {
    // --- 3. GET SERVICES FROM PROVIDER ---
    final cartService = context.watch<CartService>();
    final bool isLoading = cartService.isLoading;

    return Scaffold(
      bottomNavigationBar: CartButton(
        price: totalPrice,
        title: "Add to cart",
        subTitle: "Total price",

        // --- 4. FIX THE PRESS CALLBACK ---
        // It's no longer async, and it uses the 'cartService' instance
        press: isLoading ? null : () {
          // Call the async method from the service
          cartService.addToCart(
            currentProduct,
            quantity: quantity, // Pass the selected quantity
            size: sizes[selectedSizeIndex], // Pass selected size
            color: colors[selectedColorIndex].value.toString(), // Pass selected color
          ).then((_) {
            // This part runs *after* the async call finishes
            if (mounted) {
              customModalBottomSheet(
                context,
                isDismissible: false,
                child: const AddedToCartMessageScreen(),
              );
            }
          });
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding / 2, vertical: defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BackButton(),
                Text(
                  currentProduct.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                // --- 5. PASS PRODUCT ID TO WISHLIST BUTTON ---
                _WishlistIconButton(
                  productId: currentProduct.productId ?? '',
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                    child: AspectRatio(
                      aspectRatio: 1.05,
                      // --- 6. FIX IMAGE - Use product's actual image ---
                      child: NetworkImageWithLoader(
                        currentProduct.image.isNotEmpty
                            ? currentProduct.image
                            : productDemoImg1, // Fallback
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(defaultPadding),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              UnitPrice(
                                price: currentProduct.price,
                                priceAfterDiscount: currentProduct.priceAfetDiscount,
                              ),
                              const SizedBox(height: defaultPadding / 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: defaultPadding / 2,
                                  vertical: defaultPadding / 4,
                                ),
                                decoration: BoxDecoration(
                                  color: currentProduct.stockQuantity > 10
                                      ? Colors.green.withOpacity(0.1)
                                      : currentProduct.stockQuantity > 0
                                      ? Colors.orange.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: currentProduct.stockQuantity > 10
                                        ? Colors.green
                                        : currentProduct.stockQuantity > 0
                                        ? Colors.orange
                                        : Colors.red,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  currentProduct.stockQuantity > 0
                                      ? "Available: ${currentProduct.stockQuantity} units"
                                      : "Out of Stock",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: currentProduct.stockQuantity > 10
                                        ? Colors.green
                                        : currentProduct.stockQuantity > 0
                                        ? Colors.orange
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ProductQuantity(
                          numOfItem: quantity,
                          onIncrement: () {
                            setState(() {
                              if (quantity < currentProduct.stockQuantity &&
                                  quantity < currentProduct.maxOrderQuantity) {
                                quantity++;
                              }
                            });
                          },
                          onDecrement: () {
                            if (quantity > 1) {
                              setState(() {
                                quantity--;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: Divider()),
                SliverToBoxAdapter(
                  child: SelectedColors(
                    colors: colors,
                    selectedColorIndex: selectedColorIndex,
                    press: (value) {
                      setState(() {
                        selectedColorIndex = value;
                      });
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: SelectedSize(
                    sizes: sizes,
                    selectedIndex: selectedSizeIndex,
                    press: (value) {
                      setState(() {
                        selectedSizeIndex = value;
                      });
                    },
                  ),
                ),

                SliverPadding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: defaultPadding),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: defaultPadding / 2),
                        Text(
                          "Store pickup availability",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        const Text(
                            "Select a size to check store availability and In-Store pickup options.")
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: defaultPadding),
                  sliver: ProductListTile(
                    title: "Check stores",
                    svgSrc: "assets/icons/Stores.svg",
                    isShowBottomBorder: true,
                    press: () {
                      customModalBottomSheet(
                        context,
                        height: MediaQuery.of(context).size.height * 0.92,
                        child: const LocationPermissonStoreAvailabilityScreen(),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: defaultPadding))
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- 7. REBUILT THE WISHLIST BUTTON ---
class _WishlistIconButton extends StatefulWidget {
  final String productId;
  // It now requires a productId
  const _WishlistIconButton({required this.productId});

  @override
  _WishlistIconButtonState createState() => _WishlistIconButtonState();
}

class _WishlistIconButtonState extends State<_WishlistIconButton> {
  bool _isInWishlist = false;
  bool _isLoading = false;
  // Service will be fetched from Provider
  late WishlistApiService _wishlistApi;

  @override
  void initState() {
    super.initState();
    // Get service from Provider
    _wishlistApi = Provider.of<WishlistApiService>(context, listen: false);
    _checkWishlist();
  }

  Future<void> _checkWishlist() async {
    if (widget.productId.isEmpty) return; // Don't check if no ID
    setState(() => _isLoading = true);
    final isWish = await _wishlistApi.isInWishlist(widget.productId);
    if (mounted) {
      setState(() {
        _isInWishlist = isWish;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleWishlist() async {
    if (widget.productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot wishlist this item'), backgroundColor: errorColor),
      );
      return;
    }

    setState(() => _isLoading = true);
    if (_isInWishlist) {
      await _wishlistApi.removeFromWishlist(widget.productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from wishlist'), backgroundColor: errorColor),
        );
      }
    } else {
      await _wishlistApi.addToWishlist(widget.productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to wishlist'), backgroundColor: pinkColor),
        );
      }
    }
    // Re-check state from the server to be 100% sure
    await _checkWishlist();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isLoading ? null : _toggleWishlist,
      icon: _isLoading
      // Show a loading spinner while checking/updating
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(
        _isInWishlist ? Icons.favorite : Icons.favorite_border,
        color: _isInWishlist
            ? Colors.red
            : Theme.of(context).textTheme.bodyLarge!.color,
      ),
    );
  }
}