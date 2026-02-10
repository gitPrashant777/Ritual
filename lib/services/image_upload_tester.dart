import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadTester {
  static const String baseUrl = 'https://backendd-ankp.onrender.com/api/v1';
  
  static Future<void> testImageUpload() async {
    try {
      print('🧪 Testing image upload methods...');
      
      // Test 1: Check if there's a dedicated image upload endpoint
      await _testImageUploadEndpoint();
      
      // Test 2: Check how images should be sent in product creation
      await _testProductWithImages();
      
    } catch (e) {
      print('❌ Image upload test failed: $e');
    }
  }
  
  static Future<void> _testImageUploadEndpoint() async {
    try {
      final dio = Dio();
      
      // Test common image upload endpoints
      List<String> possibleEndpoints = [
        '$baseUrl/upload',
        '$baseUrl/uploads',
        '$baseUrl/admin/upload',
        '$baseUrl/products/upload',
        '$baseUrl/images/upload',
      ];
      
      for (String endpoint in possibleEndpoints) {
        try {
          print('🔍 Testing endpoint: $endpoint');
          final response = await dio.get(endpoint);
          print('✅ $endpoint responded: ${response.statusCode}');
        } catch (e) {
          print('❌ $endpoint failed: $e');
        }
      }
    } catch (e) {
      print('❌ Image endpoint test failed: $e');
    }
  }
  
  static Future<void> _testProductWithImages() async {
    try {
      final dio = Dio();
      
      // Test different image formats in product creation
      List<Map<String, dynamic>> testCases = [
        {
          'name': 'Test Product 1',
          'description': 'Test with empty images array',
          'category': 'Test',
          'price': 100,
          'stock': 10,
          'images': [],
        },
        {
          'name': 'Test Product 2', 
          'description': 'Test with image URLs',
          'category': 'Test',
          'price': 100,
          'stock': 10,
          'images': ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
        },
        {
          'name': 'Test Product 3',
          'description': 'Test with image objects',
          'category': 'Test', 
          'price': 100,
          'stock': 10,
          'images': [
            {'url': 'https://example.com/image1.jpg'},
            {'url': 'https://example.com/image2.jpg'}
          ],
        },
      ];
      
      for (int i = 0; i < testCases.length; i++) {
        print('🧪 Testing product creation format ${i + 1}...');
        print('📦 Data: ${jsonEncode(testCases[i])}');
        
        // Note: This would require authentication token to actually test
        // For now, just print the format we would send
      }
    } catch (e) {
      print('❌ Product image test failed: $e');
    }
  }
  
  static Future<Map<String, String>> uploadImageToCloudinary(File imageFile) async {
    try {
      print('☁️ Attempting Cloudinary upload...');
      
      // Cloudinary is commonly used for image hosting in MERN apps
      // This is a hypothetical implementation - you'd need actual Cloudinary credentials
      
      final dio = Dio();
      
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path),
        'upload_preset': 'your_upload_preset', // Would need actual preset
      });
      
      final response = await dio.post(
        'https://api.cloudinary.com/v1_1/your_cloud_name/image/upload', // Would need actual cloud name
        data: formData,
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'public_id': data['public_id'],
          'secure_url': data['secure_url'],
        };
      } else {
        throw Exception('Cloudinary upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Cloudinary upload failed: $e');
      return {};
    }
  }
  
  static Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    List<String> uploadedUrls = [];
    
    for (File file in imageFiles) {
      try {
        final result = await uploadImageToCloudinary(file);
        if (result.isNotEmpty && result['secure_url'] != null) {
          uploadedUrls.add(result['secure_url']!);
        }
      } catch (e) {
        print('❌ Failed to upload ${file.path}: $e');
      }
    }
    
    return uploadedUrls;
  }
}
