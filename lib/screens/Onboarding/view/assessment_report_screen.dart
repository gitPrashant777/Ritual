// assessment_report_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart'; // For 'firstWhereOrNull'
import 'package:shop/constants.dart';

// Import your app's models and services
import '../../../models/assessment_report.dart';
import '../../../services/firebase_kit_service.dart';
import '../../../services/products_api_service.dart';
import '../../../models/product_model.dart';
import '../../../route/screen_export.dart'; // For navigation
// ... existing imports ...
import 'package:shop/services/cart_service.dart'; // Import CartService
class AssessmentReportScreen extends StatefulWidget {
  final String userName;
  final String userAge;
  final String selectedGender;
  final AssessmentReport assessmentReport;

  const AssessmentReportScreen({
    super.key,
    required this.userName,
    required this.userAge,
    required this.selectedGender,
    required this.assessmentReport,
  });

  @override
  State<AssessmentReportScreen> createState() => _AssessmentReportScreenState();
}

class _AssessmentReportScreenState extends State<AssessmentReportScreen> {
  final ScrollController _scrollController = ScrollController();
  int _selectedCauseIndex = 0;
  int _selectedSkinCauseIndex = 0;

  // Services
  late ProductsApiService _productsApiService;
  late FirebaseKitService _firebaseKitService;

  // Futures
  late Future<List<ProductModel>> _productsFuture;

  // State
  List<ProductModel> _allProducts = [];
  Map<String, int> _selectedProductQuantities = {};
  double _totalPrice = 0.0;
  double _mrpPrice = 0.0;
  bool _isSaving = false;

  // Colors
  static const brandSecondary = Color(0xff267a0b);
  static const brandAccent = Color(0xff2a8107);
  static const brandPrimary = Color(0xFF0b3323);

  // URL
  final String _imageBaseUrl = "https://mern-backend-t3h8.onrender.com/api/v1";

  @override
  void initState() {
    super.initState();
    _productsApiService = Provider.of<ProductsApiService>(context, listen: false);
    _firebaseKitService = Provider.of<FirebaseKitService>(context, listen: false);

    _productsFuture = _productsApiService.getAllProducts();

    // Only load products if the report was actually successful
    if (widget.assessmentReport.isSuccess) {
      _loadAndInitialize();
    }
  }

  // --- LOGIC METHODS ---
  // --- NEW HELPER METHOD ---
  Future<void> _addSelectedItemsToCart() async {
    final cartService = Provider.of<CartService>(context, listen: false);

    // Show a small loading indicator or snackbar if desired
    // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Adding items to cart...")));

    for (var entry in _selectedProductQuantities.entries) {
      final productId = entry.key;
      final quantity = entry.value;

      if (quantity > 0) {
        // Find the full product object from the loaded list
        final product = _allProducts.firstWhereOrNull((p) => p.productId == productId);

        if (product != null) {
          // Add to cart using the service
          await cartService.addToCart(product, quantity: quantity);
        }
      }
    }
  }

  Future<void> _loadAndInitialize() async {
    final allApiProducts = await _productsFuture;

    final allProductsMap = <String, ProductModel>{};
    for (var p in allApiProducts) {
      if (p.productId != null) {
        allProductsMap[p.productId!] = p;
      }
    }

    if (!mounted) return;
    setState(() {
      _allProducts = allProductsMap.values.toList();
    });

    _calculateTotalPrice();
  }

  int _getSuggestedQuantity(ProductModel product) {
    return 2;
  }

  void _updateProductQuantity(ProductModel product, int newQuantity) {
    if (product.productId == null) return;
    setState(() {
      int minQty = 0;
      int maxQty = product.maxOrderQuantity;
      int clampedQty = newQuantity.clamp(minQty, maxQty);

      if (clampedQty == 0) {
        _selectedProductQuantities.remove(product.productId!);
      } else {
        _selectedProductQuantities[product.productId!] = clampedQty;
      }
      _calculateTotalPrice();
    });
  }

