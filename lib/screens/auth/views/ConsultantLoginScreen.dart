// consultant_login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop/screens/Consultation/ConsultantDashboardScreen.dart';

import '../../Consultation/Ui/AllConsultationsScreen.dart';
import 'ConsultantSignupScreen.dart';

class ConsultantLoginScreen extends StatefulWidget {
  const ConsultantLoginScreen({super.key});

  @override
  State<ConsultantLoginScreen> createState() => _ConsultantLoginScreenState();
}

class _ConsultantLoginScreenState extends State<ConsultantLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  static const brandPrimary = Color(0xFF0b3323);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Sign in with Firebase Auth
        final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Check if user is a consultant
        final consultantDoc = await _firestore
            .collection('consultants')
            .doc(userCredential.user!.uid)
            .get();

        if (!consultantDoc.exists) {
          throw Exception('This account is not registered as a consultant');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome back, Doctor!'),
              backgroundColor: brandPrimary,
            ),
          );

          // Navigate to consultant dashboard
          Navigator.push(context, MaterialPageRoute(builder: (builder)=>ConsultantDashboardScreen()));
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Login failed';
        if (e.code == 'user-not-found') {
          errorMessage = 'No consultant account found with this email';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Incorrect password';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
              // Header Image
              Stack(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.30,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE8E6E3),
                    ),
                    child: Image.asset(
                      "assets/images/docl.jpg",
                      fit: BoxFit.fill,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE8E6E3),
                          child: Center(
                            child: Icon(
                              Icons.medical_services_outlined,
                              size: 60,
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.30,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          (isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAF9F6))
                              .withOpacity(0.9),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),

              // Form Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: brandPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.medical_services,
                            color: brandPrimary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'CONSULTANT LOGIN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.5,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2,
                        height: 1.1,
                        color: isDark ? Colors.white : brandPrimary,
                        fontFamily: 'Serif',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your consultant account',
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
                              hintText: 'Enter your email',
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              hintStyle: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white30 : Colors.black26,
                                letterSpacing: 0.3,
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
                                borderSide: const BorderSide(
                                  color: brandPrimary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
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
                              hintText: 'Enter your password',
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              hintStyle: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white30 : Colors.black26,
                                letterSpacing: 0.3,
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
                                  setState(() => _isPasswordVisible = !_isPasswordVisible);
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
                                borderSide: const BorderSide(
                                  color: brandPrimary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
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

                    const SizedBox(height: 40),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Text(
                          'SIGN IN',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sign Up Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "New consultant?",
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.black54,
                              letterSpacing: 0.3,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ConsultantSignupScreen()),
                              );                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.only(left: 4),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Register here',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : brandPrimary,
                                letterSpacing: 0.3,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
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
