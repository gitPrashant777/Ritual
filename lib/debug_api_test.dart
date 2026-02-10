import 'package:flutter/material.dart';
import 'package:shop/services/api_service.dart';
import 'package:shop/services/api_config.dart';

class DebugApiTestScreen extends StatefulWidget {
  const DebugApiTestScreen({super.key});

  @override
  State<DebugApiTestScreen> createState() => _DebugApiTestScreenState();
}

class _DebugApiTestScreenState extends State<DebugApiTestScreen> {
  final ApiService _apiService = ApiService();
  String _testResults = '';
  bool _isLoading = false;

  Future<void> _testApiEndpoints() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing API endpoints...\n\n';
    });

    final baseUrls = [
      'https://mern-backend-t3h8.onrender.com',
      'https://backendd-ankp.onrender.com/api',
      'https://backendd-ankp.onrender.com/api/v1',
    ];

    final endpoints = [
      '/profile',
      '/me',
      '/user/profile',
      '/users/me',
      '/auth/profile',
      '/user/me',
    ];

    String results = _testResults;

    // First test basic connectivity
    results += '=== CONNECTIVITY TEST ===\n';
    for (final baseUrl in baseUrls) {
      try {
        final response = await _apiService.getFromCustomUrl<Map<String, dynamic>>(
          '$baseUrl/health',
          requiresAuth: false,
        );
        results += '✅ $baseUrl/health: ${response.success ? 'OK' : 'FAILED'}\n';
      } catch (e) {
        results += '❌ $baseUrl/health: $e\n';
      }
    }

    results += '\n=== PROFILE ENDPOINTS TEST ===\n';
    
    // Test with auth token if available
    final token = await _apiService.getAuthToken();
    results += 'Auth Token: ${token != null ? 'Available (${token.substring(0, 20)}...)' : 'None'}\n\n';

    for (final baseUrl in baseUrls) {
      results += '--- Testing Base URL: $baseUrl ---\n';
      
      for (final endpoint in endpoints) {
        try {
          final fullUrl = '$baseUrl$endpoint';
          final response = await _apiService.getFromCustomUrl<Map<String, dynamic>>(
            fullUrl,
            requiresAuth: true,
          );
          
          if (response.success && response.data != null) {
            results += '✅ $endpoint: SUCCESS\n';
            results += '   Data keys: ${response.data!.keys.toList()}\n';
            
            // Check if it looks like profile data
            final data = response.data!;
            if (data.containsKey('user') || data.containsKey('name') || data.containsKey('email')) {
              results += '   🎯 LOOKS LIKE PROFILE DATA!\n';
              results += '   💡 Consider using: $baseUrl as base URL\n';
            }
          } else {
            results += '❌ $endpoint: ${response.error}\n';
          }
        } catch (e) {
          if (e.toString().contains('FormatException') || e.toString().contains('DOCTYPE html')) {
            results += '🌐 $endpoint: HTML response (server error)\n';
          } else {
            results += '💥 $endpoint: $e\n';
          }
        }
      }
      results += '\n';
    }

    setState(() {
      _testResults = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API Debug Test'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _testApiEndpoints,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testApiEndpoints,
              child: _isLoading 
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Testing...'),
                    ],
                  )
                : Text('Test API Endpoints'),
            ),
            SizedBox(height: 16),
            Text(
              'Current Base URL: ${ApiConfig.currentBaseUrl}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults.isEmpty ? 'Tap "Test API Endpoints" to start' : _testResults,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
