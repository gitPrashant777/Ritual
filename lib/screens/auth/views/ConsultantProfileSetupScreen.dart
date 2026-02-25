// consultant_profile_setup_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop/screens/Consultation/ConsultantDashboardScreen.dart';

import '../../../services/cloudinary_service.dart';

class ConsultantProfileSetupScreen extends StatefulWidget {
  final String uid;

  const ConsultantProfileSetupScreen({super.key, required this.uid});

  @override
  State<ConsultantProfileSetupScreen> createState() => _ConsultantProfileSetupScreenState();
}

class _ConsultantProfileSetupScreenState extends State<ConsultantProfileSetupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _consultationFeeController = TextEditingController();
  // --- 1. ADD PHONE CONTROLLER ---
  final TextEditingController _phoneController = TextEditingController();

  File? _profileImage;
  File? _certificateFile;
  bool _isLoading = false;
  String _selectedExperienceLevel = 'Junior (0-5 years)';

  static const brandPrimary = Color(0xFF0b3323);

  final List<String> _experienceLevels = [
    'Junior (0-5 years)',
    'Mid-level (5-10 years)',
    'Senior (10-20 years)',
    'Expert (20+ years)',
  ];

  // --- 2. ADD initState TO PRE-FILL DATA ---
  @override
  void initState() {
    super.initState();
    _loadConsultantData();
  }

  Future<void> _loadConsultantData() async {
    try {
      final doc = await _firestore.collection('consultants').doc(widget.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            // Pre-fill all fields from document
            _phoneController.text = data['phone'] ?? '';
            _specialtyController.text = data['specialty'] ?? '';
            _experienceController.text = data['experienceYears'] ?? '';
            _qualificationController.text = data['qualification'] ?? '';
            _licenseController.text = data['licenseNumber'] ?? '';
            _aboutController.text = data['about'] ?? '';
            _consultationFeeController.text = (data['consultationFee'] ?? 0).toString();
            _selectedExperienceLevel = data['experienceLevel'] ?? 'Junior (0-5 years)';
          });
        }
      }
    } catch (e) {
      _showSnackBar('Error loading existing data: ${e.toString()}', isError: true);
    }
  }
  // ------------------------------------

  @override
  void dispose() {
    _specialtyController.dispose();
    _experienceController.dispose();
    _qualificationController.dispose();
    _licenseController.dispose();
    _aboutController.dispose();
    _consultationFeeController.dispose();
    _phoneController.dispose(); // --- 3. ADD TO dispose ---
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image != null) {
        setState(() => _profileImage = File(image.path));
      }
    } catch (e) {
      _showSnackBar('Error picking image: ${e.toString()}', isError: true);
    }
  }

  Future<void> _pickCertificate() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (file != null) {
        setState(() => _certificateFile = File(file.path));
      }
    } catch (e) {
      _showSnackBar('Error picking certificate: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : brandPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_profileImage == null) {
        // Check if there's already an image URL from Firestore
        final doc = await _firestore.collection('consultants').doc(widget.uid).get();
        if (doc.data()?['profileImageUrl'] == null) {
          _showSnackBar('Please upload a profile photo', isError: true);
          return;
        }
      }

      if (_certificateFile == null) {
        // Check if there's already a certificate URL
        final doc = await _firestore.collection('consultants').doc(widget.uid).get();
        if (doc.data()?['certificateUrl'] == null) {
          _showSnackBar('Please upload your medical certificate', isError: true);
          return;
        }
      }

      setState(() => _isLoading = true);

      try {
        String? profileImageUrl;
        String? certificateUrl;

        // Only upload profile image if a new one was picked
        if (_profileImage != null) {
          _showSnackBar('Uploading profile image...', isError: false);
          final profileImageResponse = await CloudinaryService.uploadImage(
            _profileImage!,
            folder: 'consultants/${widget.uid}/profile',
            imageType: 'user',
          );
          profileImageUrl = profileImageResponse.secureUrl;
        }

        // Only upload certificate if a new one was picked
        if (_certificateFile != null) {
          _showSnackBar('Uploading certificate...', isError: false);
          final certificateResponse = await CloudinaryService.uploadImage(
            _certificateFile!,
            folder: 'consultants/${widget.uid}/certificate',
            imageType: 'user',
          );
          certificateUrl = certificateResponse.secureUrl;
        }

        // --- 4. ADD PHONE TO UPDATE MAP ---
        final Map<String, dynamic> updateData = {
          'specialty': _specialtyController.text.trim(),
          'experienceYears': _experienceController.text.trim(),
          'experienceLevel': _selectedExperienceLevel,
          'qualification': _qualificationController.text.trim(),
          'licenseNumber': _licenseController.text.trim(),
          'phone': _phoneController.text.trim(), // <-- ADDED
          'about': _aboutController.text.trim(),
          'consultationFee': double.tryParse(_consultationFeeController.text) ?? 0,
          'isProfileComplete': true,
          'profileCompletedAt': FieldValue.serverTimestamp(),
        };

        // Add image URLs only if they were newly uploaded
        if (profileImageUrl != null) {
          updateData['profileImageUrl'] = profileImageUrl;
        }
        if (certificateUrl != null) {
          updateData['certificateUrl'] = certificateUrl;
        }

        // Use .update() to merge data
        await _firestore.collection('consultants').doc(widget.uid).update(updateData);
        // ----------------------------------

        if (mounted) {
          _showSnackBar('Profile submitted successfully!', isError: false);

          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ConsultantDashboardScreen(
                ),
              ),
            );

          }
        }
      } catch (e) {
        if (mounted) {
          final message = e is CloudinaryException ? e.message : e.toString();
          _showSnackBar('Error: $message', isError: true);
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
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        elevation: 0,
        title: Text(
          'Complete Your Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : brandPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: brandPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: brandPrimary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: brandPrimary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your profile will be verified by our team before approval',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : brandPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Profile Photo Section
              Center(
                child: Column(
                  children: [
                    Text(
                      'PROFILE PHOTO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _showImageSourceDialog(),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _profileImage != null
                                ? brandPrimary
                                : (isDark ? Colors.white12 : Colors.grey[300]!),
                            width: 2,
                          ),
                        ),
                        child: _profileImage != null
                            ? ClipOval(
                          child: Image.file(_profileImage!, fit: BoxFit.cover, width: 120, height: 120),
                        )
                            : Icon(
                          Icons.add_a_photo,
                          size: 40,
                          color: isDark ? Colors.white30 : Colors.grey[400],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _showImageSourceDialog(),
                      child: const Text('Upload Photo', style: TextStyle(color: brandPrimary)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Specialty
              _buildTextField(
                controller: _specialtyController,
                label: 'SPECIALTY',
                hint: 'e.g., Dermatologist, General Physician',
                isDark: isDark,
              ),

              const SizedBox(height: 20),

              // Experience Level Dropdown
              DropdownButtonFormField<String>(
                value: _selectedExperienceLevel,
                decoration: _inputDecoration('EXPERIENCE LEVEL', isDark),
                dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                items: _experienceLevels.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedExperienceLevel = value!);
                },
              ),

              const SizedBox(height: 20),

              // Years of Experience
              _buildTextField(
                controller: _experienceController,
                label: 'YEARS OF EXPERIENCE',
                hint: 'e.g., 5',
                isDark: isDark,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),

              // Qualification
              _buildTextField(
                controller: _qualificationController,
                label: 'QUALIFICATION',
                hint: 'e.g., MBBS, MD',
                isDark: isDark,
              ),

              const SizedBox(height: 20),

              // License Number
              _buildTextField(
                controller: _licenseController,
                label: 'MEDICAL LICENSE NUMBER',
                hint: 'Your registered license number',
                isDark: isDark,
              ),

              const SizedBox(height: 20),

              // --- 5. ADD PHONE TEXT FIELD ---
              _buildTextField(
                controller: _phoneController,
                label: 'PHONE NUMBER',
                hint: '+91 9999999999',
                isDark: isDark,
                keyboardType: TextInputType.phone,
              ),
              // -----------------------------

              const SizedBox(height: 20),

              // Consultation Fee
              _buildTextField(
                controller: _consultationFeeController,
                label: 'CONSULTATION FEE (₹)',
                hint: 'e.g., 500',
                isDark: isDark,
                keyboardType: TextInputType.number,
                prefixText: '₹ ',
              ),

              const SizedBox(height: 20),

              // About
              TextFormField(
                controller: _aboutController,
                maxLines: 4,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: _inputDecoration('ABOUT YOU', isDark).copyWith(
                  hintText: 'Brief description about your practice...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please write about yourself';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Certificate Upload
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _certificateFile != null
                        ? brandPrimary
                        : (isDark ? Colors.white12 : Colors.grey[300]!),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MEDICAL CERTIFICATE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_certificateFile != null)
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: brandPrimary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Certificate uploaded',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Upload your medical certificate for verification',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickCertificate,
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: Text(_certificateFile != null ? 'Change File' : 'Upload Certificate'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: brandPrimary,
                          side: const BorderSide(color: brandPrimary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProfile,
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'SUBMIT FOR VERIFICATION',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: _inputDecoration(label, isDark).copyWith(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
        prefixText: prefixText,
        prefixStyle: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (label == 'PHONE NUMBER' && value.length < 10) {
          return 'Please enter a valid phone number';
        }
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        color: isDark ? Colors.white60 : Colors.black54,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: brandPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}