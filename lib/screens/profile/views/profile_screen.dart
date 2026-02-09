import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/models/user_session.dart';
import 'package:shop/services/user_api_service.dart';

import 'components/profile_card.dart';
import 'components/profile_menu_item_list_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserApiService _userApiService = UserApiService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String? _error;

  // --- COLOR RITUAL ---
  static const brandPrimary = Color(0xFF0b3323); // Deep Green
  static const creamColor = Color(0xFFf6efe3);   // Cream BG
  static const lightGreen = Color(0xFF81C784);   // Light Green Accent
  // --------------------

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _userApiService.getProfile();

      if (response.success && response.data != null) {
        setState(() {
          _userProfile = response.data!['user'] ?? response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      String errorMessage = 'Error loading profile';
      if (e.toString().contains('FormatException') && e.toString().contains('<!DOCTYPE html>')) {
        errorMessage = 'Profile service is currently unavailable. Please try again later.';
      } else {
        errorMessage = 'Error loading profile: $e';
      }

      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: brandPrimary),
        ),
      );

      final response = await _userApiService.logout();

      if (mounted) Navigator.pop(context);

      await UserSession.clearSession();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          logInScreenRoute,
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      await UserSession.clearSession();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          logInScreenRoute,
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme logic for dark mode safety
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F0F) : creamColor;
    final textColor = isDark ? Colors.white : brandPrimary;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: brandPrimary),
              const SizedBox(height: 16),
              Text('Loading profile...', style: TextStyle(color: textColor)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                children: [
                  ElevatedButton(
                    onPressed: _loadUserProfile,
                    style: ElevatedButton.styleFrom(backgroundColor: brandPrimary),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                  if (_error!.contains('Authentication'))
                    ElevatedButton(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Re-login', style: TextStyle(color: Colors.white)),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final userName = _userProfile?['name'] ?? 'User';
    final userEmail = _userProfile?['email'] ?? 'user@example.com';
    final userAvatar = _userProfile?['avatar'] != null
        ? (_userProfile!['avatar'] is Map ? _userProfile!['avatar']['url'] : _userProfile!['avatar'])
        : 'https://i.imgur.com/IXnwbLk.png';

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        color: brandPrimary,
        backgroundColor: Colors.white,
        onRefresh: _loadUserProfile,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header Section
            Container(
              color: bgColor,
              child: ProfileCard(
                name: userName,
                email: userEmail,
                imageSrc: userAvatar,
                press: () {
                  Navigator.pushNamed(context, userInfoScreenRoute);
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding,
                vertical: defaultPadding,
              ),
              child: Text(
                "Account",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: textColor.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ProfileMenuListTile(
              text: "Orders",
              svgSrc: "assets/icons/Order.svg",
              press: () {
                Navigator.pushNamed(context, ordersScreenRoute);
              },
            ),

            ProfileMenuListTile(
              text: "Wishlist",
              svgSrc: "assets/icons/Wishlist.svg",
              press: () {
                Navigator.pushNamed(context, wishlistScreenRoute);
              },
            ),

            ProfileMenuListTile(
              text: "Addresses",
              svgSrc: "assets/icons/Address.svg",
              press: () {
                Navigator.pushNamed(context, addressesScreenRoute);
              },
            ),

            // Only show Admin Panel for admin users
            if (UserSession.isAdmin)
              ProfileMenuListTile(
                text: "Admin Panel",
                svgSrc: "assets/icons/Category.svg",
                press: () {
                  Navigator.pushNamed(context, adminPanelScreenRoute);
                },
              ),

            const SizedBox(height: defaultPadding * 2),

            // Log Out Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: ListTile(
                onTap: _handleLogout,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.withOpacity(0.1)),
                ),
                tileColor: Colors.red.withOpacity(0.05),
                minLeadingWidth: 24,
                leading: SvgPicture.asset(
                  "assets/icons/Logout.svg",
                  height: 24,
                  width: 24,
                  colorFilter: const ColorFilter.mode(
                    errorColor,
                    BlendMode.srcIn,
                  ),
                ),
                title: const Text(
                  "Log Out",
                  style: TextStyle(
                      color: errorColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600
                  ),
                ),
              ),
            ),

            const SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }
}