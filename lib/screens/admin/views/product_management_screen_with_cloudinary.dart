import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/models/simple_token_manager.dart';
import 'package:shop/services/cloudinary_service.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';

class ProductManagementScreenWithCloudinary extends StatefulWidget {
  final ProductModel? product; // null for new product, existing product for edit
  final Function(ProductModel)? onProductSaved;

  const ProductManagementScreenWithCloudinary({
    super.key,
    this.product,
    this.onProductSaved,
  });

  @override
  State<ProductManagementScreenWithCloudinary> createState() => _ProductManagementScreenWithCloudinaryState();
}

class _ProductManagementScreenWithCloudinaryState extends State<ProductManagementScreenWithCloudinary> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _maxOrderController = TextEditingController();

  List<String> _selectedImages = [];
  List<File> _newImageFiles = [];
  bool _isOutOfStock = false;
  bool _isLoading = false;

  // Category selection
  String _selectedCategory = 'Hair Care';
  final List<String> _categories = [
    'Face Care',
    'Hair Care',
    'Body Care',
    'Anti-Aging',
    'Acne Treatment',
    'Sun Protection',
    'Sensitive Skin',
    'Scalp Health',
    'Dermatology',
    'Other Treatments',
  ];

  // New product flags
  bool _isOnSale = false;
  bool _isPopular = false;
  bool _isBestSeller = false;
  bool _isFlashSale = false;
  DateTime? _flashSaleEnd;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _loadProductData();
    } else {
      // Set default values for new product
      _maxOrderController.text = '5';
      _stockController.text = '10';
    }
  }

  void _loadProductData() {
    final product = widget.product!;
    _titleController.text = product.title;
    _brandController.text = product.brandName ?? "Rituals";
    _descriptionController.text = product.description ?? '';
    _selectedCategory = product.category ?? 'Electronics';
    _priceController.text = product.price.toString();
    _discountPriceController.text = product.priceAfetDiscount?.toString() ?? '';
    _stockController.text = product.stockQuantity.toString();
    _maxOrderController.text = product.maxOrderQuantity.toString();
    _selectedImages = List.from(product.images);
    _isOutOfStock = product.isOutOfStock;

    // Load new fields if they exist in the product model
    _isOnSale = product.isOnSale ?? false;
    _isPopular = product.isPopular ?? false;
    _isBestSeller = product.isBestSeller ?? false;
    _isFlashSale = product.isFlashSale ?? false;
    _flashSaleEnd = product.flashSaleEnd;
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

  // Update return type to List<Map<String, String>>
  Future<List<Map<String, String>>> _uploadImagesToCloudinary() async {
    List<Map<String, String>> uploadedImages = [];

    if (_newImageFiles.isEmpty) {
      print('📷 No new images to upload');
      return uploadedImages;
    }

    try {
      print('☁️ Starting Cloudinary upload for ${_newImageFiles.length} images...');

      // Upload images to Cloudinary
      final uploadResults = await CloudinaryService.uploadMultipleImages(
        _newImageFiles,
        folder: 'products',
        imageType: 'product',
        onProgress: (completed, total) {
          print('📤 Upload progress: $completed/$total');
        },
      );

      // Extract BOTH public_id and secure_url for each image
      for (var result in uploadResults) {
        uploadedImages.add({
          'public_id': result.publicId,
          'url': result.secureUrl,
        });
        print('✅ Uploaded: ${result.secureUrl}');
      }

      print('🎉 Successfully uploaded ${uploadedImages.length} images to Cloudinary');

    } catch (e) {
      print('❌ Error uploading images to Cloudinary: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading images: $e'), backgroundColor: Colors.red),
        );
      }
    }

    return uploadedImages;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Upload new files to Cloudinary ONLY ONCE
      final List<Map<String, String>> newCloudinaryImages = await _uploadImagesToCloudinary();

      // 2. Prepare the final list for the backend
      List<Map<String, dynamic>> finalImagesList = [];

      // Add existing remote images (if editing)
      for (String imagePath in _selectedImages) {
        if (imagePath.startsWith('http')) {
          finalImagesList.add({
            'public_id': 'existing_image',
            'url': imagePath,
          });
        }
      }

      // Add newly uploaded images from Cloudinary
      finalImagesList.addAll(newCloudinaryImages);

      // Ensure we don't send an empty list if uploads failed or were empty
      if (finalImagesList.isEmpty) {
        finalImagesList.add({
          'public_id': 'placeholder',
          'url': 'https://placehold.co/600x400?text=No+Image',
        });
      }

      // 3. Get Auth Token
      final directToken = SimpleTokenManager.getDirectToken();
      if (directToken == null) throw Exception('Admin authentication required.');

      // 4. Construct Payload
      Map<String, dynamic> productData = {
        'name': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'brand': _brandController.text.trim(),
        'category': _selectedCategory,
        'price': double.parse(_priceController.text),
        'stock': int.parse(_stockController.text),
        'maxOrderQuantity': int.tryParse(_maxOrderController.text) ?? 5,
        'images': finalImagesList, // List of Objects
        'isOutOfStock': _isOutOfStock,
        'isOnSale': _isOnSale,
        'isPopular': _isPopular,
        'isBestSeller': _isBestSeller,
        'isFlashSale': _isFlashSale,
      };

      // Add discount calculation
      if (_discountPriceController.text.isNotEmpty) {
        double salePrice = double.parse(_discountPriceController.text);
        productData['salePrice'] = salePrice;
        double originalPrice = double.parse(_priceController.text);
        productData['discount'] = ((originalPrice - salePrice) / originalPrice * 100).round();
      }

      // 5. Final API call to your Render backend
      Map<String, dynamic> result;
      if (widget.product == null) {
        result = await _createProductDirectAPI(productData, directToken);
      } else {
        result = await _updateProductDirectAPI(widget.product!.productId!, productData, directToken);
      }

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product saved successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
          widget.onProductSaved?.call(widget.product ?? ProductModel.fromApi(result['product']));
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to save to backend');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<Map<String, dynamic>> _createProductDirectAPI(Map<String, dynamic> productData, String token) async {
    try {
      final dio = Dio();

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': '*/*',
      };

      final response = await dio.post(
        'https://backendd-ankp.onrender.com/api/v1/admin/product',
        data: productData,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          validateStatus: (status) => true, // Allow all status codes to be handled manually
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'product': response.data['product'],
          'message': 'Product created successfully'
        };
      } else {
        return {
          'success': false,
          'message': 'Server Error (${response.statusCode}): ${response.data is Map ? response.data['message'] ?? response.statusMessage : response.data}'
        };
      }
    } catch (e) {
      print('❌ API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

  Future<Map<String, dynamic>> _updateProductDirectAPI(String productId, Map<String, dynamic> productData, String token) async {
    try {
      final dio = Dio();

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': '*/*',
      };

      final response = await dio.put(
        'https://backendd-ankp.onrender.com/api/v1/admin/product/$productId',
        data: productData,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'product': response.data['product'],
          'message': 'Product updated successfully'
        };
      } else {
        return {
          'success': false,
          'message': 'Server Error (${response.statusCode}): ${response.data is Map ? response.data['message'] ?? response.statusMessage : response.data}'
        };
      }
    } catch (e) {
      print('❌ API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e'
      };
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

              const SizedBox(height: defaultPadding * 2),

              // Product Flags Section
              _buildProductFlagsSection(),

              const SizedBox(height: defaultPadding),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 50,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    widget.product == null ? 'Create Product' : 'Update Product',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                ),

              ),
              const SizedBox(height: defaultPadding * 2),

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
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _selectedImages[index].startsWith('http')
                          ? Image.network(
                        _selectedImages[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.error, color: Colors.red),
                          );
                        },
                      )
                          : Image.file(
                        File(_selectedImages[index]),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
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
              );
            },
          ),

        const SizedBox(height: defaultPadding),

        // Add Images Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickSingleImage,
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
                onPressed: _isLoading ? null : _pickImages,
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

        const SizedBox(height: defaultPadding),

        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Product Description',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            hintText: 'Enter detailed product description...',
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter product description';
            }
            return null;
          },
        ),

        const SizedBox(height: defaultPadding),

        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items: _categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: _isLoading ? null : (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCategory = newValue;
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    const Color primaryDark = Color(0xFF0B3323); // Your ritual color

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.currency_rupee, color: primaryDark),
            const SizedBox(width: 8),
            Text(
              "Pricing Details",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Original Price Field
        TextFormField(
          controller: _priceController,
          style: const TextStyle(color: primaryDark),
          decoration: InputDecoration(
            labelText: 'Original Price (₹)',
            labelStyle: TextStyle(color: primaryDark.withOpacity(0.6)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryDark.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryDark, width: 2),
            ),
            prefixIcon: const Icon(Icons.payments_outlined, color: primaryDark),
            filled: true,
            fillColor: Colors.white,
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter price';
            if (double.tryParse(value) == null) return 'Enter a valid number';
            return null;
          },
        ),

        const SizedBox(height: 16), // Gap between fields

        // Discount Price Field (Now on the next line)
        TextFormField(
          controller: _discountPriceController,
          style: const TextStyle(color: primaryDark),
          decoration: InputDecoration(
            labelText: 'Discount Price (₹)',
            labelStyle: TextStyle(color: primaryDark.withOpacity(0.6)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryDark.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryDark, width: 2),
            ),
            prefixIcon: const Icon(Icons.local_offer_outlined, color: primaryDark),
            filled: true,
            fillColor: Colors.white,
            helperText: "Customers see this as the final price",
            helperStyle: TextStyle(color: primaryDark.withOpacity(0.5)),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              double? discountPrice = double.tryParse(value);
              double? originalPrice = double.tryParse(_priceController.text);
              if (discountPrice == null) return 'Enter a valid number';
              if (originalPrice != null && discountPrice >= originalPrice) {
                return 'Discount must be lower than original price';
              }
            }
            return null;
          },
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
          onChanged: _isLoading ? null : (value) {
            setState(() {
              _isOutOfStock = value;
              // 🎯 ADDED LOGIC: Set stock to '0' when marked as out of stock
              if (value) {
                _stockController.text = '0';
              } else if (_stockController.text == '0') {
                // Optionally reset to a default if it was 0 due to 'Out of Stock'
                // This is a design choice. Leaving it as '0' might be safer.
                // _stockController.text = '';
              }
            });
          },
          activeColor: primaryColor,
        ),
      ],
    );
  }

  Widget _buildProductFlagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flag, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              "Product Flags",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: defaultPadding),

        // On Sale Flag
        SwitchListTile(
          title: const Text('On Sale'),
          subtitle: const Text('Mark this product as on sale'),
          value: _isOnSale,
          onChanged: _isLoading ? null : (value) {
            setState(() {
              _isOnSale = value;
            });
          },
          activeColor: primaryColor,
        ),

        // Popular Flag
        SwitchListTile(
          title: const Text('Popular'),
          subtitle: const Text('Mark this product as popular'),
          value: _isPopular,
          onChanged: _isLoading ? null : (value) {
            setState(() {
              _isPopular = value;
            });
          },
          activeColor: primaryColor,
        ),

        // Best Seller Flag
        SwitchListTile(
          title: const Text('Best Seller'),
          subtitle: const Text('Mark this product as best seller'),
          value: _isBestSeller,
          onChanged: _isLoading ? null : (value) {
            setState(() {
              _isBestSeller = value;
            });
          },
          activeColor: primaryColor,
        ),

        // Flash Sale Flag
        SwitchListTile(
          title: const Text('Flash Sale'),
          subtitle: const Text('Mark this product as flash sale'),
          value: _isFlashSale,
          onChanged: _isLoading ? null : (value) {
            setState(() {
              _isFlashSale = value;
              if (!value) {
                _flashSaleEnd = null; // Clear flash sale end date if disabled
              }
            });
          },
          activeColor: primaryColor,
        ),

        // Flash Sale End Date (only show when flash sale is enabled)
        if (_isFlashSale) ...[
          const SizedBox(height: defaultPadding),
          GestureDetector(
            onTap: _isLoading ? null : () async {
              try {
                print('🗓️ Opening date picker for flash sale end date...');
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _flashSaleEnd ?? DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );

                if (pickedDate != null) {
                  print('📅 Date selected: $pickedDate');
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_flashSaleEnd ?? DateTime.now()),
                  );

                  if (pickedTime != null) {
                    print('⏰ Time selected: $pickedTime');
                    final newDateTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                    print('🎯 Setting flash sale end date: $newDateTime');
                    setState(() {
                      // Ensure we're setting a DateTime object
                      if (newDateTime is DateTime) {
                        _flashSaleEnd = newDateTime;
                      } else {
                        print('❌ Error: newDateTime is not a DateTime object: ${newDateTime.runtimeType}');
                      }
                    });
                    print('✅ Flash sale end date set successfully: $_flashSaleEnd');
                  }
                }
              } catch (e) {
                print('❌ Error setting flash sale end date: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error setting date: $e')),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(defaultPadding),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: primaryColor),
                  const SizedBox(width: defaultPadding),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Flash Sale End Date & Time',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _flashSaleEnd != null && _flashSaleEnd is DateTime
                            ? '${_flashSaleEnd!.day}/${_flashSaleEnd!.month}/${_flashSaleEnd!.year} at ${_flashSaleEnd!.hour}:${_flashSaleEnd!.minute.toString().padLeft(2, '0')}'
                            : 'Tap to select date & time',
                        style: TextStyle(
                          color: (_flashSaleEnd != null && _flashSaleEnd is DateTime) ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _stockController.dispose();
    _maxOrderController.dispose();
    super.dispose();
  }
}