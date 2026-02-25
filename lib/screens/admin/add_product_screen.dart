import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/products_api_service.dart';
import 'dart:io';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();

  bool _isLoading = false;
  String _selectedCategory = 'Hair Care';
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

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
  @override
  void dispose() {
    _titleController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final productApiService = ProductsApiService(); // Fixed: ProductsApiService (with 's')

      // Calculate price after discount
      final price = double.parse(_priceController.text);
      final discountPercent = _discountController.text.isNotEmpty
          ? int.parse(_discountController.text)
          : 0;
      final priceAfterDiscount = discountPercent > 0
          ? price - (price * discountPercent / 100)
          : price;

      // Create ProductModel object
      final product = ProductModel(
        title: _titleController.text.trim(),
        brandName: _brandController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : 'No description provided',
        category: _selectedCategory,
        price: price,
        priceAfetDiscount: priceAfterDiscount,
        dicountpercent: discountPercent,
        stockQuantity: int.parse(_quantityController.text),
        maxOrderQuantity: int.parse(_quantityController.text),
        isOutOfStock: int.parse(_quantityController.text) <= 0,
        image: _selectedImage?.path ?? productDemoImg1, // Use demo image if no image selected
        images: [
          _selectedImage?.path ?? productDemoImg1,
          productDemoImg2,
          productDemoImg3,
        ],
        isOnSale: discountPercent > 0,
        isPopular: false,
        isBestSeller: false,
        isFlashSale: false,
      );

      // Call the createProduct method
      final response = await productApiService.createProduct(product);

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product added successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to add product'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(defaultPadding),
          children: [
            // Image Picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to add product image',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(Optional - demo image will be used)',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Product Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Product Title *',
                hintText: 'Enter product title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_bag),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter product title';
                }
                if (value.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Brand Name
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Brand Name *',
                hintText: 'Enter brand name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.branding_watermark),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter brand name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Price and Discount
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price (₹) *',
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter price';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Invalid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Discount %',
                      hintText: '0',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_offer),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final discount = int.tryParse(value);
                        if (discount == null || discount < 0 || discount > 100) {
                          return 'Invalid %';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Quantity
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock Quantity *',
                hintText: 'Available quantity',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter quantity';
                }
                final qty = int.tryParse(value);
                if (qty == null || qty < 0) {
                  return 'Invalid quantity';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter product description (optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.description),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Add Product Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline),
                    SizedBox(width: 8),
                    Text(
                      'Add Product',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Required Fields Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '* Required fields must be filled',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
