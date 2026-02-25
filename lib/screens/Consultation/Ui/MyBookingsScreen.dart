// lib/screens/consultation/Ui/MyBookingsScreen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop/models/user_session.dart'; // <-- Correct: Uses API User Session
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:shop/services/call_service.dart';
import 'call_screen.dart';
import 'chat_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  static const brandPrimary = Color(0xFF0b3323);
  final CallService _callService = CallService();
  StreamSubscription? _callSubscription;
  bool _isCalling = false;

  Future<void> _startCall(
      Map<String, dynamic> consultationData, String consultationType) async {
    setState(() => _isCalling = true);

    // Get patient from UserSession (API Login)
    final patientData = UserSession.userData;
    if (patientData == null) {
      setState(() => _isCalling = false);
      return;
    }

    // Use API user data
    final String patientId = patientData['id'] ?? patientData['_id'] ?? patientData['uid'] ?? 'unknown_user';
    final String patientName = patientData['name'] ?? 'Patient';

    final String channelName = await _callService.startCall(
      callerId: patientId,
      callerName: patientName,
      receiverId: consultationData['consultantId'],
      receiverName: consultationData['consultantName'],
      isVideoCall: consultationType == 'Video Call',
    );

    // Listen for the call to be accepted or declined
    _callSubscription =
        _callService.listenForCall(consultationData['consultantId']).listen((snapshot) {
          if (snapshot.exists) {
            // Call is active and ringing...
          } else {
            // Call document was deleted (declined, ended, or accepted)
            _callSubscription?.cancel();
            setState(() => _isCalling = false);
            if (Navigator.of(context).canPop()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call ended or declined.')),
              );
            }
          }
        });

    // Immediately join the call screen to wait for the doctor
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          channelName: channelName,
          uid: 1, // Patient is guest (UID 1)
          isVideoCall: consultationType == 'Video Call',
        ),
      ),
    );

    // After the call screen is closed (call ended by patient)
    _callSubscription?.cancel();
    setState(() => _isCalling = false);
    // Use the *doctor's* ID to end the call document
    _callService.endCall(consultationData['consultantId']);
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get UID from UserSession (API Login)
    final uid = UserSession.userData?['id'] ?? UserSession.userData?['_id'] ?? UserSession.userData?['uid'];

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Please log in.")));
    }

    // ⚠️ CHAT CREDENTIAL REMOVED (No longer needed for Firebase Chat)
    // final String chatCredential = "123456";
    // --------------------------------------------------------------------------

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Consultations"),
        backgroundColor: brandPrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // This query now works because you created the index
        stream: FirebaseFirestore.instance
            .collection('consultations')
            .where('userId', isEqualTo: uid) // Filter for the correct API user
            .orderBy('date', descending: true) // Sort by date
            .snapshots(),
        builder: (context, snapshot) {

          // --- FIX: RE-ORDERED CHECKS ---

          // 1. Check for errors first
          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            debugPrint("--- MyBookingsScreen ERROR ---");
            debugPrint(error);

            // We use addPostFrameCallback to show the SnackBar *after* the build
            // completes, otherwise it can cause errors.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) { // Check if the widget is still in the tree
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: Could not load bookings. Check console.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            });

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Error loading consultations.\n\n"
                      "This is likely a Firestore Security Rules issue or a missing index."
                      "\n\nCheck your debug console for the error.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                ),
              ),
            );
          }

          // 2. Check for loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. Check for empty/null data (THIS IS THE SAFER CHECK)
          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("You have no consultations."));
          }
          // --- END OF FIX ---


          // 4. If all checks pass, build the list
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final consultationType = data['consultationType'] ?? 'Chat';
              final consultationId = data['channelName'] ?? doc.id; // Use consultationId

              IconData icon = Icons.chat;
              if (consultationType == 'Video Call') icon = Icons.videocam;
              if (consultationType == 'Voice Call') icon = Icons.call;

              // Safely handle a null 'date' field by providing a default
              final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
              final time = data['time'] ?? 'N/A';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(icon, color: brandPrimary),
                  title: Text('Dr. ${data['consultantName'] ?? 'Doctor'}'),
                  subtitle: Text(
                    '${DateFormat.yMMMd().format(date)} at $time\nType: $consultationType',
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandPrimary,
                    ),
                    onPressed: _isCalling
                        ? null
                        : () {
                      if (consultationType == 'Chat') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              consultationId: consultationId, // 🎯 FIX: Use consultationId
                              uid: uid, // Pass the correct user ID
                              // chatCredential REMOVED
                            ),
                          ),
                        );
                      } else {
                        _startCall(data, consultationType);
                      }
                    },
                    child: _isCalling
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : const Text('Join'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}