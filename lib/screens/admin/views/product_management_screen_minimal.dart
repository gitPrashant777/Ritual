import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/models/simple_token_manager.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

class ProductManagementScreenMinimal extends StatefulWidget {
  final ProductModel? product;
  final Function(ProductModel)? onProductSaved;

  const ProductManagementScreenMinimal({
    Key? key,
    this.product,
    this.onProductSaved,
  }) : super(key: key);

  @override
  State<ProductManagementScreenMinimal> createState() => _ProductManagementScreenMinimalState();
}

class _ProductManagementScreenMinimalState extends State<ProductManagementScreenMinimal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _loadProductData();
    }
  }

  void _loadProductData() {
    final product = widget.product!;
    _titleController.text = product.title;
    _brandController.text = product.brandName!;
    _priceController.text = product.price.toString();
    _stockController.text = product.stockQuantity.toString();
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final directToken = SimpleTokenManager.getDirectToken();
        final isDirectAdmin = SimpleTokenManager.isDirectAdmin();
        
        if (directToken == null || !isDirectAdmin) {
          throw Exception('Admin authentication required. Please log in again.');
        }

        Map<String, dynamic> productData = {
          'name': _titleController.text.trim(),
          'description': _brandController.text.trim(),
          'category': 'Other',
          'price': double.parse(_priceController.text),
          'stock': int.parse(_stockController.text),
          'images': ['https://via.placeholder.com/400x400/CCCCCC/FFFFFF?text=No+Image'],
          'salePrice': double.parse(_priceController.text) * 0.9, // 10% discount
          'discount': 10,
        };

        Map<String, dynamic> result = await _createProductDirectAPI(productData, directToken);
        
        if (!result['success']) {
          throw Exception(result['message'] ?? 'Failed to create product');
        }
        
        // Create ProductModel from result for callback
        if (widget.onProductSaved != null && result['product'] != null) {
          try {
            final productModel = ProductModel.fromApi(result['product']);
            widget.onProductSaved!(productModel);
          } catch (e) {
            print('Error creating ProductModel for callback: $e');
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product ${widget.product == null ? 'created' : 'updated'} successfully!'),
              backgroundColor: successColor,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
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
          'message': 'Failed to create product: ${response.statusMessage}'
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
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter stock quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }
}
