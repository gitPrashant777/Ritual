import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shop/models/user_session.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/auth/views/ConsultantSignupScreen.dart';
import 'package:shop/services/auth_api_service.dart';

// --- IMPORT REMOVED ---
// We remove the agora_chat_sdk import because the app
// should not create users. Only your backend server should.

import '../../../constants.dart';
import '../../Consultation/ConsultantDashboardScreen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthApiService _authApi = AuthApiService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isTermsAccepted = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final route = ModalRoute.of(context);
        if (route?.settings.arguments == 'from_login') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child:
                    Text('Welcome! Please create your account to continue.'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0F2E1A

),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      if (!_isTermsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please accept the terms of service to continue'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      if (!mounted) return;

      try {
        final response = await _authApi.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        if (response.success && response.data != null) {
          final userData = response.data!;

          String? authToken = userData['token'] ??
              userData['accessToken'] ??
              userData['data']?['token'];

          Map<String, dynamic>? user = userData['user'] ??
              userData['data']?['user'] ??
              (userData['email'] != null ? userData : null);

          // --- AGORA BLOCK REMOVED ---
          // Your backend API (which _authApi.register calls)
          // is now responsible for creating the Agora Chat user
          // on the server.
          // ---

          if (user != null && user['email'] != null) {
            await UserSession.setUserSession(
              user['email'],
              token: authToken,
              userData: user,
            );
          } else {
            await UserSession.setUserSession(
              _emailController.text.trim(),
              token: authToken,
            );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Welcome to RITUAL! 🎉'),
              backgroundColor: const Color(0xFF0F2E1A

),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          Navigator.pushNamedAndRemoveUntil(
            context,
            onboarding,
                (route) => false,
          );
        } else {
          String errorMessage =
              response.error ?? 'Registration failed. Please try again.';

          if (errorMessage.toLowerCase().contains('already exists') ||
              errorMessage.toLowerCase().contains('duplicate')) {
            errorMessage =
            'This email is already registered. Please log in instead.';
          } else if (errorMessage.toLowerCase().contains('invalid email')) {
            errorMessage = 'Please enter a valid email address.';
          } else if (errorMessage.toLowerCase().contains('password')) {
            errorMessage = 'Password must be at least 6 characters long.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        String errorMessage = 'Registration failed. Please try again.';

        if (e.toString().toLowerCase().contains('network') ||
            e.toString().toLowerCase().contains('connection') ||
            e.toString().toLowerCase().contains('timeout')) {
          errorMessage = 'Network error. Please check your connection.';
        } else if (e.toString().toLowerCase().contains('server')) {
          errorMessage = 'Server error. Please try again later.';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAF9F6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Premium header image with overlay
              Stack(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.28,
                    width: double.infinity,
                    child: Image.asset(
                      "assets/images/imgk.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.28,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          (isDark
                              ? const Color(0xFF0F0F0F)
                              : const Color(0xFFFAF9F6))
                              .withOpacity(0.9),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),

              // Form content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Header section
                    Text(
                      'CREATE ACCOUNT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Join Us',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2,
                        height: 1.1,
                        color: isDark ? Colors.white : const Color(0xFF0F2E1A

),
                        fontFamily: 'Serif',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your details to create an account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white60 : Colors.black54,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            style: TextStyle(
                              fontSize: 16,
                              letterSpacing: 0.5,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'FULL NAME',
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              filled: true,
                              fillColor:
                              isDark ? const Color(0xFF1A1A1A) : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white12 : Colors.black12,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white12 : Colors.black12,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F2E1A

),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              if (value.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              fontSize: 16,
                              letterSpacing: 0.5,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'EMAIL',
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              filled: true,
                              fillColor:
                              isDark ? const Color(0xFF1A1A1A) : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white12 : Colors.black12,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white12 : Colors.black12,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F2E1A

),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: TextStyle(
                              fontSize: 16,
                              letterSpacing: 0.5,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'PASSWORD',
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              filled: true,
                              fillColor:
                              isDark ? const Color(0xFF1A1A1A) : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() =>
                                  _isPasswordVisible = !_isPasswordVisible);
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white12 : Colors.black12,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white12 : Colors.black12,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F2E1A

),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Terms checkbox
                    GestureDetector(
                      onTap: () {
                        setState(() => _isTermsAccepted = !_isTermsAccepted);
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _isTermsAccepted,
                              onChanged: (value) {
                                setState(() => _isTermsAccepted = value ?? false);
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: BorderSide(
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text.rich(
                                TextSpan(
                                  text: "I agree to the ",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    letterSpacing: 0.3,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Terms of Service",
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F2E1A

),
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          Navigator.pushNamed(
                                            context,
                                            termsOfServicesScreenRoute,
                                          );
                                        },
                                    ),
                                    const TextSpan(text: " and "),
                                    TextSpan(
                                      text: "Privacy Policy",
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F2E1A

),
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          Navigator.pushNamed(
                                            context,
                                            termsOfServicesScreenRoute,
                                          );
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_isTermsAccepted && !_isLoading)
                            ? _handleSignUp
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          isDark ? Colors.white : const Color(0xFF0F2E1A

),
                          foregroundColor:
                          isDark ? const Color(0xFF0F2E1A

) : Colors.white,
                          disabledBackgroundColor: isDark
                              ? Colors.white.withOpacity(0.3)
                              : Colors.black26,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark
                                  ? const Color(0xFF0F2E1A

)
                                  : Colors.white,
                            ),
                          ),
                        )
                            : const Text(
                          'CREATE ACCOUNT',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Log In Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.black54,
                              letterSpacing: 0.3,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                  context, logInScreenRoute);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.only(left: 4),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Log in',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F2E1A

),
                                letterSpacing: 0.3,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark ? Colors.white12 : Colors.black12,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white38 : Colors.black38,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark ? Colors.white12 : Colors.black12,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (builder) =>
                                const ConsultantSignupScreen()),
                          );
                        },
                        icon:
                        const Icon(Icons.medical_services_outlined, size: 20),
                        label: const Text(
                          'REGISTER AS CONSULTANT',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0b3323),
                          side: const BorderSide(
                            color: Color(0xFF0b3323),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}