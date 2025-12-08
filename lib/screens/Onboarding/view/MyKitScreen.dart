import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shop/screens/Consultation/ConsultantsListScreen.dart';

import 'package:shop/services/firebase_kit_service.dart';
import 'package:shop/route/route_constants.dart';

import '../../../models/SavedKitModel.dart';
import 'KitDetailScreen.dart';

class MyKitScreen extends StatefulWidget {
  const MyKitScreen({super.key});

  @override
  State<MyKitScreen> createState() => _MyKitScreenState();
}

class _MyKitScreenState extends State<MyKitScreen> with SingleTickerProviderStateMixin {
  late Future<List<SavedKitModel>> _savedKitsFuture;
  late FirebaseKitService _firebaseKitService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // --- RITUAL THEME COLORS ---
  final Color _bgCream = const Color(0xFFf6efe3);
  final Color _darkGreen = const Color(0xFF0b3323);
  final Color _lightGreen = const Color(0xFFCFE8D6); // Soft sage
  final Color _cardWhite = const Color(0xFFFFFFFF);
  // ---------------------------

  @override
  void initState() {
    super.initState();
    _firebaseKitService = Provider.of<FirebaseKitService>(context, listen: false);
    _loadKits();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadKits() {
    setState(() {
      _savedKitsFuture = _firebaseKitService.getSavedKits();
    });
  }

  @override
  Widget build(BuildContext context) {
    // We override dark mode for now to enforce the Ritual theme consistency
    const isDark = false;

    return Scaffold(
      backgroundColor: _bgCream, // RITUAL CREAM BG
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: () async {
            _loadKits();
          },
          color: _darkGreen,
          backgroundColor: _bgCream,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Header Section
                  Text(
                    "My Personalized Kits",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _darkGreen,
                      letterSpacing: 0.5,
                      fontFamily: "Serif", // Optional: if you have a serif font
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Your AI-powered skincare & haircare solutions",
                    style: TextStyle(
                      fontSize: 15,
                      color: _darkGreen.withOpacity(0.7),
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Re-assessment Button
                  _buildReAssessmentButton(context),

                  const SizedBox(height: 20),

                  // Consultation Banner
                  _buildConsultationBanner(context),

                  const SizedBox(height: 28),

                  // Section Header
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _darkGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Your Saved Kits",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _darkGreen,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Saved Kits List
                  FutureBuilder<List<SavedKitModel>>(
                    future: _savedKitsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(48.0),
                            child: Column(
                              children: [
                                CircularProgressIndicator(
                                  color: _darkGreen,
                                  strokeWidth: 3,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Loading your kits...",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _darkGreen.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _buildErrorState();
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState();
                      }

                      final kits = snapshot.data!;
                      return ListView.builder(
                        itemCount: kits.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return _buildSavedKitCard(
                            context: context,
                            kit: kits[index],
                            index: index,
                          );
                        },
                      );
                    },
                  ),

                  // Add bottom padding for scrolling
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReAssessmentButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(context, onboarding);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: _cardWhite.withOpacity(0.6), // Semi-transparent white
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _darkGreen.withOpacity(0.1),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _darkGreen,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _darkGreen.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Take a Re-assessment",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _darkGreen,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Update your profile for a new plan.",
                      style: TextStyle(
                        fontSize: 13,
                        color: _darkGreen.withOpacity(0.6),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: _darkGreen.withOpacity(0.4),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsultationBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _darkGreen,
            const Color(0xFF144532), // Slightly lighter green gradient
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _darkGreen.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.video_call_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Expert Advice",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Book an in-app consultation.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConsultantsListScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.calendar_today, size: 14, color: _darkGreen),
                    label: Text(
                      "Book Now",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _darkGreen,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _bgCream,
                      foregroundColor: _darkGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedKitCard({
    required BuildContext context,
    required SavedKitModel kit,
    required int index,
  }) {
    IconData icon = Icons.medical_services_rounded;

    if (kit.kitName.toLowerCase().contains('hair')) {
      icon = Icons.health_and_safety_rounded;
    } else if (kit.kitName.toLowerCase().contains('skin')) {
      icon = Icons.face_retouching_natural_rounded;
    }

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: _darkGreen.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KitDetailScreen(kit: kit),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _lightGreen, // Soft Sage background
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: _darkGreen, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kit.kitName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _darkGreen,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: _darkGreen.withOpacity(0.5),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Assessed on ${kit.assessmentDate}",
                              style: TextStyle(
                                fontSize: 13,
                                color: _darkGreen.withOpacity(0.6),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _bgCream,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: _darkGreen,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _lightGreen.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medical_services_outlined,
                size: 50,
                color: _darkGreen.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No Kits Yet",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Take your first assessment to get a personalized kit recommendation",
              style: TextStyle(
                fontSize: 14,
                color: _darkGreen.withOpacity(0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, onboarding);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text("Start Assessment"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkGreen,
                foregroundColor: _bgCream,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "Something went wrong",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _darkGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Unable to load your kits",
              style: TextStyle(
                fontSize: 14,
                color: _darkGreen.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadKits,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkGreen,
                foregroundColor: _bgCream,
              ),
            ),
          ],
        ),
      ),
    );
  }
}