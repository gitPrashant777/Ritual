import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop/components/list_tile/divider_list_tile.dart';
import 'package:shop/components/network_image_with_loader.dart';
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
      // Better error handling for HTML responses
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
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Call backend logout API
      final response = await _userApiService.logout();
      
      // Close loading dialog
      Navigator.pop(context);
      
      if (response.success) {
        // Clear local session
        await UserSession.clearSession();
        
        // Navigate to login screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          logInScreenRoute,
          (route) => false,
        );
      } else {
        // Even if backend logout fails, clear local session
        await UserSession.clearSession();
        Navigator.pushNamedAndRemoveUntil(
          context,
          logInScreenRoute,
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);
      
      // Clear local session anyway
      await UserSession.clearSession();
      Navigator.pushNamedAndRemoveUntil(
        context,
        logInScreenRoute,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                children: [
                  ElevatedButton(
                    onPressed: _loadUserProfile,
                    child: Text('Retry'),
                  ),
                  if (_error!.contains('Authentication'))
                    ElevatedButton(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: Text('Re-login'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Extract user data with fallbacks
    final userName = _userProfile?['name'] ?? 'User';
    final userEmail = _userProfile?['email'] ?? 'user@example.com';
    final userAvatar = _userProfile?['avatar'] ?? 'https://i.imgur.com/IXnwbLk.png';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: ListView(
          children: [
            ProfileCard(
              name: userName,
              email: userEmail,
              imageSrc: userAvatar,
              // proLableText: "Sliver",
              // isPro: true, if the user is pro
              press: () {
                Navigator.pushNamed(context, userInfoScreenRoute);
              },
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            child: Text(
              "Account",
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: defaultPadding / 2),
          ProfileMenuListTile(
            text: "Orders",
            svgSrc: "assets/icons/Order.svg",
            press: () async {
              // Fetch and navigate to orders screen
              try {
                final ordersResponse = await _userApiService.getUserOrders();
                if (ordersResponse.success) {
                  Navigator.pushNamed(context, ordersScreenRoute);
                } else {
                  // Still navigate but show error in orders screen
                  Navigator.pushNamed(context, ordersScreenRoute);
                }
              } catch (e) {
                Navigator.pushNamed(context, ordersScreenRoute);
              }
            },
          ),

          ProfileMenuListTile(
            text: "Wishlist",
            svgSrc: "assets/icons/Wishlist.svg",
           press: () async {
      // Fetch and navigate to orders screen
      try {
      final ordersResponse = await _userApiService.getUserOrders();
      if (ordersResponse.success) {
      Navigator.pushNamed(context, wishlistScreenRoute);
      } else {
      // Still navigate but show error in orders screen
      Navigator.pushNamed(context, wishlistScreenRoute);
      }
      } catch (e) {
      Navigator.pushNamed(context, wishlistScreenRoute);
      }
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
          const SizedBox(height: defaultPadding),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding, vertical: defaultPadding / 2),
            child: Text(
              "Personalization",
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          DividerListTileWithTrilingText(
            svgSrc: "assets/icons/Notification.svg",
            title: "Notification",
            trilingText: "Off",
            press: () {
              Navigator.pushNamed(context, enableNotificationScreenRoute);
            },
          ),
          ProfileMenuListTile(
            text: "Preferences",
            svgSrc: "assets/icons/Preferences.svg",
            press: () {
              Navigator.pushNamed(context, preferencesScreenRoute);
            },
          ),
          const SizedBox(height: defaultPadding),


          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding, vertical: defaultPadding / 2),
            child: Text(
              "Help & Support",
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),

          ProfileMenuListTile(
            text: "FAQ",
            svgSrc: "assets/icons/FAQ.svg",
            press: () {},
            isShowDivider: false,
          ),

          // Log Out
          ListTile(
            onTap: _handleLogout,
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
              style: TextStyle(color: errorColor, fontSize: 14, height: 1),
            ),
          )
        ],
      ),
      ),
    );
  }
}
