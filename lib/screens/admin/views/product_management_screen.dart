import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/models/user_session.dart';
import 'package:shop/models/simple_token_manager.dart';
import 'package:shop/services/api_service.dart';
// import 'package:shop/services/cloudinary_service.dart'; // Temporarily commented
// import 'package:shop/services/cloudinary_config.dart'; // Temporarily commented
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

class ProductManagementScreen extends StatefulWidget {
  final ProductModel? product; // null for new product, existing product for edit
  final Function(ProductModel)? onProductSaved;

  const ProductManagementScreen({
    super.key,
    this.product,
    this.onProductSaved,
  });

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _maxOrderController = TextEditingController();
  final _imageUrlController = TextEditingController(); // New field for manual image URL entry
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController(); // For search keywords
  final _categoryController = TextEditingController(); // To replace hardcoded category
  List<String> _selectedImages = [];
  List<File> _newImageFiles = [];
  // List<CloudinaryResponse> _uploadedImages = []; // Track Cloudinary uploads - temporarily commented
  List<Map<String, dynamic>> _uploadedImages = []; // Track Cloudinary uploads - using Map for now
  bool _isOutOfStock = false;
  bool _isLoading = false;
  bool _isUploadingImages = false; // Track image upload progress
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _loadProductData();
    }
  }

  void _loadProductData() {
    final product = widget.product!;
    
    // Debug logging to check product data
    print('🔍 Loading product data:');
    print('   Product ID: ${product.productId}');
    print('   Title: ${product.title}');
    print('   Brand: ${product.brandName}');
    print('   Price: ${product.price}');
    print('   Discount Price: ${product.priceAfetDiscount}');
    print('   Stock: ${product.stockQuantity}');
    print('   Max Order: ${product.maxOrderQuantity}');
    print('   Images: ${product.images}');
    print('   Out of Stock: ${product.isOutOfStock}');
    
    _titleController.text = product.title;
    _brandController.text = product.brandName ?? "Ritual";
    _priceController.text = product.price.toString();
    _discountPriceController.text = product.priceAfetDiscount?.toString() ?? '';
    _stockController.text = product.stockQuantity.toString();
    _maxOrderController.text = product.maxOrderQuantity.toString();
    _selectedImages = List.from(product.images);
    _isOutOfStock = product.isOutOfStock;
    
    print('✅ Form fields populated:');
    print('   Title field: ${_titleController.text}');
    print('   Brand field: ${_brandController.text}');
    print('   Price field: ${_priceController.text}');
    print('   Discount field: ${_discountPriceController.text}');
    print('   Stock field: ${_stockController.text}');
    print('   Max Order field: ${_maxOrderController.text}');
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1000,
        maxHeight: 1000,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          for (var image in images) {
            _newImageFiles.add(File(image.path));
            _selectedImages.add(image.path); // For display purposes
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<void> _pickSingleImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1000,
        maxHeight: 1000,
      );
      
      if (image != null) {
        setState(() {
          _newImageFiles.add(File(image.path));
          _selectedImages.add(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _selectedImages.length) {
        String imagePath = _selectedImages[index];
        _selectedImages.removeAt(index);
        
        // Also remove from new files if it's a new file
        _newImageFiles.removeWhere((file) => file.path == imagePath);
      }
    });
  }

  void _addImageUrl() {
    if (_imageUrlController.text.trim().isNotEmpty) {
      setState(() {
        _selectedImages.add(_imageUrlController.text.trim());
        _imageUrlController.clear();
      });
    }
  }

  Future<void> _uploadImagesToCloudinary() async {
    if (_newImageFiles.isEmpty) {
      print('📷 No new images to upload');
      return;
    }

    setState(() => _isUploadingImages = true);

    try {
      print('☁️ Image upload temporarily disabled for debugging...');
      
      // Temporarily convert local paths to placeholder URLs
      for (int i = 0; i < _newImageFiles.length; i++) {
        final file = _newImageFiles[i];
        final localPath = file.path;
        
        // Use placeholder URL for now
        final placeholderUrl = 'https://via.placeholder.com/400x400/CCCCCC/FFFFFF?text=Image+${i + 1}';
        
        setState(() {
          final index = _selectedImages.indexOf(localPath);
          if (index != -1) {
            _selectedImages[index] = placeholderUrl;
          } else {
            _selectedImages.add(placeholderUrl);
          }
        });

        print('✅ Image ${i + 1} converted to placeholder: $placeholderUrl');
      }

      // Clear the local files
      _newImageFiles.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Images converted to placeholders (Cloudinary temporarily disabled)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Error in upload simulation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingImages = false);
    }
  }

  // --- ADD THIS HELPER METHOD INSIDE YOUR STATE CLASS ---
  List<Map<String, String>> _formatImagesForBackend(List<String> imageUrls) {
    return imageUrls.where((url) => url.isNotEmpty).map((url) {
      String publicId = "unknown_id";

      // Attempt to extract public_id from Cloudinary URL
      // Example: .../upload/v1234/products/my_image.jpg -> public_id: products/my_image
      try {
        if (url.contains('cloudinary.com')) {
          final uri = Uri.parse(url);
          final segments = uri.pathSegments;
          // Find 'upload' segment and look after it
          int uploadIndex = segments.indexOf('upload');
          if (uploadIndex != -1 && uploadIndex + 2 < segments.length) {
            // Skip 'upload' and version 'v1234'
            List<String> idParts = segments.sublist(uploadIndex + 2);
            String filename = idParts.last;
            idParts.removeLast();

            // Remove file extension
            String id = filename.split('.').first;

            // Reconstruct path: folder/id
            publicId = [...idParts, id].join('/');
          }
        }
      } catch (e) {
        print('⚠️ Could not extract public_id: $e');
      }

      return {
        "public_id": publicId, // Backend needs this
        "url": url
      };
    }).toList();
  }

  // --- REPLACE YOUR _saveProduct METHOD WITH THIS ---
  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        print('🔐 Getting DIRECT token from login...');
        final directToken = SimpleTokenManager.getDirectToken();
        final isDirectAdmin = SimpleTokenManager.isDirectAdmin();

        if (directToken == null || !isDirectAdmin) {
          throw Exception('Direct admin authentication required. Please log in again.');
        }

        // Upload any new images first (if implementation exists)
        if (_newImageFiles.isNotEmpty) {
          await _uploadImagesToCloudinary();
        }

        // --- FIX: Format images as Objects, not Strings ---
        final formattedImages = _formatImagesForBackend(_selectedImages);

        Map<String, dynamic> productData = {
          'name': _titleController.text.trim(),
          'description': _titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : 'Product description',
          'brand': _brandController.text.trim().isNotEmpty
              ? _brandController.text.trim()
              : 'Default Brand',
          'category': 'Electronics',
          'price': double.tryParse(_priceController.text) ?? 0.0,
          'stock': int.tryParse(_stockController.text) ?? 0,
          'maxOrderQuantity': int.tryParse(_maxOrderController.text) ?? 10,
          'images': formattedImages, // <--- SENDING OBJECTS NOW
          'isOutOfStock': _isOutOfStock,
          'isOnSale': false,
          'isPopular': false,
          'isBestSeller': false,
          'isFlashSale': false,
        };

        // ... (rest of your validation logic matches original) ...

        // Add discount logic
        if (_discountPriceController.text.isNotEmpty) {
          double discountPrice = double.tryParse(_discountPriceController.text) ?? 0.0;
          double originalPrice = double.tryParse(_priceController.text) ?? 0.0;
          productData['salePrice'] = discountPrice;
          if (discountPrice < originalPrice && originalPrice > 0) {
            productData['discount'] = ((originalPrice - discountPrice) / originalPrice * 100).round();
          }
        }

        print('📦 Sending Product Data: ${jsonEncode(productData)}');

        Map<String, dynamic> result;
        if (widget.product == null) {
          // CREATE
          result = await _createProductExactPostman(productData, directToken);
        } else {
          // UPDATE
          // For update, we use the same direct API call structure but with PUT
          final dio = Dio();
          final productId = widget.product!.productId;

          print('🔄 Updating product: $productId');

          final response = await dio.put(
            'https://mern-backend-t3h8.onrender.com/api/v1/admin/product/$productId',
            data: productData,
            options: Options(
              headers: {
                'Authorization': 'Bearer $directToken',
                'Content-Type': 'application/json',
              },
              validateStatus: (status) => true,
            ),
          );

          if (response.statusCode == 200) {
            result = {'success': true, 'data': response.data};
          } else {
            result = {'success': false, 'message': 'Update failed: ${response.statusCode} - ${response.data}'};
          }
        }

        if (!result['success']) {
          throw Exception(result['message'] ?? 'Failed to save product');
        }

        print('✅ Product saved successfully!');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product saved successfully!'),
              backgroundColor: successColor,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        print('❌ Error saving product: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
  // Refresh token and retry product creation
  Future<Map<String, dynamic>> _refreshTokenAndRetry(Map<String, dynamic> productData) async {
    try {
      print('🔄 Attempting to refresh authentication token...');
      
      // Get current user credentials from session
      final userSession = await UserSession.getUserSession();
      final currentEmail = UserSession.userEmail;
      
      if (currentEmail.isEmpty) {
        throw Exception('No user email found for token refresh');
      }
      
      print('🔄 Re-authenticating user: $currentEmail');
      
      // Make a fresh login call to get a new token
      final dio = Dio();
      final loginResponse = await dio.post(
        'https://mern-backend-t3h8.onrender.com/api/v1/login',
        data: {
          'email': currentEmail,
          'password': 'admin1234', // You might need to store this securely
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      
      if (loginResponse.statusCode == 200 && loginResponse.data['success']) {
        final newToken = loginResponse.data['token'];
        print('🔄 Got fresh token: ${newToken.substring(0, 30)}...');
        
        // Save the new token
        await UserSession.setAuthToken(newToken);
        final apiService = ApiService();
        await apiService.setAuthToken(newToken);
        
        // Retry product creation with new token
        return await _createProductExactPostman(productData, newToken);
      } else {
        throw Exception('Failed to refresh token: ${loginResponse.data}');
      }
    } catch (e) {
      print('❌ Token refresh failed: $e');
      return {
        'success': false,
        'message': 'Token refresh failed: $e'
      };
    }
  }

  // Test token validity before making the actual API call
  Future<void> _testTokenValidity(String token) async {
    try {
      final dio = Dio();
      
      // Test with a simple GET request to user profile or admin endpoint
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=utf-8',
      };
      
      print('🧪 Testing token with /admin/dashboard endpoint...');
      
      final response = await dio.get(
        'https://mern-backend-t3h8.onrender.com/api/v1/admin/dashboard',
        options: Options(
          headers: headers,
          validateStatus: (status) => true, // Allow all status codes
        ),
      );
      
      print('🧪 Token test result: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('✅ Token is valid and working!');
      } else if (response.statusCode == 401) {
        print('❌ Token is invalid or expired!');
        print('❌ Response: ${response.data}');
      } else {
        print('⚠️ Unexpected response: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('🧪 Token test failed: $e');
    }
  }

  // ULTRA-SIMPLE: Create product exactly like Postman
  Future<Map<String, dynamic>> _createProductExactPostman(Map<String, dynamic> productData, String token) async {
    try {
      final dio = Dio();
      
      print('🎯 EXACT POSTMAN REQUEST COMPARISON:');
      print('URL: https://mern-backend-t3h8.onrender.com/api/v1/admin/product');
      print('WORKING POSTMAN TOKEN: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4YmIyNmJlNjhlMzhhZTY3ZWY3ZWQwYyIsInJvbGUiOiJhZG1pbiIsImlhdCI6MTc1NzE0NDk5MSwiZXhwIjoxNzU3NDA0MTkxfQ.vJCFVxSABlddjrCEuposcoANGjhFMW6_E5cON7r-1X4');
      print('OUR CURRENT TOKEN: $token');
      print('TOKEN MATCHES POSTMAN: ${token.startsWith('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9')}');
      print('Body: ${jsonEncode(productData)}');
      
      // Try with EXACT working Postman token first
      print('🧪 TESTING WITH KNOWN WORKING POSTMAN TOKEN...');
      final workingToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4YmIyNmJlNjhlMzhhZTY3ZWY3ZWQwYyIsInJvbGUiOiJhZG1pbiIsImlhdCI6MTc1NzE0NDk5MSwiZXhwIjoxNzU3NDA0MTkxfQ.vJCFVxSABlddjrCEuposcoANGjhFMW6_E5cON7r-1X4';
      
      // TEST 1: Exact Postman headers
      print('🔬 TEST 1: Exact Postman headers...');
      var response = await dio.post(
        'https://mern-backend-t3h8.onrender.com/api/v1/admin/product',
        data: productData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $workingToken',
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': '*/*',
            'User-Agent': 'PostmanRuntime/7.45.0',
            'Connection': 'keep-alive',
          },
          validateStatus: (status) => true,
        ),
      );
      print('📡 TEST 1 Result: ${response.statusCode} - ${response.data}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ SUCCESS WITH TEST 1!');
        return {'success': true, 'data': response.data};
      }
      
      // TEST 2: Try with x-access-token instead of Authorization
      print('🔬 TEST 2: Using x-access-token header...');
      response = await dio.post(
        'https://mern-backend-t3h8.onrender.com/api/v1/admin/product',
        data: productData,
        options: Options(
          headers: {
            'x-access-token': workingToken,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => true,
        ),
      );
      print('📡 TEST 2 Result: ${response.statusCode} - ${response.data}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ SUCCESS WITH TEST 2!');
        return {'success': true, 'data': response.data};
      }
      
      // TEST 3: Try with token in body
      print('🔬 TEST 3: Token in request body...');
      var bodyWithToken = Map<String, dynamic>.from(productData);
      bodyWithToken['token'] = workingToken;
      
      response = await dio.post(
        'https://mern-backend-t3h8.onrender.com/api/v1/admin/product',
        data: bodyWithToken,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => true,
        ),
      );
      print('📡 TEST 3 Result: ${response.statusCode} - ${response.data}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ SUCCESS WITH TEST 3!');
        return {'success': true, 'data': response.data};
      }
      
      // TEST 4: Try without charset in Content-Type
      print('🔬 TEST 4: Simple Content-Type...');
      response = await dio.post(
        'https://mern-backend-t3h8.onrender.com/api/v1/admin/product',
        data: productData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $workingToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => true,
        ),
      );

      // FINAL TEST: Check backend middleware/CORS
      print('� FINAL TEST: Checking backend middleware...');
      
      // Test with raw HTTP request to see what backend expects
      response = await dio.post(
        'https://mern-backend-t3h8.onrender.com/api/v1/admin/product',
        data: productData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $workingToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Origin': 'https://mern-backend-t3h8.onrender.com',
            'Referer': 'https://mern-backend-t3h8.onrender.com',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
          validateStatus: (status) => true,
          followRedirects: false,
        ),
      );
      print('📡 BACKEND CHECK Result: ${response.statusCode} - ${response.data}');
      print('📋 Response Headers: ${response.headers.map}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ SUCCESS WITH BACKEND CHECK!');
        return {'success': true, 'data': response.data};
      }
      
      // If all else fails, let's check if login endpoint works with same method
      print('🔬 TESTING LOGIN ENDPOINT for comparison...');
      final loginResponse = await dio.post(
        'https://mern-backend-t3h8.onrender.com/api/v1/login',
        data: {
          'email': 'rishiarora2705@gmail.com',
          'password': 'Rishi599@'
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => true,
        ),
      );
      print('📡 LOGIN TEST Result: ${loginResponse.statusCode} - Success: ${loginResponse.data['success'] ?? false}');
      
      if (loginResponse.statusCode == 200 && loginResponse.data['success'] == true) {
        final freshToken = loginResponse.data['token'];
        print('🔑 Got fresh token, testing product creation...');
        
        final freshResponse = await dio.post(
          'https://mern-backend-t3h8.onrender.com/api/v1/admin/product',
          data: productData,
          options: Options(
            headers: {
              'Authorization': 'Bearer $freshToken',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            validateStatus: (status) => true,
          ),
        );
        print('📡 FRESH TOKEN Result: ${freshResponse.statusCode} - ${freshResponse.data}');
        
        if (freshResponse.statusCode == 201 || freshResponse.statusCode == 200) {
          return {'success': true, 'data': freshResponse.data};
        }
      }
      
      // If Postman token failed ALL tests, try with our current token using the same tests
      print('🔄 All Postman token tests failed, trying our current token with TEST 4 format...');
      
      response = await dio.post(
        'https://mern-backend-t3h8.onrender.com/api/v1/admin/product',
        data: productData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => true,
        ),
      );

      print('📡 OUR TOKEN Result: ${response.statusCode} - ${response.data}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': 'ALL TESTS FAILED: ${response.statusCode}: ${response.data}'};
      }
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? "Add New Product" : "Edit Product",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _saveProduct,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images Section
              _buildImageSection(),
              
              const SizedBox(height: defaultPadding * 2),
              
              // Product Information
              _buildProductInfoSection(),
              
              const SizedBox(height: defaultPadding * 2),
              
              // Pricing Section
              _buildPricingSection(),
              
              const SizedBox(height: defaultPadding * 2),
              
              // Inventory Section
              _buildInventorySection(),
              
              const SizedBox(height: defaultPadding * 3),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.product == null ? 'Create Product' : 'Update Product',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              "Product Images",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: defaultPadding),
        
        // Image Grid
        if (_selectedImages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _selectedImages[index].startsWith('http')
                          ? Image.network(
                              _selectedImages[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            )
                          : Image.file(
                              File(_selectedImages[index]),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                    ),
                    // Remove button
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: errorColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ),
                  // Main image indicator
                  if (index == 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Main',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        
        const SizedBox(height: defaultPadding),
        
        // Add Images Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickSingleImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Single Image'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Add Multiple'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: primaryColor),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: defaultPadding / 2),
        
        // Upload to Cloudinary Button
        if (_newImageFiles.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploadingImages ? null : _uploadImagesToCloudinary,
              icon: _isUploadingImages 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(
                _isUploadingImages 
                    ? 'Uploading to Cloudinary...' 
                    : 'Upload ${_newImageFiles.length} images to Cloudinary',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: successColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        
        const SizedBox(height: defaultPadding),
        
        // Manual Image URL Input
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Or add image URL',
                  hintText: 'https://example.com/image.jpg',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty && !Uri.tryParse(value)!.isAbsolute) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _addImageUrl,
              icon: const Icon(Icons.add),
              label: const Text('Add URL'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              "Product Information",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: defaultPadding),
        
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Product Title',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.title),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter product title';
            }
            return null;
          },
        ),
        
        const SizedBox(height: defaultPadding),
        
        TextFormField(
          controller: _brandController,
          decoration: const InputDecoration(
            labelText: 'Brand Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter brand name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.currency_rupee, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              "Pricing",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: defaultPadding),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Original Price (₹)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter valid price';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: defaultPadding),
            Expanded(
              child: TextFormField(
                controller: _discountPriceController,
                decoration: const InputDecoration(
                  labelText: 'Discount Price (₹)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_offer),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    double? discountPrice = double.tryParse(value);
                    double? originalPrice = double.tryParse(_priceController.text);
                    if (discountPrice == null) {
                      return 'Please enter valid price';
                    }
                    if (originalPrice != null && discountPrice >= originalPrice) {
                      return 'Discount price must be less than original price';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInventorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              "Inventory",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: defaultPadding),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter stock quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter valid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: defaultPadding),
            Expanded(
              child: TextFormField(
                controller: _maxOrderController,
                decoration: const InputDecoration(
                  labelText: 'Max Order Quantity',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_cart),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter max order quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter valid number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: defaultPadding),
        
        SwitchListTile(
          title: const Text('Out of Stock'),
          subtitle: const Text('Mark this product as out of stock'),
          value: _isOutOfStock,
          onChanged: (value) {
            setState(() {
              _isOutOfStock = value;
            });
          },
          activeColor: primaryColor,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _stockController.dispose();
    _maxOrderController.dispose();
    super.dispose();
  }
}
  