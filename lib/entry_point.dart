import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/screens/Onboarding/view/MyKitScreen.dart';
import 'package:shop/services/cart_service.dart';
import 'package:shop/services/user_api_service.dart';
import 'package:shop/models/user_session.dart';

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final UserApiService _userApiService = UserApiService();

  final List _pages = const [
    HomeScreen(),
    MyKitScreen(),
    DiscoverScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  int _currentIndex = 0;
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartService>(context, listen: false).fetchCart();
    });
  }

  Future<void> _loadUserProfile() async {
    if (_isLoadingProfile) return;

    setState(() => _isLoadingProfile = true);

    try {
      final response = await _userApiService.getProfile();
      if (response.success && response.data != null) {
        setState(() {
          _userProfile = response.data!['user'] ?? response.data;
        });
      }
    } catch (e) {
      print('Error loading profile for drawer: $e');
    } finally {
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _handleLogout() async {
    Navigator.pop(context); // Close drawer first

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      await _userApiService.logout();
    } catch (e) {
      print('Logout error: $e');
    }

    await UserSession.clearSession();
    Navigator.pop(context); // Close loading dialog

    Navigator.pushNamedAndRemoveUntil(
      context,
      logInScreenRoute,
          (route) => false,
    );
  }

  // Enhanced cart icon
  // Enhanced cart icon
  Widget _buildCartIcon(bool isActive) {
    return Consumer<CartService>(
      builder: (context, cartService, child) {

        // --- FIX START: Filter Ghost Items for Badge Count ---
        // We filter the items list to count ONLY valid products
        final validItems = cartService.items.where((item) {
          final hasId = item.product.productId != null && item.product.productId!.isNotEmpty;
          // Check if title is not the default placeholder
          final isNotDefault = item.product.title != 'Product';
          return hasId && isNotDefault;
        });

        int cartCount = validItems.length;
        // --- FIX END ---

        Color iconColor = isActive
            ? const Color(0xFF020953)
            : Theme.of(context).brightness == Brightness.dark
            ? Colors.white70
            : const Color(0xFF020953).withOpacity(0.6);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF020953).withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SvgPicture.asset(
                "assets/icons/Bag.svg",
                height: 22,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
            if (cartCount > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF4757)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4757).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    cartCount > 99 ? '99+' : cartCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  Widget _buildNavIcon(String src, {bool isActive = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color iconColor = isActive
        ? const Color(0xFF020953)
        : isDark ? Colors.white60 : const Color(0xFF020953).withOpacity(0.5);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF020953).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SvgPicture.asset(
        src,
        height: 20,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildIconNavIcon(IconData icon, {bool isActive = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color iconColor = isActive
        ? const Color(0xFF020953)
        : isDark ? Colors.white60 : const Color(0xFF020953).withOpacity(0.5);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF020953).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: iconColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Exit App', style: TextStyle(color: const Color(0xFF020953), fontWeight: FontWeight.w600)),
              content: Text('Are you sure you want to exit the app?', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF020953)),
                  child: const Text('Exit', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          if (shouldExit == true) Navigator.of(context).pop();
        },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
          drawer: _buildModernDrawer(isDark),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _scaffoldKey.currentState?.openDrawer(),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.menu_rounded,
                                  color: isDark ? Colors.white70 : const Color(0xFF020953).withOpacity(0.8),
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF020953), Color(0xFF04076B)],
                            ).createShader(bounds),
                            child: const Text(
                              "RITUAL",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.0,
                                color: Colors.white,
                                fontFamily: 'Serif',
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pushNamed(context, searchScreenRoute),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: SvgPicture.asset(
                                  "assets/icons/Search.svg",
                                  height: 22,
                                  colorFilter: ColorFilter.mode(
                                    isDark ? Colors.white70 : const Color(0xFF020953).withOpacity(0.7),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pushNamed(context, cartScreenRoute),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: _buildCartIcon(false),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: PageTransitionSwitcher(
            duration: const Duration(milliseconds: 400),
            reverse: _currentIndex < 2,
            transitionBuilder: (child, animation, secondAnimation) {
              return FadeThroughTransition(
                animation: animation,
                secondaryAnimation: secondAnimation,
                child: child,
              );
            },
            child: _pages[_currentIndex],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Container(
                  height: 62, // REDUCED from 60 to fix 1px overflow
                  padding: const EdgeInsets.symmetric(horizontal: defaultPadding / 2, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(index: 0, icon: "assets/icons/Shop.svg", label: "Shop", useSvg: true),
                      _buildNavItem(index: 1, iconData: Icons.medical_services_outlined, activeIconData: Icons.medical_services, label: "My Kit", useSvg: false),
                      _buildNavItem(index: 2, icon: "assets/icons/Category.svg", label: "Discover", useSvg: true),
                      _buildNavItem(index: 3, iconData: Icons.notifications_outlined, activeIconData: Icons.notifications, label: "Alerts", useSvg: false),
                      _buildNavItem(index: 4, icon: "assets/icons/Profile.svg", label: "Profile", useSvg: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Modern Material 3 Drawer with ProfileScreen data
  Widget _buildModernDrawer(bool isDark) {
    final userName = _userProfile?['name'] ?? 'Guest User';
    final userEmail = _userProfile?['email'] ?? 'guest@baetown.com';
    final userAvatar = _userProfile?['avatar'];

    return NavigationDrawer(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      elevation: 0,
      children: [
        // Modern Header with user info
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF020953), Color(0xFF04076B)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF020953).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      backgroundImage: userAvatar != null ? NetworkImage(userAvatar) : null,
                      child: userAvatar == null
                          ? const Icon(Icons.person, size: 36, color: Color(0xFF020953))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 4);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'View Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Navigation Items
        _buildDrawerTile(
          icon: Icons.home_rounded,
          label: 'Home',
          isSelected: _currentIndex == 0,
          onTap: () {
            Navigator.pop(context);
            setState(() => _currentIndex = 0);
          },
          isDark: isDark,
        ),

        _buildDrawerTile(
          icon: Icons.shopping_bag_rounded,
          label: 'My Orders',
          onTap: () async {
            Navigator.pop(context);
            try {
              await _userApiService.getUserOrders();
              Navigator.pushNamed(context, ordersScreenRoute);
            } catch (e) {
              Navigator.pushNamed(context, ordersScreenRoute);
            }
          },
          isDark: isDark,
        ),

        _buildDrawerTile(
          icon: Icons.favorite_rounded,
          label: 'Wishlist',
          onTap: () {
            Navigator.pop(context);
            // Navigate to wishlist
          },
          isDark: isDark,
        ),

        _buildDrawerTile(
          icon: Icons.wallet_rounded,
          label: 'Wallet',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, walletScreenRoute);
          },
          isDark: isDark,
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Divider(height: 1),
        ),

        _buildDrawerTile(
          icon: Icons.location_on_rounded,
          label: 'Addresses',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, addressesScreenRoute);
          },
          isDark: isDark,
        ),

        _buildDrawerTile(
          icon: Icons.credit_card_rounded,
          label: 'Payment Methods',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, emptyPaymentScreenRoute);
          },
          isDark: isDark,
        ),

        _buildDrawerTile(
          icon: Icons.settings_rounded,
          label: 'Settings',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, preferencesScreenRoute);
          },
          isDark: isDark,
        ),

        if (UserSession.isAdmin) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Divider(height: 1),
          ),
          _buildDrawerTile(
            icon: Icons.admin_panel_settings_rounded,
            label: 'Admin Panel',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, adminPanelScreenRoute);
            },
            isDark: isDark,
            iconColor: const Color(0xFF020953),
          ),
        ],

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Divider(height: 1),
        ),

        _buildDrawerTile(
          icon: Icons.help_rounded,
          label: 'Help & Support',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, getHelpScreenRoute);
          },
          isDark: isDark,
        ),

        _buildDrawerTile(
          icon: Icons.logout_rounded,
          label: 'Logout',
          onTap: _handleLogout,
          isDark: isDark,
          iconColor: Colors.red,
          textColor: Colors.red,
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isSelected = false,
    Color? iconColor,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF020953).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: iconColor ??
                      (isSelected
                          ? const Color(0xFF020953)
                          : isDark
                          ? Colors.white70
                          : Colors.black54),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: textColor ??
                          (isSelected
                              ? const Color(0xFF020953)
                              : isDark
                              ? Colors.white
                              : Colors.black87),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF020953),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    String? icon,
    IconData? iconData,
    IconData? activeIconData,
    required String label,
    required bool useSvg,
  }) {
    final isActive = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (index != _currentIndex) {
              setState(() => _currentIndex = index);
              HapticFeedback.lightImpact();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (useSvg && icon != null)
                  _buildNavIcon(icon, isActive: isActive)
                else if (!useSvg && iconData != null)
                  _buildIconNavIcon(
                    isActive && activeIconData != null ? activeIconData : iconData,
                    isActive: isActive,
                  ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: isActive ? 10 : 9,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? const Color(0xFF020953)
                        : isDark ? Colors.white60 : const Color(0xFF020953).withOpacity(0.5),
                    letterSpacing: 0.3,
                  ),
                  child: Text(label),
                ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 2,
                  width: isActive ? 16 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF020953),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
