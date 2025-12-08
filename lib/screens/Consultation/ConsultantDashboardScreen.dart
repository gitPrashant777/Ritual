// screens/consultant/consultant_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:shop/screens/Consultation/Ui/AllConsultationsScreen.dart';

// (Your other imports)
import 'package:shop/services/call_service.dart';
import 'Ui/call_screen.dart';
import 'Ui/chat_screen.dart';

class ConsultantDashboardScreen extends StatefulWidget {
  const ConsultantDashboardScreen({super.key});

  @override
  State<ConsultantDashboardScreen> createState() => _ConsultantDashboardScreenState();
}

class _ConsultantDashboardScreenState extends State<ConsultantDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final CallService _callService = CallService();
  StreamSubscription? _callSubscription;

  static const brandPrimary = Color(0xFF020953);
  static const brandSecondary = Color(0xFF04076B);

  Map<String, dynamic>? consultantData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConsultantData().then((_) {
      if (!mounted) return;
      if (_auth.currentUser != null) {
        _listenForIncomingCalls();
        _listenToCallKitEvents();
      }
    });
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

  void _listenForIncomingCalls() {
    final uid = _auth.currentUser!.uid;
    _callSubscription = _callService.listenForCall(uid).listen((snapshot) {
      if (snapshot.exists) {
        final callData = snapshot.data() as Map<String, dynamic>;
        if (callData['status'] == 'pending') {
          CallService.showIncomingCallUI(callData);
        }
      }
    });
  }

  // 8. NEW METHOD: Listen for "Accept" or "Decline"
  void _listenToCallKitEvents() {
    // FlutterCallkitIncoming.onEvent.listen((event) {
    //   if (event == null) return;
    //
    //   final callData = event.body['extra'] as Map<String, dynamic>;
    //   final callId = callData['callId'];
    //   final channelName = callData['channelName'];
    //   final isVideoCall = callData['isVideoCall'] as bool;
    //
    //   if (_auth.currentUser == null) return;
    //   final doctorUid = _auth.currentUser!.uid;
    //
    //   // --- 2. THIS IS THE FIX ---
    //   // Compare the event.event (which is an enum) to the
    //   // enum values from CallEvent, NOT to Strings.
    //   switch (event.event) {
    //     // case Event.actionCallAccept: // <-- Correct enum
    //     //   CallService.hideIncomingCallUI(callId);
    //     //   _callService.endCall(doctorUid);
    //     //
    //     //   Future.delayed(Duration.zero, () {
    //     //     if (mounted) {
    //     //       Navigator.push(
    //     //         context,
    //     //         MaterialPageRoute(
    //     //           builder: (context) => CallScreen(
    //     //             channelName: channelName,
    //     //             uid: 0, // Doctor is host
    //     //             isVideoCall: isVideoCall,
    //     //           ),
    //     //         ),
    //     //       );
    //     //     }
    //     //   });
    //     //   break;
    //     //
    //     // case Event.actionCallDecline: // <-- Correct enum
    //     //   _callService.endCall(doctorUid);
    //     //   break;
    //     //
    //     // case Event.actionCallEnded: // <-- Correct enum
    //     //   _callService.endCall(doctorUid);
    //     //   break;
    //
    //     default:
    //       break;
    //   }
    //   // --- END OF FIX ---
    // });
  }

  Future<void> _loadConsultantData() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final doc = await _firestore.collection('consultants').doc(uid).get();
        if (doc.exists && mounted) {
          setState(() {
            consultantData = doc.data();
            isLoading = false;
          });
        } else if (mounted) {
          setState(() => isLoading = false);
        }
      } else if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Stream<QuerySnapshot> _getTodayConsultations() {
    final uid = _auth.currentUser?.uid;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return _firestore
        .collection('consultations')
        .where('consultantId', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .orderBy('date')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final consultantUid = _auth.currentUser?.uid ?? 'doctor';

    // ⚠️ CHAT CREDENTIAL REMOVED (No longer needed for Firebase Chat)
    // final String chatCredential = "123456";
    // --------------------------------------------------------------------------

    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: brandPrimary)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadConsultantData,
          color: brandPrimary,
          child: CustomScrollView(
            slivers: [
              // ... (SliverAppBar is unchanged) ...
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          brandPrimary,
                          brandSecondary,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  image: consultantData?['profileImageUrl'] != null
                                      ? DecorationImage(
                                    image: NetworkImage(consultantData!['profileImageUrl']),
                                    fit: BoxFit.cover,
                                  )
                                      : null,
                                ),
                                child: consultantData?['profileImageUrl'] == null
                                    ? const Icon(Icons.person, color: brandPrimary, size: 30)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dr. ${consultantData?['name'] ?? 'Doctor'}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      consultantData?['specialty'] ?? 'Specialist',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (consultantData?['isVerified'] == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
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

              // ... (SliverToBoxAdapter is unchanged) ...
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Today\'s\nConsultations',
                              '5',
                              Icons.calendar_today,
                              Colors.blue,
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Total\nPatients',
                              '124',
                              Icons.people,
                              Colors.green,
                              isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Earnings\nThis Month',
                              '₹${(consultantData?['consultationFee'] ?? 500) * 45}',
                              Icons.currency_rupee,
                              Colors.orange,
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Average\nRating',
                              '4.8 ⭐',
                              Icons.star,
                              Colors.purple,
                              isDark,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Profile Status Card
                      if (consultantData?['isVerified'] != true)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.withAlpha(51), // 0.2
                                Colors.orange.withAlpha(26), // 0.1
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.hourglass_empty, color: Colors.orange[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Profile Under Review',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Your profile is being verified by our team',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Quick Actions
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : brandPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              'My Schedule',
                              Icons.schedule,
                              brandPrimary,
                              isDark,
                                  () {
                                // Navigate to schedule
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              'My Patients',
                              Icons.people_outline,
                              Colors.blue,
                              isDark,
                                  () {
                                // Navigate to patients
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              'Earnings',
                              Icons.account_balance_wallet,
                              Colors.green,
                              isDark,
                                  () {
                                // Navigate to earnings
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              'Settings',
                              Icons.settings,
                              Colors.grey,
                              isDark,
                                  () {
                                // Navigate to settings
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Today's Consultations
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Today\'s Consultations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : brandPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to the "View All" screen
                              Navigator.push(context, MaterialPageRoute(builder: (builder)=> const AllConsultationsScreen()));
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ... (StreamBuilder for consultations is unchanged) ...
              StreamBuilder<QuerySnapshot>(
                stream: _getTodayConsultations(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    debugPrint("Today's Consultations Error: ${snapshot.error}");
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Text("Error: Failed to load consultations.\nIs your index built?"),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 60,
                                color: isDark ? Colors.white24 : Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No consultations today',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Take some rest or check your schedule',
                                style: TextStyle(
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        // Use consultationId for chat/call link
                        final consultationId = data['channelName'] ?? doc.id;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                final consultationType = data['consultationType'] ?? 'Chat';

                                if (consultationType == 'Chat') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        consultationId: consultationId, // 🎯 FIX: Use consultationId
                                        uid: consultantUid, // Pass the correct consultant ID
                                        // chatCredential REMOVED
                                      ),
                                    ),
                                  );
                                } else {
                                  // Video or Voice Call
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CallScreen(
                                        channelName: consultationId,
                                        uid: 0,
                                        isVideoCall: consultationType == 'Video Call',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: _buildConsultationCard(data, isDark),
                            ),
                          ),
                        );
                      },
                      childCount: snapshot.data!.docs.length,
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  // ... (All _build helper widgets are unchanged) ...
  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(26), // 0.1
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label,
      IconData icon,
      Color color,
      bool isDark,
      VoidCallback onTap,
      ) {
    return Material(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(26), // 0.1
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsultationCard(Map<String, dynamic> data, bool isDark) {
    final time = data['time'] ?? 'N/A';
    final patientName = data['userName'] ?? 'Patient';
    final type = data['consultationType'] ?? 'Video Call';
    final status = data['status'] ?? 'pending';

    Color statusColor = Colors.orange;
    if (status == 'completed') statusColor = Colors.green;
    if (status == 'cancelled') statusColor = Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  brandPrimary.withAlpha(51), // 0.2
                  brandSecondary.withAlpha(26), // 0.1
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              type == 'Video Call'
                  ? Icons.videocam
                  : type == 'Voice Call'
                  ? Icons.call
                  : Icons.chat,
              color: brandPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$type • $time',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(26), // 0.1
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}