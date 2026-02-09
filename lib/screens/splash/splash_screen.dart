import 'package:flutter/material.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/models/user_session.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    ));

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _startSplashSequence();
  }

  void _startSplashSequence() async {
    _animationController.forward();

    // Add repeating pulse animation
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });

    await Future.delayed(const Duration(milliseconds: 3000));
    await _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      await UserSession.loadSession();
      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        if (UserSession.isLoggedIn) {
          if (UserSession.isAdmin) {
            Navigator.of(context).pushReplacementNamed(adminPanelScreenRoute);
          } else {
            Navigator.of(context).pushReplacementNamed(entryPointScreenRoute);
          }
        } else {
          Navigator.of(context).pushReplacementNamed(logInScreenRoute);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(logInScreenRoute);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              const Color(0xFF0A0A0A),
              const Color(0xFF020953).withOpacity(0.3),
              const Color(0xFF0A0A0A),
            ]
                : [
              const Color(0xFFFFFFFE),
              const Color(0xFFF8F9FB),
              const Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background circles
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Positioned(
                  top: -100,
                  right: -100,
                  child: Opacity(
                    opacity: 0.03 * _fadeAnimation.value,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF020953),
                            const Color(0xFF020953).withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Positioned(
                  bottom: -150,
                  left: -150,
                  child: Opacity(
                    opacity: 0.03 * _fadeAnimation.value,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF04076B),
                            const Color(0xFF04076B).withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Main content
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with enhanced animations
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark
                                      ? Colors.white
                                      : const Color(0xFF020953))
                                      .withOpacity(0.15 * _logoAnimation.value),
                                  blurRadius: 50 * _pulseAnimation.value,
                                  spreadRadius: 15 * _pulseAnimation.value,
                                ),
                                BoxShadow(
                                  color: (isDark
                                      ? const Color(0xFF020953)
                                      : const Color(0xFF04076B))
                                      .withOpacity(0.1 * _logoAnimation.value),
                                  blurRadius: 80 * _pulseAnimation.value,
                                  spreadRadius: 25 * _pulseAnimation.value,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1A1A1A)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Image.asset(
                                  isDark
                                      ? 'assets/images/logom.png'
                                      : 'assets/images/logom.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: isDark
                                              ? [
                                            Colors.white.withOpacity(0.1),
                                            Colors.white.withOpacity(0.05),
                                          ]
                                              : [
                                            const Color(0xFF020953).withOpacity(0.1),
                                            const Color(0xFF04076B).withOpacity(0.05),
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.spa_outlined,
                                        size: 200,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.3)
                                            : const Color(0xFF020953).withOpacity(0.3),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 60),

                        // Tagline with fade animation
                        FadeTransition(
                          opacity: _logoAnimation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (isDark
                                    ? Colors.white
                                    : const Color(0xFF020953))
                                    .withOpacity(0.1),
                              ),
                            ),
                            child: Text(
                              'Timeless Beauty, Modern Science',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 2.5,
                                color: isDark
                                    ? Colors.white.withOpacity(0.6)
                                    : const Color(0xFF020953).withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        const SizedBox(height: 80),

                        // Enhanced loading indicator
                        FadeTransition(
                          opacity: _logoAnimation,
                          child: Column(
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer rotating ring
                                    SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isDark
                                              ? Colors.white.withOpacity(0.3)
                                              : const Color(0xFF020953).withOpacity(0.3),
                                        ),
                                      ),
                                    ),
                                    // Inner pulsing dot
                                    ScaleTransition(
                                      scale: _pulseAnimation,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: isDark
                                                ? [Colors.white, Colors.white70]
                                                : [
                                              const Color(0xFF020953),
                                              const Color(0xFF04076B)
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 1.5,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.4)
                                      : const Color(0xFF020953).withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
