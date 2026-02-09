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

  // --- RITUAL THEME COLORS ---
  final Color _bgCream = const Color(0xFFf6efe3);
  final Color _darkGreen = const Color(0xFF0b3323);
  final Color _lightGreen = const Color(0xFFCFE8D6); // Soft sage for active backgrounds
  final Color _notificationRed = const Color(0xFFFF6B6B);
  // ---------------------------

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
    Navigator.pop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator(color: _darkGreen)),
    );

    try {
      await _userApiService.logout();
    } catch (e) {
      print('Logout error: $e');
    }

    await UserSession.clearSession();
    Navigator.pop(context);

    Navigator.pushNamedAndRemoveUntil(
      context,
      logInScreenRoute,
          (route) => false,
    );
  }

  // Enhanced cart icon
  Widget _buildCartIcon(bool isActive) {
    return Consumer<CartService>(
      builder: (context, cartService, child) {

        final validItems = cartService.items.where((item) {
          final hasId = item.product.productId != null && item.product.productId!.isNotEmpty;
          final isNotDefault = item.product.title != 'Product';
          return hasId && isNotDefault;
        });

        int cartCount = validItems.length;

        Color iconColor = isActive
            ? _darkGreen
            : _darkGreen.withOpacity(0.7);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? _lightGreen : Colors.transparent, // Light green bg when active
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
                    color: _notificationRed,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _notificationRed.withOpacity(0.4),
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
    Color iconColor = isActive ? _darkGreen : _darkGreen.withOpacity(0.5);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isActive ? _lightGreen : Colors.transparent, // Light green accent
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
    Color iconColor = isActive ? _darkGreen : _darkGreen.withOpacity(0.5);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isActive ? _lightGreen : Colors.transparent, // Light green accent
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: iconColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We override dark mode check to enforce the Ritual Theme
    // If you want to support dark mode with these colors, you can adjust logic here.
    // For now, we apply the Cream/Dark Green theme consistently.

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Dark icons on Cream BG
        systemNavigationBarColor: _bgCream,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: _bgCream,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Exit App', style: TextStyle(color: _darkGreen, fontWeight: FontWeight.w600)),
              content: Text('Are you sure you want to exit the app?', style: TextStyle(color: _darkGreen.withOpacity(0.8))),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: _darkGreen),
                  child: const Text('Exit', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          if (shouldExit == true) Navigator.of(context).pop();
        },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: _bgCream, // RITUAL CREAM BG
          drawer: _buildModernDrawer(),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(66),
            child: Container(
              decoration: BoxDecoration(
                color: _bgCream, // RITUAL CREAM BG
                boxShadow: [BoxShadow(color: _darkGreen.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                  color: _darkGreen, // RITUAL DARK GREEN
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),

                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 30),
                            child: Image.asset(
                              "assets/images/title.png",
                              fit: BoxFit.fitHeight,
                              color: null, // Ensure original logo colors (or apply _darkGreen if it's a mask)
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
                                    _darkGreen, // RITUAL DARK GREEN
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
                color: _bgCream, // RITUAL CREAM BG
                boxShadow: [
                  BoxShadow(
                    color: _darkGreen.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Container(
                  height: 62,
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
  Widget _buildModernDrawer() {
    final userName = _userProfile?['name'] ?? 'Guest User';
    final userEmail = _userProfile?['email'] ?? 'guest@rituals.com';
    final userAvatar = _userProfile?['avatar'];

    return NavigationDrawer(
      backgroundColor: _bgCream, // RITUAL CREAM BG
      elevation: 0,
      children: [
        // Modern Header with user info
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_darkGreen, const Color(0xFF144532)], // Dark Green Gradient
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _darkGreen.withOpacity(0.3),
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
                      border: Border.all(color: _bgCream, width: 3),
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
                      backgroundColor: _bgCream,
                      backgroundImage: userAvatar != null ? NetworkImage(userAvatar) : null,
                      child: userAvatar == null
                          ? Icon(Icons.person, size: 36, color: _darkGreen)
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
                          style: TextStyle(
                            color: _bgCream,
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
                            color: _bgCream.withOpacity(0.9),
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
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Profile',
                        style: TextStyle(
                          color: _bgCream,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, color: _bgCream, size: 12),
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
        ),

        _buildDrawerTile(
          icon: Icons.favorite_rounded,
          label: 'Wishlist',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, wishlistScreenRoute);
          },
        ),


        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Divider(height: 1, color: _darkGreen.withOpacity(0.1)),
        ),

        _buildDrawerTile(
          icon: Icons.location_on_rounded,
          label: 'Addresses',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, addressesScreenRoute);
          },
        ),



        if (UserSession.isAdmin) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Divider(height: 1, color: _darkGreen.withOpacity(0.1)),
          ),
          _buildDrawerTile(
            icon: Icons.admin_panel_settings_rounded,
            label: 'Admin Panel',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, adminPanelScreenRoute);
            },
            iconColor: _darkGreen,
          ),
        ],

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Divider(height: 1, color: _darkGreen.withOpacity(0.1)),
        ),



        _buildDrawerTile(
          icon: Icons.logout_rounded,
          label: 'Logout',
          onTap: _handleLogout,
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
                  ? _lightGreen // USE LIGHT GREEN BG
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
                          ? _darkGreen
                          : _darkGreen.withOpacity(0.6)),
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
                              ? _darkGreen
                              : _darkGreen.withOpacity(0.8)),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _darkGreen,
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
                        ? _darkGreen
                        : _darkGreen.withOpacity(0.5),
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
                    color: _darkGreen,
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