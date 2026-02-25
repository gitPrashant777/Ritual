// chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final String consultationId;
  final String uid;
  final String doctorName;
  final String doctorSpecialty;

  const ChatScreen({
    super.key,
    required this.consultationId,
    required this.uid,
    this.doctorName = "Doctor",
    this.doctorSpecialty = "",
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  static const brandPrimary = Color(0xFF0b3323);
  static const brandSecondary = Color(0xFF0A1E78);
  int _lastMessageCount = 0;
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ---------------------- SEND MESSAGE ----------------------
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isTyping = false);

    try {
      final messageCollection = FirebaseFirestore.instance
          .collection('consultations')
          .doc(widget.consultationId)
          .collection('messages');

      await messageCollection.add({
        'senderId': widget.uid,
        'content': text,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (mounted) {
        _controller.clear();
        _focusNode.requestFocus();
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to send message'),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // ---------------------- SCROLL HELPER ----------------------
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------------------- MESSAGE GROUPING HELPER ----------------------
  bool _isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDateDivider(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (_isSameDay(date, now)) return "Today";
    if (_isSameDay(date, yesterday)) return "Yesterday";
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // ---------------------- UI ----------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F7FA),

      // --- FIXED APP BAR WITH DYNAMIC LAYOUT ---
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          elevation: 0,
          backgroundColor: brandPrimary,
          iconTheme: const IconThemeData(color: Colors.white), // Ensures back button is white
          // Flexible title with proper constraints
          title: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate available width for title
              final availableWidth = constraints.maxWidth;

              return Row(
                children: [
                  // Doctor Avatar
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_services,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Flexible column for name and specialty
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.doctorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white, // Explicit white color
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (widget.doctorSpecialty.isNotEmpty)
                          Text(
                            widget.doctorSpecialty,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70, // Explicit light white color
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            // Video Call Button
            IconButton(
              icon: const Icon(Icons.videocam_outlined, color: Colors.white),
              onPressed: () {
                // TODO: Implement video call
              },
              tooltip: 'Video Call',
            ),
            // More Options
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                // Handle menu actions
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view_profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 20),
                      SizedBox(width: 12),
                      Text('View Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Share'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // Security/Privacy Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  brandPrimary.withOpacity(0.1),
                  brandSecondary.withOpacity(0.05),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: brandPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  "End-to-end encrypted",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : brandPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // --- MESSAGE STREAM ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('consultations')
                  .doc(widget.consultationId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: brandPrimary,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Loading messages...",
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Couldn't load messages",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Check your connection and try again",
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;
                final newMessageCount = messages.length;

                if (newMessageCount > _lastMessageCount) {
                  _scrollToBottom();
                }
                _lastMessageCount = newMessageCount;

                // --- EMPTY STATE ---
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: brandPrimary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: brandPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Start Your Consultation",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Send a message to begin the conversation\nwith your healthcare provider",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // --- MESSAGE LIST ---
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final data = messages[i].data() as Map<String, dynamic>;
                    final senderId = data['senderId'];
                    final content = data['content'] as String? ?? '...';
                    final timestamp = data['timestamp'] as Timestamp?;

                    final isMe = senderId == widget.uid;
                    final messageDate = timestamp?.toDate();

                    // Show date divider
                    final showDateDivider = i == 0 ||
                        !_isSameDay(
                          messageDate,
                          (messages[i - 1].data() as Map<String, dynamic>)['timestamp']
                              ?.toDate(),
                        );

                    final timeString = timestamp != null
                        ? DateFormat('h:mm a').format(timestamp.toDate())
                        : '';

                    return Column(
                      children: [
                        // Date Divider
                        if (showDateDivider && messageDate != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatDateDivider(messageDate),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white60 : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),

                        // Message Bubble
                        Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                // Message Content
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isMe
                                        ? const LinearGradient(
                                      colors: [brandPrimary, brandSecondary],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                        : null,
                                    color: isMe
                                        ? null
                                        : (isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.white),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(18),
                                      topRight: const Radius.circular(18),
                                      bottomLeft: isMe
                                          ? const Radius.circular(18)
                                          : const Radius.circular(4),
                                      bottomRight: isMe
                                          ? const Radius.circular(4)
                                          : const Radius.circular(18),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isMe
                                            ? brandPrimary.withOpacity(0.3)
                                            : Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    content,
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white
                                          : (isDark ? Colors.white : Colors.black87),
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                ),

                                // Timestamp
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    left: 8,
                                    right: 8,
                                  ),
                                  child: Text(
                                    timeString,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // --- INPUT BAR ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment Button
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: IconButton(
                      icon: Icon(
                        Icons.attach_file_rounded,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                      onPressed: () {
                        // TODO: Implement file attachment
                      },
                    ),
                  ),

                  // Text Input Field
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                        maxLines: 5,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: "Type your message...",
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey[500],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (text) {
                          setState(() {
                            _isTyping = text.trim().isNotEmpty;
                          });
                        },
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),

                  // Send Button
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      gradient: _isTyping
                          ? const LinearGradient(
                        colors: [brandPrimary, brandSecondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      color: _isTyping ? null : Colors.grey[400],
                      shape: BoxShape.circle,
                      boxShadow: _isTyping
                          ? [
                        BoxShadow(
                          color: brandPrimary.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                          : null,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isTyping ? Icons.send_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _isTyping ? _sendMessage : () {
                        // TODO: Implement voice recording
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
