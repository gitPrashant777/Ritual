// lib/main.dart
// ignore_for_file: avoid_print

import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ROUTES
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/router.dart' as router;

// SERVICES
import 'package:shop/services/agora_config.dart';
import 'package:shop/services/api_service.dart';
import 'package:shop/services/cart_service.dart';
import 'package:shop/services/cart_wishlist_api_service.dart';
import 'package:shop/services/firebase_kit_service.dart';
import 'package:shop/services/products_api_service.dart';
import 'package:shop/services/reviews_api_service.dart';
import 'package:shop/services/orders_api_service.dart';

// THEME + SESSION
import 'package:shop/models/user_session.dart';
import 'package:shop/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --------------------------------------------------
  //                   AGORA CHAT INIT
  // --------------------------------------------------

  // ------------------ Load Local Session ------------------
  await UserSession.loadSession();

  // ------------------ Firebase Init ------------------
  await Firebase.initializeApp();

  print("🔍 MAIN: Checking existing session...");
  if (UserSession.authToken != null) {
    print("🔐 MAIN: Found existing token → user logged in");
  } else {
    print("❌ MAIN: No token → user must login");
  }

  // --------------------------------------------------
  //                   RUN APPLICATION
  // --------------------------------------------------
  runApp(
    MultiProvider(
      providers: [
        // Base services (singletons)
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        Provider<FirebaseKitService>(
          create: (_) => FirebaseKitService(),
        ),
        Provider<ProductsApiService>(
          create: (_) => ProductsApiService(),
        ),

        // Services dependent on ApiService
        ProxyProvider<ApiService, ReviewsApiService>(
          update: (_, apiService, __) => ReviewsApiService(apiService),
        ),
        ProxyProvider<ApiService, OrdersApiService>(
          update: (_, apiService, __) => OrdersApiService(apiService),
        ),
        ProxyProvider<ApiService, CartApiService>(
          update: (_, apiService, __) => CartApiService(apiService),
        ),
        ProxyProvider<ApiService, WishlistApiService>(
          update: (_, apiService, __) => WishlistApiService(apiService),
        ),

        // Cart state management
        ChangeNotifierProvider<CartService>(
          create: (context) => CartService(
            Provider.of<CartApiService>(context, listen: false),
          )..fetchCart(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ritual',

      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme(context),

      onGenerateRoute: router.generateRoute,
      initialRoute: splashScreenRoute,
    );
  }
}
