import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/models/user_session.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/admin/views/inventory_management_screen.dart';
import 'package:shop/screens/admin/views/components/admin_dashboard_card.dart';
import 'package:shop/screens/admin/views/product_list_management_screen.dart';
import 'package:shop/screens/admin/views/send_notification_screen.dart';
import 'package:shop/services/products_api_service.dart';
import 'package:shop/services/auth_api_service.dart';
import 'package:shop/services/api_service.dart';
import 'package:shop/debug_api_test_screen.dart';

// --- NEW IMPORTS ---
import 'verify_doctors_screen.dart';
import 'manage_hero_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final ProductsApiService _productsApi = ProductsApiService();
  final AuthApiService _authApiService = AuthApiService();
  final ApiService _apiService = ApiService();

  int totalProducts = 0;
  int outOfStockProducts = 0;
  int lowStockProducts = 0;
  bool _isLoading = true;
  List<ProductModel> _products = [];

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadStats();
  }

  Future<void> _checkAuthAndLoadStats() async {
    setState(() => _isLoading = true);

    try {
      // Check if we have valid admin session and token
      final token = await _apiService.getAuthToken();
      final userSession = await UserSession.getUserSession();

      if (token == null || userSession == null ||
          userSession['userData'] == null ||
          userSession['userData']['role']?.toString().toLowerCase() != 'admin') {
        throw Exception('Admin authentication required. Please log out and log back in as an administrator.');
      }

      print('✅ Admin authentication verified, loading stats...');

      // Now try to load products and stats
      await _loadProductsAndCalculateStats();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing admin panel: $e')),
        );
      }
    }
  }

  Future<void> _loadProductsAndCalculateStats() async {
    print('📊 Loading products and calculating stats...');
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch products from API with a high limit to get all products for statistics
      final products = await _productsApi.getAllProductsForAdmin();
      print('📦 Loaded ${products.length} products for stats');

      _products = products;
      _calculateStats();
      print('📊 Stats calculated: Total=$totalProducts, OutOfStock=$outOfStockProducts, LowStock=$lowStockProducts');
    } catch (e) {
      print('❌ Error loading products for stats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      // Reset stats to 0
      totalProducts = 0;
      outOfStockProducts = 0;
      lowStockProducts = 0;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateStats() {
    totalProducts = _products.length;
    outOfStockProducts = _products.where((p) => p.isOutOfStock || p.stockQuantity <= 0).length;
    lowStockProducts = _products.where((p) => p.stockQuantity > 0 && p.stockQuantity <= 5).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Panel",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [

          IconButton(
            onPressed: _isLoading ? null : _checkAuthAndLoadStats,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Dashboard',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              switch (value) {
                case 'user_view':
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    entryPointScreenRoute,
                        (route) => false,
                  );
                  break;
                case 'logout':
                  await UserSession.clearSession();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    logInScreenRoute,
                        (route) => false,
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'user_view',
                child: Row(
                  children: [
                    Icon(Icons.home),
                    SizedBox(width: 8),
                    Text('Switch to User View'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: errorColor),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: errorColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 16),
            Text(
              'Loading product data...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(defaultPadding),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: defaultPadding),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Welcome Admin!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            UserSession.userEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: defaultPadding * 1.5),

            Text(
              "Dashboard Overview",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: defaultPadding),

            // Dashboard Cards
            Row(
              children: [
                Expanded(
                  child: AdminDashboardCard(
                    title: "Total Products",
                    value: totalProducts.toString(),
                    icon: "assets/icons/Category.svg",
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: defaultPadding),
                Expanded(
                  child: AdminDashboardCard(
                    title: "Out of Stock",
                    value: outOfStockProducts.toString(),
                    icon: "assets/icons/Danger Circle.svg",
                    color: errorColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),

            Row(
              children: [
                Expanded(
                  child: AdminDashboardCard(
                    title: "Low Stock",
                    value: lowStockProducts.toString(),
                    icon: "assets/icons/info.svg",
                    color: warningColor,
                  ),
                ),
                const SizedBox(width: defaultPadding),
                Expanded(
                  child: AdminDashboardCard(
                    title: "In Stock",
                    value: (totalProducts - outOfStockProducts).toString(),
                    icon: "assets/icons/Doublecheck.svg",
                    color: successColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: defaultPadding * 2),

            Text(
              "Management Tools",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: defaultPadding),

            // Management Options

            _buildManagementOption(
              context,
              title: "Product Management",
              subtitle: "Add, edit, and manage product catalog with images",
              icon: "assets/icons/Plus1.svg",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductListManagementScreen(),
                  ),
                ).then((_) {
                  _checkAuthAndLoadStats();
                });
              },
            ),

            // --- NEW: Verify Doctors ---
            _buildManagementOption(
              context,
              title: 'Verify Doctors',
              subtitle: 'Approve pending doctor accounts',
              iconData: Icons.verified_user_outlined, // Use iconData for Material Icons
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VerifyDoctorsScreen()),
              ),
            ),

            // --- NEW: Hero Section ---
            _buildManagementOption(
              context,
              title: 'Hero Section',
              subtitle: 'Update home screen banner',
              iconData: Icons.view_carousel_outlined, // Use iconData for Material Icons
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageHeroScreen()),
              ),
            ),


// Add this inside the Column, along with other _buildManagementOption widgets
            _buildManagementOption(
              context,
              title: "Send Notification",
              subtitle: "Post alerts and updates to users",
              iconData: Icons.notifications_active_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SendNotificationScreen(),
                  ),
                );
              },
            ),

          ],
        ),
      ),
    );
  }

  // Helper widget updated to support both SVG and IconData
  Widget _buildManagementOption(
      BuildContext context, {
        required String title,
        required String subtitle,
        String? icon, // Make optional
        IconData? iconData, // Add this
        required VoidCallback onTap,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: icon != null
                ? SvgPicture.asset(
              icon,
              height: 24,
              width: 24,
              colorFilter: const ColorFilter.mode(
                primaryColor,
                BlendMode.srcIn,
              ),
            )
                : Icon(
              iconData,
              color: primaryColor,
              size: 24,
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
      ),
    );
  }
}