  void _calculateTotalPrice() {
    double total = 0.0;
    double mrp = 0.0;

    for (var entry in _selectedProductQuantities.entries) {
      final productId = entry.key;
      final quantity = entry.value;

      final product = _allProducts.firstWhereOrNull(
            (p) => p.productId == productId,
      );

      if (product != null) {
        total += (product.priceAfetDiscount ?? product.price) * quantity;
        mrp += product.price * quantity;
      }
    }
    setState(() {
      _totalPrice = total;
      _mrpPrice = mrp;
    });
  }

  Future<void> _saveKitForLater() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final List<ProductModel> productsToSave = [];
      for (var entry in _selectedProductQuantities.entries) {
        final product =
        _allProducts.firstWhereOrNull((p) => p.productId == entry.key);
        if (product != null) {
          productsToSave.add(product);
        }
      }

      if (productsToSave.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Your kit is empty."),
              backgroundColor: Colors.orange),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }

      String kitName = "Custom Kit";
      String diagnosis = "${widget.assessmentReport.hairDiagnosis}. ${widget.assessmentReport.skinDiagnosis}";

      await _firebaseKitService.saveKit(
        kitProducts: productsToSave,
        kitName: kitName,
        diagnosis: diagnosis.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Kit saved successfully!"),
            backgroundColor: brandPrimary),
      );

      Navigator.pushNamedAndRemoveUntil(
          context, entryPointScreenRoute, (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error saving kit: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _buildProductImageUrl(ProductModel product) {
    String imageUrl = product.image;
    if (imageUrl.isEmpty && product.images.isNotEmpty) {
      imageUrl = product.images.first;
    } else if (imageUrl.isEmpty) {
      return '';
    }
    if (imageUrl.startsWith('http')) return imageUrl;
    if (imageUrl.startsWith('/')) return '$_imageBaseUrl$imageUrl';
    return '$_imageBaseUrl/$imageUrl';
  }

  // --- NEW: DYNAMIC TEXT HELPER ---
  String _getRegrowthDescription(int percentage) {
    if (percentage >= 85) {
      return "Stage 1: Excellent Potential. Your hair follicles are highly active. Minimal intervention is required to maintain density and health.";
    } else if (percentage >= 70) {
      return "Stage 2: High Potential. Male pattern hair fall is in early stages. Hormonal factors are affecting follicles, but most are still active and recoverable.";
    } else if (percentage >= 50) {
      return "Stage 3: Moderate Potential. Visible thinning detected. Some follicles are shrinking due to hormonal effects. Immediate action is recommended to stop further loss.";
    } else if (percentage >= 30) {
      return "Stage 4: Lower Potential. Advanced thinning detected. Follicles are significantly miniaturized. Intensive treatment is needed to support existing hair.";
    } else {
      return "Stage 5: Low Potential. Significant hair loss detected. Focus should be on maintenance and scalp health to prevent further recession.";
    }
  }

  // --- MAIN BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    // ---------------------------------------------------------
    // 1. CHECK IF ANALYSIS FAILED (Invalid Images)
    // ---------------------------------------------------------
    if (widget.assessmentReport.isSuccess == false) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            "Analysis Failed",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.broken_image_outlined,
                      size: 60, color: Colors.red),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Could Not Analyze Images",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.assessmentReport.failureReason.isNotEmpty
                      ? widget.assessmentReport.failureReason
                      : "We could not detect clear skin or scalp details. Please retake the photos ensuring good lighting and focus.",
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D2D),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Try Again",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ---------------------------------------------------------
    // 2. SHOW REPORT IF SUCCESSFUL
    // ---------------------------------------------------------
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed(entryPointScreenRoute),
        ),
        title: const Text(
          "Assessment Report",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDiagnosisSection(),
              const SizedBox(height: 24),
              _buildRootCausesSection(),
              const SizedBox(height: 24),
              _buildHairKitSection(),
              const SizedBox(height: 24),
              _buildSkinRootCausesSection(),
              const SizedBox(height: 24),
              _buildSkinKitSection(),
              const SizedBox(height: 24),
              _buildRecommendedProductsSection(),
              const SizedBox(height: 24),
              _buildAddOnsSection(),
              const SizedBox(height: 24),
              _buildResultsTimelineSection(),
              const SizedBox(height: 24),
              _buildBottomActions(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET 1: Diagnosis Section (Dynamic Text Added) ---
  Widget _buildDiagnosisSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${widget.userName}, ${widget.userAge}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "You've been diagnosed with:",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "• ${widget.assessmentReport.hairDiagnosis}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "• ${widget.assessmentReport.skinDiagnosis}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Start Seeing Results In ${widget.assessmentReport.hairTimeline}",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.selectedGender.toLowerCase() == 'female'
                      ? Icons.female
                      : Icons.male,
                  color: Colors.grey[600],
                  size: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: brandPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Hair Regrowth possibility ${widget.assessmentReport.regrowthPossibility}%",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // --- UPDATED DYNAMIC CONTAINER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              // Call the helper function here
              _getRegrowthDescription(widget.assessmentReport.regrowthPossibility),
              style: TextStyle(
                color: brandPrimary,
                height: 1.4,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET 2 (Unchanged) ---
  Widget _buildRootCausesSection() {
    final causes = widget.assessmentReport.hairRootCauses;
    if (causes.isEmpty) return Container();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Hair Loss Root Causes",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(causes.length, (index) {
              final cause = causes[index];
              final isSelected = _selectedCauseIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCauseIndex = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      left: index == 0 ? 0 : 4,
                      right: index == causes.length - 1 ? 0 : 4,
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange[50] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue[700]!
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          cause.icon,
                          color:
                          isSelected ? Colors.blue[800] : Colors.black87,
                          size: 28,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40.0,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              cause.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.blue[900]
                                    : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              causes[_selectedCauseIndex].description,
              style: TextStyle(
                color: Colors.orange[900],
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET 3: Hair Kit Section (Unchanged) ---
  Widget _buildHairKitSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your 1st Month Kit",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<ProductModel>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No products found."));
              }

              final hairProducts = snapshot.data!
                  .where((p) => p.title.toLowerCase().contains("hair"))
                  .take(4)
                  .toList();

              if (hairProducts.isEmpty) {
                return const Center(child: Text("No hair products found."));
              }

              return Column(
                children: hairProducts.map((product) {
                  final currentQty =
                      _selectedProductQuantities[product.productId] ?? 0;
                  final suggestedQty = _getSuggestedQuantity(product);

                  return _buildProductRowCard(
                    product,
                    currentQty,
                    suggestedQty,
                        () => _updateProductQuantity(product, currentQty + 1),
                        () => _updateProductQuantity(product, currentQty - 1),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- WIDGET 4 (Unchanged) ---
  Widget _buildSkinRootCausesSection() {
    final causes = widget.assessmentReport.skinRootCauses;
    if (causes.isEmpty) return Container();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Skin Root Causes",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(causes.length, (index) {
              final cause = causes[index];
              final isSelected = _selectedSkinCauseIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSkinCauseIndex = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      left: index == 0 ? 0 : 4,
                      right: index == causes.length - 1 ? 0 : 4,
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                        isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          cause.icon,
                          color: isSelected ? Colors.blue[800] : Colors.black87,
                          size: 28,
                        ),

                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40.0,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              cause.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                isSelected ? Colors.blue[900] : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              causes[_selectedSkinCauseIndex].description,
              style: TextStyle(
                color: Colors.blue[900],
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET 5: Skin Kit Section (Unchanged) ---
  Widget _buildSkinKitSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Skin Care Products",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<ProductModel>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No products found."));
              }

              final skinProducts = snapshot.data!
                  .where((p) {
                final t = p.title.toLowerCase();
                return t.contains("face") || t.contains("skin");
              })
                  .take(5)
                  .toList();

              if (skinProducts.isEmpty) {
                return const Center(child: Text("No skin products found."));
              }

              return Column(
                children: skinProducts.map((product) {
                  final currentQty =
                      _selectedProductQuantities[product.productId] ?? 0;
                  final suggestedQty = _getSuggestedQuantity(product);

                  return _buildProductRowCard(
                    product,
                    currentQty,
                    suggestedQty,
                        () => _updateProductQuantity(product, currentQty + 1),
                        () => _updateProductQuantity(product, currentQty - 1),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- WIDGET 6: Recommended Products (Unchanged) ---
  Widget _buildRecommendedProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recommended For You",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<ProductModel>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                  height: 220,
                  child: const Center(child: CircularProgressIndicator()

              ));
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text("Error fetching products: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No products found."));
            }

            final allProducts = snapshot.data!;

            final productsToShow = allProducts.where((p) {
              final t = p.title.toLowerCase();
              return t.contains('hair') || t.contains('face');
            }).take(5).toList();

            if (productsToShow.isEmpty) {
              return Container(
                height: 220,
                child: const Center(child: Text("No matching products found.")),
              );
            }

            return Container(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: productsToShow.length,
                itemBuilder: (context, index) {
                  final product = productsToShow[index];
                  final imageUrl = _buildProductImageUrl(product);

                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: Image.network(
                            imageUrl,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) {
                              return Container(
                                height: 120,
                                width: 160,
                                color: Colors.grey[200],
                                child: Icon(Icons.shopping_bag,
                                    color: Colors.grey[600]),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            product.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "₹${(product.priceAfetDiscount ?? product.price).toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // --- WIDGET 7 (Unchanged) ---
  Widget _buildAddOnsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 16),
          child: Text(
            "Your Personalised Plan",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
        ),
        ...widget.assessmentReport.freeAddOns.map(
              (addon) => _buildAddOnCard(addon),
        ),
      ],
    );
  }

  Widget _buildResultsTimelineSection() {
    // 1. Get dynamic data
    final timelineStages = _getDynamicTimelineData();

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Personalised Roadmap",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Based on your score of ${widget.assessmentReport.regrowthPossibility}%, here is what to expect:",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 32),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 25,
                    left: 0,
                    right: 0, // Extend line across full width
                    child: Container(
                      height: 2,
                      color: brandPrimary.withOpacity(0.3),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: timelineStages.map((stage) {
                      return Container(
                        width: 90, // Fixed width to prevent wrapping
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildTimelineNode(
                            stage.icon, stage.time, stage.description),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  // --- Bottom Actions Widget (Unchanged) ---
  Widget _buildBottomActions() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              const Text(
                "Your Custom Kit Price",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "₹${_totalPrice.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_mrpPrice > _totalPrice)
                    Text(
                      "₹${_mrpPrice.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF999999),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Inclusive of all taxes",
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : _saveKitForLater,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                      color: _isSaving
                          ? Colors.grey[300]!
                          : const Color(0xFF2D2D2D)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.grey),
                )
                    : const Text(
                  "Save Kit",
                  style: TextStyle(
                    color: Color(0xFF2D2D2D),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  int totalItemCount = _selectedProductQuantities.values.isEmpty
                      ? 0
                      : _selectedProductQuantities.values
                      .reduce((a, b) => a + b);

                  _showCheckoutDialog(
                    _totalPrice.toStringAsFixed(0),
                    _mrpPrice.toStringAsFixed(0),
                    totalItemCount,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D2D2D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Buy Now",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 60,)

      ],

    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildProductRowCard(
      ProductModel product,
      int quantity,
      int suggestedQty,
      VoidCallback onIncrement,
      VoidCallback onDecrement,
      ) {
    final imageUrl = _buildProductImageUrl(product);
    final finalPrice = (product.priceAfetDiscount ?? product.price);
    final bool isSelected = quantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? brandPrimary : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? brandPrimary.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover, errorBuilder: (c, e, s) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: Icon(Icons.shopping_bag_outlined,
                        color: Colors.grey[600]),
                  );
                }),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 4),
                if (product.category.isNotEmpty)
                  _buildTagChip(product.category),
                const SizedBox(height: 4),
                Text(
                  "Recommended: $suggestedQty units",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "₹${finalPrice.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              if (product.priceAfetDiscount != null &&
                  product.priceAfetDiscount! < product.price)
                Text(
                  "₹${product.price.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              const SizedBox(height: 8),

              if (quantity == 0)
                TextButton(
                  onPressed: onIncrement,
                  style: TextButton.styleFrom(
                    backgroundColor: brandPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size(88, 32),
                  ),
                  child: Text(
                    "ADD",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: IconButton(
                          onPressed: onDecrement,
                          icon: Icon(Icons.remove,
                              size: 14, color: Colors.green[900]),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      Text(
                        "$quantity",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.green[900],
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: IconButton(
                          onPressed: onIncrement,
                          icon: Icon(Icons.add,
                              size: 14, color: Colors.green[900]),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String category) {
    const hairCategories = ['hair', 'scalp'];
    bool isHair = hairCategories.any((cat) => category.toLowerCase().contains(cat));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isHair ? Colors.orange[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isHair ? Colors.orange[800] : Colors.blue[800],
        ),
      ),
    );
  }

  Widget _buildAddOnCard(RecommendedProduct addon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                addon.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[200],
                  child: Icon(
                    _getAddOnIcon(addon.name),
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    addon.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    addon.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${addon.price}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: brandPrimary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: brandPrimary!),
                  ),
                  child: Text(
                    addon.discountedPrice.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildTimelineNode(IconData icon, String month, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: brandPrimary,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: brandPrimary,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          month,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 120,
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
        ),
      ],
    );
  }
  List<_TimelineStage> _getDynamicTimelineData() {
    int score = widget.assessmentReport.regrowthPossibility;

    if (score >= 80) {
      // Scenario A: Mild Issues (Fast Recovery)
      return [
        _TimelineStage(Icons.cleaning_services, "Month 1", "Detox scalp & stop hairfall."),
        _TimelineStage(Icons.grass, "Month 2", "Visible baby hair growth."),
        _TimelineStage(Icons.waves, "Month 3", "Improved density & volume."),
        _TimelineStage(Icons.check_circle, "Month 6", "Full health maintenance."),
      ];
    } else if (score >= 50) {
      // Scenario B: Moderate Issues (Standard Plan)
      return [
        _TimelineStage(Icons.shield, "Month 1-2", "Stop active hairfall & strengthen roots."),
        _TimelineStage(Icons.trending_up, "Month 3-4", "Reactivate dormant follicles."),
        _TimelineStage(Icons.opacity, "Month 5-6", "Thickening of existing strands."),
        _TimelineStage(Icons.celebration, "Month 9", "Significant visible coverage."),
      ];
    } else {
      // Scenario C: Severe Issues (Slow, Intensive Plan)
      return [
        _TimelineStage(Icons.healing, "Month 1-3", "Stabilize loss & scalp inflammation."),
        _TimelineStage(Icons.spa, "Month 4-6", "Nourish miniaturized follicles."),
        _TimelineStage(Icons.local_florist, "Month 7-9", "First signs of new fuzz."),
        _TimelineStage(Icons.verified, "Year 1+", "Long-term density improvement."),
      ];
    }
  }
  IconData _getAddOnIcon(String addonName) {
    if (addonName.toLowerCase().contains('coach')) return Icons.support_agent;
    if (addonName.toLowerCase().contains('diet')) return Icons.restaurant_menu;
    if (addonName.toLowerCase().contains('doctor'))
      return Icons.medical_services;
    return Icons.card_giftcard;
  }

  void _showCheckoutDialog(String finalPrice, String mrpPrice, int itemCount) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Checkout",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Order summary",
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Text("$itemCount items",
                        style: const TextStyle(color: Color(0xFF666666))),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total MRP"),
                          Text("₹$mrpPrice"),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Delivery charges"),
                          Text("FREE",
                              style: TextStyle(color: Color(0xFF4CAF50))),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Amount to be paid",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("₹$finalPrice",
                              style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // 1. Add all selected items to the cart
                      await _addSelectedItemsToCart();

                      if (!mounted) return;

                      // 2. Close the dialog
                      Navigator.of(context).pop();

                      // 3. Navigate to the Cart Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D2D),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Add Address & Pay ₹$finalPrice",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
class _TimelineStage {
  final IconData icon;
  final String time;
  final String description;
  _TimelineStage(this.icon, this.time, this.description);
}