// lib/screens/consultants/consultant_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop/models/user_session.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Ui/chat_screen.dart';
import 'Ui/MyBookingsScreen.dart';
import 'Ui/ConsultantModel.dart';

class ConsultantDetailScreen extends StatefulWidget {
  final ConsultantModel consultant;

  const ConsultantDetailScreen({super.key, required this.consultant});

  @override
  State<ConsultantDetailScreen> createState() => _ConsultantDetailScreenState();
}

class _ConsultantDetailScreenState extends State<ConsultantDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- COLOR RITUAL ---
  static const brandPrimary = Color(0xFF0b3323); // Deep Green
  static const creamColor = Color(0xFFf6efe3);   // Cream BG
  static const lightGreen = Color(0xFF81C784);   // Light Green Accent
  // --------------------

  String _selectedConsultationType = 'Video Call';
  final List<String> _consultationTypes = ['Video Call', 'Voice Call', 'Chat'];

  bool _isCalling = false;

  Future<void> _startConsultation() async {
    // Check your static UserSession class instead of Firebase
    if (UserSession.authToken == null || UserSession.userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to start.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final apiUser = UserSession.userData!;
    final String userId =
        apiUser['id'] ?? apiUser['_id'] ?? apiUser['uid'] ?? 'unknown_user';
    final String userName = apiUser['name'] ?? 'Patient';

    setState(() => _isCalling = true);

    try {
      final docRef = _firestore.collection('consultations').doc();
      final String consultationId = docRef.id;
      final DateTime now = DateTime.now();

      final consultationData = {
        'consultantId': widget.consultant.uid,
        'consultantName': widget.consultant.name,
        'userId': userId,
        'userName': userName,
        'date': now,
        'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'consultationType': _selectedConsultationType,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'channelName': consultationId,
      };

      await docRef.set(consultationData);

      if (_selectedConsultationType == 'Chat') {
        setState(() => _isCalling = false);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              consultationId: consultationId,
              uid: userId,
            ),
          ),
        );
      } else {
        // --- Phone/Video Dialer Logic ---
        final phoneNumber = widget.consultant.phone;

        if (phoneNumber.isEmpty) {
          throw Exception('Consultant phone number is not available.');
        }

        final Uri launchUri = Uri(
          scheme: 'tel',
          path: phoneNumber,
        );

        if (await canLaunchUrl(launchUri)) {
          await launchUrl(launchUri);
        } else {
          throw Exception('Could not launch phone dialer.');
        }

        setState(() => _isCalling = false);
      }
    } catch (e) {
      setState(() => _isCalling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use creamColor for light mode, dark grey for dark mode
    final backgroundColor = isDark ? const Color(0xFF0A0A0A) : creamColor;

    // Text colors need to adapt to the Cream background
    final textColor = isDark ? Colors.white : brandPrimary;
    final subTextColor = isDark ? Colors.white70 : brandPrimary.withOpacity(0.7);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: backgroundColor,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : brandPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      brandPrimary.withOpacity(0.8), // Dark Green top
                      lightGreen.withOpacity(0.3),   // Fades to light green
                    ],
                  ),
                ),
                child: widget.consultant.profileImageUrl != null
                    ? Image.network(widget.consultant.profileImageUrl!,
                    fit: BoxFit.cover, errorBuilder: (_, __, ___) {
                      return Center(
                          child: Icon(Icons.person,
                              size: 100,
                              color: creamColor));
                    })
                    : const Center(
                    child: Icon(Icons.person,
                        size: 100,
                        color: creamColor)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor Name + Verified Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Dr. ${widget.consultant.name}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (widget.consultant.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: lightGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: brandPrimary),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified,
                                  size: 16, color: brandPrimary),
                              const SizedBox(width: 4),
                              const Text('Verified',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: brandPrimary)),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(widget.consultant.specialty,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      )),

                  const SizedBox(height: 4),

                  Text(widget.consultant.qualification,
                      style: TextStyle(
                        fontSize: 14,
                        color: subTextColor,
                      )),

                  const SizedBox(height: 24),

                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                          child: _buildStatCard(
                              'Experience',
                              '${widget.consultant.experienceYears} years',
                              Icons.work_outline,
                              isDark)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildStatCard(
                              'Fee',
                              '₹${widget.consultant.consultationFee.toInt()}',
                              Icons.currency_rupee,
                              isDark)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // About section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      // White container on Cream BG looks elegant
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark ? Colors.white12 : brandPrimary.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: lightGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.info_outline,
                                  color: brandPrimary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text('About',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textColor)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(widget.consultant.about,
                            style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: subTextColor)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Consultation Type
                  Text('Select Consultation Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      )),

                  const SizedBox(height: 12),

                  Row(
                    children: _consultationTypes.map((type) {
                      bool selected = _selectedConsultationType == type;
                      IconData icon = Icons.videocam_outlined;
                      if (type == 'Voice Call') icon = Icons.call_outlined;
                      if (type == 'Chat') icon = Icons.chat_outlined;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedConsultationType = type),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? const LinearGradient(
                                colors: [brandPrimary, Color(0xFF1B5E20)], // Dark Green Gradient
                              )
                                  : null,
                              color: selected
                                  ? null
                                  : (isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: selected
                                  ? null
                                  : Border.all(color: brandPrimary.withOpacity(0.1)),
                            ),
                            child: Column(
                              children: [
                                Icon(icon,
                                    color: selected
                                        ? creamColor
                                        : brandPrimary,
                                    size: 24),
                                const SizedBox(height: 8),
                                Text(
                                  type,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: selected
                                        ? creamColor
                                        : brandPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // Start Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isCalling
                          ? null
                          : _startConsultation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandPrimary,
                        foregroundColor: creamColor, // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isCalling
                          ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: creamColor,
                          strokeWidth: 3,
                        ),
                      )
                          : Text(
                        'START ${_selectedConsultationType.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Using light green tint for stats background
        color: isDark ? Colors.white.withOpacity(0.05) : lightGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brandPrimary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: brandPrimary, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : brandPrimary,
              )),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : brandPrimary.withOpacity(0.7),
              )),
        ],
      ),
    );
  }
}