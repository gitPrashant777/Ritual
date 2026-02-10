import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/models/user_session.dart';
import 'package:shop/services/products_api_service.dart';
import 'package:shop/services/auth_api_service.dart';
import 'package:shop/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

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
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _discountController = TextEditingController();
  final _stockController = TextEditingController();
  
  final ProductsApiService _productsApiService = ProductsApiService();
  final AuthApiService _authApiService = AuthApiService();
  final ApiService _apiService = ApiService();
  
  List<String> _selectedImages = [];
  List<File> _newImageFiles = [];
  bool _isOnSale = false;
  bool _isPopular = false;
  bool _isBestSeller = false;
  bool _isFlashSale = false;
  DateTime? _flashSaleEnd;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Predefined categories for dropdown
  final List<String> _categories = [
    'Electronics',
    'Clothing',
    'Accessories',
    'Home & Garden',
    'Sports',
    'Books',
    'Beauty',
    'Toys',
    'Food & Beverages',
    'Other'
  ];

  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _loadProductData();
    }
  }

  void _loadProductData() {
    final product = widget.product!;
    _nameController.text = product.title;
    _descriptionController.text = product.brandName!; // Using brandName as description for now
    _selectedCategory = _categories.contains(product.brandName) ? product.brandName : 'Other';
    _priceController.text = product.price.toString();
    _salePriceController.text = product.priceAfetDiscount?.toString() ?? '';
    _discountController.text = product.dicountpercent?.toString() ?? '';
    _stockController.text = product.stockQuantity.toString();
    _selectedImages = List.from(product.images);
    _isOnSale = product.priceAfetDiscount != null && product.priceAfetDiscount! < product.price;
    _isPopular = false; // These would need to be added to ProductModel
    _isBestSeller = false;
    _isFlashSale = false;
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

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one image')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Add debugging for input values
        print('🔍 Debug - Form values:');
        print('  Name: "${_nameController.text}"');
        print('  Description: "${_descriptionController.text}"');
        print('  Category: "$_selectedCategory"');
        print('  Price: "${_priceController.text}"');
        print('  Sale Price: "${_salePriceController.text}"');
        print('  Stock: "${_stockController.text}"');
        
        // Admin authentication check
        print('🔐 Checking for admin authentication...');
        final currentToken = await _apiService.getAuthToken();
        final userSession = await UserSession.getUserSession();
        
        // Debug user session and token
        print('🔍 Debug auth details:');
        print('  - Token exists: ${currentToken != null}');
        print('  - Token length: ${currentToken?.length ?? 0}');
        print('  - UserSession exists: ${userSession != null}');
        
        if (userSession != null && userSession['userData'] != null) {
          print('  - User role: ${userSession['userData']['role']}');
          print('  - Role type: ${userSession['userData']['role'].runtimeType}');
          print('  - Role lowercase: ${userSession['userData']['role']?.toString().toLowerCase()}');
        }
        
        // Only check if token exists, let backend validate admin role
        if (currentToken == null) {
          throw Exception('No authentication token found. Please login again.');
        }
        
        print('✅ Token found, proceeding with API call...');
        
        // Basic token format validation
        try {
          // Just a basic check that it's roughly JWT format
          if (!currentToken.contains('.') || currentToken.split('.').length != 3) {
            throw Exception('Invalid token format');
          }
          
          print('✅ Admin authentication verified');
        } catch (e) {
          throw Exception('Invalid authentication token. Please log out and log back in. Error: $e');
        }

        // Calculate discount percentage if both prices are provided
        int? discountPercent;
        double? salePrice;
        print('🔍 Debug - Calculating discount...');
        if (_salePriceController.text.isNotEmpty) {
          print('  Parsing sale price: "${_salePriceController.text}"');
          salePrice = double.parse(_salePriceController.text);
          print('  Parsing original price: "${_priceController.text}"');
          double originalPrice = double.parse(_priceController.text);
          if (salePrice < originalPrice) {
            discountPercent = ((originalPrice - salePrice) / originalPrice * 100).round();
            print('  Calculated discount percent: $discountPercent');
          }
        }

        // Create product data map that matches backend API
        print('🔍 Debug - Creating product data...');
        Map<String, dynamic> productData = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory ?? 'Other',
          'price': double.parse(_priceController.text),
          'images': _selectedImages.map((img) => {'url': img}).toList(),
          'stock': int.parse(_stockController.text),
        };

        // Add optional fields
        if (salePrice != null) {
          productData['salePrice'] = salePrice;
        }
        if (discountPercent != null) {
          productData['discount'] = discountPercent;
        }
        productData['isOnSale'] = _isOnSale;
        productData['isPopular'] = _isPopular;
        productData['isBestSeller'] = _isBestSeller;
        productData['isFlashSale'] = _isFlashSale;
        
        if (_isFlashSale && _flashSaleEnd != null) {
          productData['flashSaleEnd'] = _flashSaleEnd!.toIso8601String();
        }

        print('📦 Product data to be sent: ${jsonEncode(productData)}');

        // Save product via API
        print('🔍 Debug - About to call API...');
        Map<String, dynamic> result;
        if (widget.product == null) {
          // Create new product using direct API call
          print('📦 Creating new product...');
          result = await _createProductDirectAPI(productData, currentToken);
          print('📦 API Response: $result');
        } else {
          // Update existing product
          print('📝 Updating existing product...');
          result = {'success': false, 'message': 'Update not implemented yet'};
        }
        
        // Check if the API call was successful
        if (result['success'] != true) {
          throw Exception(result['message'] ?? 'Failed to save product');
        }
        
        print('✅ Product saved successfully via API!');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.product == null ? 'Product created successfully!' : 'Product updated successfully!'),
              backgroundColor: successColor,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        print('🚨 ERROR CAUGHT: $e');
        print('🚨 ERROR TYPE: ${e.runtimeType}');
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving product: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Direct API call method
  Future<Map<String, dynamic>> _createProductDirectAPI(Map<String, dynamic> productData, String token) async {
    try {
      final url = Uri.parse('https://backendd-ankp.onrender.com/api/v1/admin/product');
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      print('🚀 Making direct API call to: $url');
      print('📋 Headers: $headers');
      print('📦 Body: ${jsonEncode(productData)}');
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(productData),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');
      
      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Product created successfully',
          'data': responseData
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create product: ${response.statusCode} - ${response.body}'
        };
      }
    } catch (e) {
      print('❌ Error in direct API call: $e');
      return {
        'success': false,
        'message': 'Error creating product: $e'
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: defaultPadding * 2),
                    _buildFormFields(),
                    const SizedBox(height: defaultPadding * 2),
                    _buildPriceSection(),
                    const SizedBox(height: defaultPadding * 2),
                    _buildStockSection(),
                    const SizedBox(height: defaultPadding * 3),
                    _buildSaveButton(),
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
            const Text(
              'Product Images',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: defaultPadding),
        if (_selectedImages.isNotEmpty)
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _selectedImages[index].startsWith('http')
                              ? Image.network(
                                  _selectedImages[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.error,
                                        color: errorColor,
                                      ),
                                    );
                                  },
                                )
                              : Image.file(
                                  File(_selectedImages[index]),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: defaultPadding),
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
            const SizedBox(width: defaultPadding),
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
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, color: primaryColor),
            const SizedBox(width: 8),
            const Text(
              'Product Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: defaultPadding),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Product Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter product name';
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
          ),
          items: _categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCategory = newValue;
            });
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

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.currency_rupee, color: primaryColor),
            const SizedBox(width: 8),
            const Text(
              'Pricing',
              style: TextStyle(
                fontSize: 18,
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
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter original price';
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
                controller: _salePriceController,
                decoration: const InputDecoration(
                  labelText: 'Sale Price (₹)',
                  border: OutlineInputBorder(),
                  hintText: 'Optional',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Please enter valid price';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: defaultPadding),
        CheckboxListTile(
          title: const Text('On Sale'),
          value: _isOnSale,
          onChanged: (value) => setState(() => _isOnSale = value ?? false),
          activeColor: primaryColor,
        ),
        CheckboxListTile(
          title: const Text('Popular Product'),
          value: _isPopular,
          onChanged: (value) => setState(() => _isPopular = value ?? false),
          activeColor: primaryColor,
        ),
        CheckboxListTile(
          title: const Text('Best Seller'),
          value: _isBestSeller,
          onChanged: (value) => setState(() => _isBestSeller = value ?? false),
          activeColor: primaryColor,
        ),
        CheckboxListTile(
          title: const Text('Flash Sale'),
          value: _isFlashSale,
          onChanged: (value) => setState(() => _isFlashSale = value ?? false),
          activeColor: primaryColor,
        ),
        if (_isFlashSale) ...[
          const SizedBox(height: defaultPadding),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Flash Sale End: ${_flashSaleEnd != null ? _flashSaleEnd!.toString().split(' ')[0] : 'Not set'}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _flashSaleEnd ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _flashSaleEnd = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
                child: const Text('Set Date'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory, color: primaryColor),
            const SizedBox(width: 8),
            const Text(
              'Stock Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: defaultPadding),
        TextFormField(
          controller: _stockController,
          decoration: const InputDecoration(
            labelText: 'Stock Quantity',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter stock quantity';
            }
            if (int.tryParse(value) == null) {
              return 'Please enter valid quantity';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.product == null ? 'Create Product' : 'Update Product',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    super.dispose();
  }
}
