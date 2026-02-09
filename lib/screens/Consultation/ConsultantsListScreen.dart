// lib/screens/consultants/consultants_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ConsultantDetailScreen.dart';
import 'Ui/MyBookingsScreen.dart';
import 'Ui/ConsultantModel.dart';

class ConsultantsListScreen extends StatefulWidget {
  const ConsultantsListScreen({super.key});

  @override
  State<ConsultantsListScreen> createState() => _ConsultantsListScreenState();
}

class _ConsultantsListScreenState extends State<ConsultantsListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- COLOR RITUAL ---
  static const brandPrimary = Color(0xFF0b3323); // Deep Green
  static const creamColor = Color(0xFFf6efe3);   // Cream BG
  static const lightGreen = Color(0xFF81C784);   // Light Green Accent
  // --------------------

  String _selectedFilter = 'All';
  final List<String> _specialties = [
    'All',
    'Dermatologist',
    'General Physician',
    'Hair Specialist',
    'Skin Specialist',
  ];

  Stream<List<ConsultantModel>> _getConsultants() {
    Query query = _firestore
        .collection('consultants')
        .where('isVerified', isEqualTo: true);

    if (_selectedFilter != 'All') {
      query = query.where('specialty', isEqualTo: _selectedFilter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
          ConsultantModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Background and text colors based on theme
    final backgroundColor = isDark ? const Color(0xFF0A0A0A) : creamColor;
    final textColor = isDark ? Colors.white : brandPrimary;
    final subTextColor = isDark ? Colors.white70 : brandPrimary.withOpacity(0.7);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: textColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find a Consultant',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            Text(
              'Book your consultation',
              style: TextStyle(
                fontSize: 12,
                color: subTextColor,
              ),
            ),
          ],
        ),

      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor, // Match scaffold BG
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white12 : brandPrimary.withOpacity(0.1),
                ),
              ),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _specialties.length,
              itemBuilder: (context, index) {
                final specialty = _specialties[index];
                final isSelected = _selectedFilter == specialty;

                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = specialty),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                        colors: [brandPrimary, Color(0xFF1B5E20)], // Dark Green Gradient
                      )
                          : null,
                      color: isSelected
                          ? null
                          : (isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white), // White chips on cream BG
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? null
                          : Border.all(color: brandPrimary.withOpacity(0.1), width: 1),
                    ),
                    child: Center(
                      child: Text(
                        specialty,
                        style: TextStyle(
                          color: isSelected
                              ? creamColor
                              : (isDark ? Colors.white : brandPrimary),
                          fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Consultants List
          Expanded(
            child: StreamBuilder<List<ConsultantModel>>(
              stream: _getConsultants(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: brandPrimary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 60, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading consultants',
                          style: TextStyle(
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final consultants = snapshot.data ?? [];

                if (consultants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medical_services_outlined,
                          size: 80,
                          color: isDark ? Colors.white24 : brandPrimary.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No consultants available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please check back later',
                          style: TextStyle(
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: consultants.length,
                  itemBuilder: (context, index) {
                    return _buildConsultantCard(consultants[index], isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultantCard(ConsultantModel consultant, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: brandPrimary.withOpacity(isDark ? 0.0 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ConsultantDetailScreen(consultant: consultant),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        brandPrimary.withOpacity(0.2),
                        lightGreen.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: consultant.profileImageUrl != null
                      ? ClipOval(
                    child: Image.network(
                      consultant.profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 40,
                          color: brandPrimary,
                        );
                      },
                    ),
                  )
                      : const Icon(
                    Icons.person,
                    size: 40,
                    color: brandPrimary,
                  ),
                ),

                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Dr. ${consultant.name}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : brandPrimary,
                              ),
                            ),
                          ),
                          if (consultant.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: lightGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: brandPrimary.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: brandPrimary,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: brandPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        consultant.specialty,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : brandPrimary.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        consultant.qualification,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : brandPrimary.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 14,
                            color: isDark ? Colors.white54 : brandPrimary.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${consultant.experienceYears} years',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : brandPrimary.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.currency_rupee,
                            size: 14,
                            color: isDark ? Colors.white54 : brandPrimary.withOpacity(0.5),
                          ),
                          Text(
                            '${consultant.consultationFee.toInt()}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : brandPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark ? Colors.white38 : brandPrimary.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}