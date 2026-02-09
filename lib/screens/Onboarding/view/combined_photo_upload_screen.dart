import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../models/onboarding_data.dart';

class CombinedPhotoUploadScreen extends StatefulWidget {
  const CombinedPhotoUploadScreen({super.key});

  @override
  State<CombinedPhotoUploadScreen> createState() =>
      _CombinedPhotoUploadScreenState();
}

class _CombinedPhotoUploadScreenState extends State<CombinedPhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  static const brandPrimary = Color(0xFF0b3323);
  static const brandSecondary = Color(0xFF0b3323);

  Future<void> _pickImage(ImageSource source, String type) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      HapticFeedback.lightImpact();
      final data = Provider.of<OnboardingData>(context, listen: false);
      if (type == 'skin') {
        data.setSkinImage(File(pickedFile.path));
      } else if (type == 'scalp') {
        data.setScalpImage(File(pickedFile.path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<OnboardingData>(context);
    final bool canSubmit = data.skinImage != null && data.scalpImage != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 32.0 : 20.0,
        vertical: isTablet ? 24.0 : 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: isTablet ? 24 : 16),

          // Header Section with brand color
          Container(
            padding: EdgeInsets.all(isTablet ? 14 : 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  brandPrimary.withOpacity(0.15),
                  brandSecondary.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.camera_alt_rounded,
              color: brandPrimary,
              size: isTablet ? 42 : 36,
            ),
          ),

          SizedBox(height: isTablet ? 24 : 20),

          // Title with brand gradient
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [brandPrimary, brandSecondary],
            ).createShader(bounds),
            child: Text(
              "AI PHOTO ANALYSIS",
              style: TextStyle(
                fontSize: isTablet ? 30 : 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),

          SizedBox(height: isTablet ? 12 : 8),

          // Description
          Text(
            "Upload clear photos for the most accurate AI analysis and kit recommendation.",
            style: TextStyle(
              fontSize: isTablet ? 17 : 16,
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.5,
            ),
          ),

          SizedBox(height: isTablet ? 40 : 32),

          // Skin Photo Upload
          _buildUploadSection(
            context: context,
            title: "Skin Photo Upload",
            description: "Detects acne, pigmentation, and fine lines.",
            imageFile: data.skinImage,
            onPickGallery: () => _pickImage(ImageSource.gallery, 'skin'),
            onPickCamera: () => _pickImage(ImageSource.camera, 'skin'),
            isDark: isDark,
            isTablet: isTablet,
          ),

          SizedBox(height: isTablet ? 28 : 24),

          // Scalp Photo Upload
          _buildUploadSection(
            context: context,
            title: "Hair/Scalp Photo Upload",
            description: "Detects thinning, dryness, and dandruff.",
            imageFile: data.scalpImage,
            onPickGallery: () => _pickImage(ImageSource.gallery, 'scalp'),
            onPickCamera: () => _pickImage(ImageSource.camera, 'scalp'),
            isDark: isDark,
            isTablet: isTablet,
          ),

          SizedBox(height: isTablet ? 16 : 18),

          // Submit Button with brand gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: isTablet ? 60 : 56,
            decoration: BoxDecoration(
              gradient: canSubmit
                  ? const LinearGradient(
                colors: [brandPrimary, brandSecondary],
              )
                  : null,
              color: canSubmit ? null : Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
              boxShadow: canSubmit
                  ? [
                BoxShadow(
                  color: brandPrimary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canSubmit ? () => data.submitPhotosAndAnalyze(context) : null,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Submit & Analyze",
                        style: TextStyle(
                          color: canSubmit ? Colors.white : Colors.grey[500],
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 17 : 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (canSubmit) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: isTablet ? 22 : 20,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: isTablet ? 64: 60),

        ],
      ),
    );
  }

  Widget _buildUploadSection({
    required BuildContext context,
    required String title,
    required String description,
    File? imageFile,
    required VoidCallback onPickGallery,
    required VoidCallback onPickCamera,
    required bool isDark,
    required bool isTablet,
  }) {
    final hasImage = imageFile != null;

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasImage
              ? brandPrimary.withOpacity(0.3)
              : isDark
              ? Colors.white12
              : Colors.grey[200]!,
          width: hasImage ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 10 : 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      brandPrimary.withOpacity(0.15),
                      brandSecondary.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo_camera_rounded,
                  color: brandPrimary,
                  size: isTablet ? 22 : 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isTablet ? 19 : 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: isTablet ? 15 : 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: isTablet ? 20 : 16),

          // Image Preview with brand border
          Center(
            child: Container(
              width: isTablet ? 180 : 150,
              height: isTablet ? 180 : 150,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasImage
                      ? brandPrimary
                      : isDark
                      ? Colors.white12
                      : Colors.grey[300]!,
                  width: hasImage ? 2 : 1,
                ),
              ),
              child: hasImage
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imageFile!,
                  fit: BoxFit.cover,
                ),
              )
                  : Icon(
                Icons.add_photo_alternate_outlined,
                size: isTablet ? 60 : 50,
                color: isDark ? Colors.white30 : Colors.grey[400],
              ),
            ),
          ),

          SizedBox(height: isTablet ? 20 : 16),

          // Action Buttons with brand colors
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    Icons.photo_library_outlined,
                    size: isTablet ? 20 : 18,
                  ),
                  label: Text(
                    "Gallery",
                    style: TextStyle(fontSize: isTablet ? 15 : 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brandPrimary,
                    side: BorderSide(color: brandPrimary.withOpacity(0.3)),
                    padding: EdgeInsets.symmetric(
                      vertical: isTablet ? 14 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onPickGallery,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    size: isTablet ? 20 : 18,
                  ),
                  label: Text(
                    "Camera",
                    style: TextStyle(fontSize: isTablet ? 15 : 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandPrimary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isTablet ? 14 : 12,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onPickCamera,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
