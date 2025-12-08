import 'package:flutter/material.dart';
import 'package:shop/constants.dart';

import '../../notification/model/NotificationService.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _userIdController = TextEditingController();

  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  bool _isBroadcast = true; // Default to Broadcast to All

  // ✅ FIX: Use 'SaleAlert' as the default since we know it works
  String _selectedType = 'SaleAlert';

  // ✅ FIX: Updated list to match Backend Enums (PascalCase)
  // 'SaleAlert' is confirmed via your screenshot.
  // 'OrderUpdate' and 'System' are standard MERN defaults.
  final List<String> _types = [
    'SaleAlert',
    'OrderUpdate',
    'System',
    'General'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // ✅ FIX: Send null if broadcasting, otherwise send the User ID string
    final String? targetUserId = _isBroadcast ? null : _userIdController.text.trim();

    print('📦 Sending Type: $_selectedType'); // Debug print to verify

    final success = await _notificationService.sendNotification(
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      type: _selectedType, // This sends "SaleAlert" (Valid) instead of "promo" (Invalid)
      userId: targetUserId,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sent successfully!'),
            backgroundColor: successColor,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed. Type "$_selectedType" might be invalid.'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Notification"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                  hintText: "e.g., Flash Sale!",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => value!.isEmpty ? "Enter a title" : null,
              ),
              const SizedBox(height: defaultPadding),

              // Message Field
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: "Message",
                  hintText: "e.g., 50% off everything...",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) => value!.isEmpty ? "Enter a message" : null,
              ),
              const SizedBox(height: defaultPadding),

              // Type Dropdown (Updated)
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: "Notification Type",
                  helperText: "Must match backend Enums (e.g. SaleAlert)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _types.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: defaultPadding),

              // Broadcast vs Specific User Switch
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("Broadcast to All Users"),
                      subtitle: const Text("Turn off to send to a specific person"),
                      value: _isBroadcast,
                      activeColor: primaryColor,
                      onChanged: (val) {
                        setState(() => _isBroadcast = val);
                      },
                    ),

                    if (!_isBroadcast)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextFormField(
                          controller: _userIdController,
                          decoration: const InputDecoration(
                            labelText: "Target User ID",
                            hintText: "Paste user ID (e.g. 64b1f...)",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (!_isBroadcast && (value == null || value.isEmpty)) {
                              return "User ID is required for specific messages";
                            }
                            return null;
                          },
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: defaultPadding * 2),

              // Send Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendNotification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send),
                      SizedBox(width: 8),
                      Text("Post Notification", style: TextStyle(fontSize: 16)),
                    ],
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