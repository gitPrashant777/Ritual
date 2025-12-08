import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:uuid/uuid.dart';

class CallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Stream to listen for incoming calls for a specific user (doctor)
  Stream<DocumentSnapshot> listenForCall(String userId) {
    // Listens to a SPECIFIC document named after the user's ID
    // This is more efficient than listening to the whole collection
    return _firestore.collection('calls').doc(userId).snapshots();
  }

  // Function for the PATIENT to start a call
  Future<String> startCall({
    required String callerId,
    required String callerName,
    required String receiverId,
    required String receiverName,
    required bool isVideoCall,
  }) async {
    final callId = _uuid.v4();
    final channelName = callId; // Use the callId as the channel name

    final callData = {
      'callId': callId,
      'channelName': channelName,
      'callerId': callerId,
      'callerName': callerName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'isVideoCall': isVideoCall,
      'status': 'pending', // pending, accepted, declined, ended
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Create the call document using the RECEIVER'S ID as the document ID
    await _firestore.collection('calls').doc(receiverId).set(callData);

    return channelName;
  }

  // Function to end/decline a call (deletes the document)
  Future<void> endCall(String userId) async {
    final doc = _firestore.collection('calls').doc(userId);
    if ((await doc.get()).exists) {
      await doc.delete();
    }
  }

  // --- Functions to show the native INCOMING CALL UI ---

  // Show the native "Incoming Call" screen
  static Future<void> showIncomingCallUI(Map<String, dynamic> callData,) async {
    // final params = CallKitParams(
    //   id: callData['callId'],
    //   nameCaller: callData['callerName'],
    //   appName: 'Ritual',
    //   // Your app name
    //   avatar: null,
    //   // Optional: patient's avatar URL
    //   handle: callData['isVideoCall'] ? 'Video Call' : 'Audio Call',
    //   type: callData['isVideoCall'] ? 1 : 0,
    //   // 0 = audio, 1 = video
    //   duration: 30000,
    //   // 30 seconds
    //   textAccept: 'Accept',
    //   textDecline: 'Decline',
    //   extra: callData,
    //   // Pass all call data
    //   android: const AndroidParams(
    //     isCustomNotification: true,
    //     isShowLogo: false,
    //     ringtonePath: 'system_ringtone_default',
    //     backgroundColor: '#020953',
    //     actionColor: '#4CAF50',
    //   ),
      // ios: const IOSParams(
      //   iconName: 'AppIcon', // Make sure you have AppIcon in your Runner/Assets.xcassets
      //   handleType: 'generic',
      //   supportsVideo: true,
      // ),

    // await FlutterCallkitIncoming.showCallkitIncoming(params);
    // }

    // Ends the native "Incoming Call" screen
    // static Future<void> hideIncomingCallUI(String callId) async {
    //   await FlutterCallkitIncoming.endCall(callId);
    // }
  }
}