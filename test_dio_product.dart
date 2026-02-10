import 'package:dio/dio.dart';
import 'dart:convert';

void main() async {
  print('🧪 Testing Dio Product Creation...');
  
  // Test token (replace with actual admin token)
  String testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3NmYzNzQzNGEyMDE4YzcwMzJhZTkyZCIsImlhdCI6MTczNTUzMzQ1OSwiZXhwIjoxNzU3MDczNDU5fQ.VvkZCz_mJJY65d5Q1P8W3lKr0-DuIjBE6jPVQNQh1EU';
  
  // Test product data
  Map<String, dynamic> productData = {
    'name': 'Dio Test Product',
    'description': 'Testing product creation via Dio',
    'category': 'Electronics',
    'price': 99.99,
    'stock': 10,
    'images': [],
  };
  
  try {
    // Create Dio instance with configuration
    final dio = Dio();
    
    // Configure Dio options
    dio.options.baseUrl = 'https://backendd-ankp.onrender.com/api/v1';
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.headers = {
      'Authorization': 'Bearer $testToken',
      'Content-Type': 'application/json',
    };
    
    // Add interceptor for detailed logging
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🚀 DIO REQUEST:');
        print('   URL: ${options.baseUrl}${options.path}');
        print('   Method: ${options.method}');
        print('   Headers: ${options.headers}');
        print('   Data: ${options.data}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('📡 DIO RESPONSE:');
        print('   Status: ${response.statusCode}');
        print('   Headers: ${response.headers}');
        print('   Data: ${response.data}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('❌ DIO ERROR:');
        print('   Type: ${error.type}');
        print('   Message: ${error.message}');
        print('   Response: ${error.response?.data}');
        handler.next(error);
      },
    ));
    
    print('📦 Product data to send: $productData');
    print('🔑 Token length: ${testToken.length}');
    
    // Make the API call
    final response = await dio.post('/admin/product', data: productData);
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      print('🎉 SUCCESS! Product created successfully with Dio!');
      print('Response data: ${response.data}');
    } else {
      print('❌ Failed with status: ${response.statusCode}');
      print('Response: ${response.data}');
    }
    
  } on DioException catch (e) {
    print('❌ Dio Exception: ${e.type}');
    print('❌ Message: ${e.message}');
    print('❌ Response: ${e.response?.data}');
  } catch (e) {
    print('❌ General error: $e');
  }
}
