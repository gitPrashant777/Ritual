// consultant_signup_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- IMPORT REMOVED ---
// We remove the agora_chat_sdk import because the app
// should not create users. Only the server should.

import 'package:shop/screens/auth/views/ConsultantLoginScreen.dart';
import 'ConsultantProfileSetupScreen.dart';

class ConsultantSignupScreen extends StatefulWidget {
  const ConsultantSignupScreen({super.key});

  @override
  State<ConsultantSignupScreen> createState() => _ConsultantSignupScreenState();
}

class _ConsultantSignupScreenState extends State<ConsultantSignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isTermsAccepted = false;

  static const brandPrimary = Color(0xFF0b3323);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept terms and conditions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Create Firebase Auth user
        final UserCredential userCredential =
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final String firebaseUID = userCredential.user!.uid;

        // --- AGORA BLOCK REMOVED ---
        // The Agora user is now created by your
        // secure Firebase Function (server-side), not the app.
        // ---

        // Save basic consultant data to Firestore
        await _firestore
            .collection('consultants')
            .doc(firebaseUID)
            .set({
          'uid': firebaseUID,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': 'consultant',
          'isProfileComplete': false,
          'isVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Please complete your profile.'),
              backgroundColor: brandPrimary,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ConsultantProfileSetupScreen(
                uid: firebaseUID,
              ),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Signup failed';
        if (e.code == 'email-already-in-use') {
          errorMessage = 'This email is already registered';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Password is too weak';
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
              // Show the original error
              content: Text('Error: ${e.toString()}'),
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
                    height: MediaQuery.of(context).size.height * 0.25,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE8E6E3),
                    ),
                    child: Image.asset(
                      "assets/images/docs.png",
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
                    height: MediaQuery.of(context).size.height * 0.25,
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
                          'CONSULTANT REGISTRATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.5,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Join as Doctor',
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
                      'Create your consultant account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white60 : Colors.black54,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Full Name
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            style: TextStyle(
                              fontSize: 16,
                              letterSpacing: 0.5,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'FULL NAME',
                              hintText: 'Dr. John Doe',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              hintStyle: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white30 : Colors.black26,
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
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Email
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
                              hintText: 'doctor@example.com',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              hintStyle: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white30 : Colors.black26,
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

                          const SizedBox(height: 20),

                          // Phone
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              fontSize: 16,
                              letterSpacing: 0.5,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'PHONE NUMBER',
                              hintText: '+91 9999999999',
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              hintStyle: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white30 : Colors.black26,
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
                                return 'Please enter your phone number';
                              }
                              if (value.length < 10) {
                                return 'Please enter a valid phone number';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Password
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
                              hintText: 'Create a strong password',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              hintStyle: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white30 : Colors.black26,
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

                    // Terms Checkbox
                    Row(
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
                            activeColor: brandPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'I agree to the Terms & Conditions and understand that my profile will be verified before approval',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
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
                            valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
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

                    const SizedBox(height: 24),

                    // Login Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already registered?",
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
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ConsultantLoginScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.only(left: 4),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Sign in',
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