import 'package:dio/dio.dart';
import 'dart:convert';

// Simple test to create product exactly like Postman
void main() async {
  try {
    final dio = Dio();
    
    // EXACT headers from working Postman request
    final headers = {
      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4YmIyNmJlNjhlMzhhZTY3ZWY3ZWQwYyIsInJvbGUiOiJhZG1pbiIsImlhdCI6MTc1NzMyMDI4MywiZXhwIjoxNzU3NTc5NDgzfQ.JlhS48fOXvm_svcICwW9u-NX84GVIl2Uw-bEs72DZNE',
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': '*/*',
      'User-Agent': 'PostmanRuntime/7.45.0',
      'Connection': 'keep-alive',
    };
    
    // EXACT body from Postman
    final body = {
      'name': 'Test Product',
      'description': 'Test Description',
      'category': 'Other',
      'price': 500.0,
      'stock': 100,
      'images': [],
      'salePrice': 450.0,
      'discount': 10
    };
    
    print('🎯 Making request to: https://backendd-ankp.onrender.com/api/v1/admin/product');
    print('📋 Headers: ${headers.keys.join(', ')}');
    print('📦 Body: ${jsonEncode(body)}');
    
    final response = await dio.post(
      'https://backendd-ankp.onrender.com/api/v1/admin/product',
      data: body,
      options: Options(
        headers: headers,
        validateStatus: (status) => true,
      ),
    );
    
    print('📡 Response Status: ${response.statusCode}');
    print('📋 Response Data: ${response.data}');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
