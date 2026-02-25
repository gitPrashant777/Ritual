import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../ConsultantDashboardScreen.dart';
import 'chat_screen.dart';
import 'call_screen.dart';

class AllConsultationsScreen extends StatelessWidget {
  const AllConsultationsScreen({super.key});

  static const brandPrimary = Color(0xFF0b3323);

  // --- This is the new function to handle navigation ---
  void _goToDashboard(BuildContext context) {
    // This will pop all screens until it finds the route named '/consultant-dashboard'
    // This ensures you ALWAYS return to the main dashboard screen.
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (builder)=>ConsultantDashboardScreen()));

  }

  Stream<QuerySnapshot> _getAllConsultations() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('consultations')
        .where('consultantId', isEqualTo: uid)
        .orderBy('date', descending: true) // This will need an index
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ⚠️ CHAT CREDENTIAL REMOVED (No longer needed for Firebase Chat)
    // final String chatCredential = "123456";
    // --------------------------------------------------------------------------

    // --- 1. Wrap your Scaffold in a PopScope ---
    return PopScope(
      canPop: false, // We handle the pop manually
      onPopInvoked: (didPop) {
        if (didPop) return; // If already popped, do nothing
        _goToDashboard(context); // Call our custom back function
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FB),
        appBar: AppBar(
          // --- 2. Add a custom 'leading' back button ---
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : brandPrimary),
            onPressed: () {
              _goToDashboard(context); // Call our custom back function
            },
          ),
          title: const Text("All Consultations"),
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          foregroundColor: isDark ? Colors.white : brandPrimary,
          elevation: 0,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _getAllConsultations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: brandPrimary));
            }

            if (snapshot.hasError) {
              print("Error: ${snapshot.error}");
              return Center(child: Text("Error: ${snapshot.error} \n\nNOTE: This query likely requires a composite index in Firestore."));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No consultations found."));
            }

            final consultations = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: consultations.length,
              itemBuilder: (context, index) {
                final data = consultations[index].data() as Map<String, dynamic>;
                // Removed chatCredential from here
                return _buildConsultationCard(context, data, isDark);
              },
            );
          },
        ),
      ),
    );
  }

  // NOTE: chatCredential removed from method signature
  Widget _buildConsultationCard(BuildContext context, Map<String, dynamic> data, bool isDark) {
    // ... (This widget is unchanged)
    final time = data['time'] ?? 'N/A';
    final patientName = data['userName'] ?? 'Patient';
    final type = data['consultationType'] ?? 'Video Call';
    final status = data['status'] ?? 'pending';
    final date = (data['date'] as Timestamp).toDate();

    Color statusColor = Colors.orange;
    if (status == 'completed') statusColor = Colors.green;
    if (status == 'cancelled') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey[200]!),
      ),
      elevation: 0,
      child: InkWell(
        onTap: () {
          final consultationType = data['consultationType'] ?? 'Chat';
          final consultationId = data['channelName'] ?? (data['uid'] ?? ''); // Use consultationId
          final consultantUid = FirebaseAuth.instance.currentUser?.uid ?? 'doctor';

          if (consultationType == 'Chat') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  consultationId: consultationId, // 🎯 FIX: Use consultationId
                  uid: consultantUid,
                  // chatCredential REMOVED
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CallScreen(
                  channelName: consultationId,
                  uid: 0, // Doctor is host
                  isVideoCall: consultationType == 'Video Call',
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                type == 'Video Call' ? Icons.videocam
                    : type == 'Voice Call' ? Icons.call
                    : Icons.chat,
                color: brandPrimary,
                size: 24,
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
                      '${DateFormat.yMMMd().format(date)} • $time',
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
        ),
      ),
    );
  }
}