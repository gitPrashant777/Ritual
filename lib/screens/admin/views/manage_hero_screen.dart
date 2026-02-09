import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shop/constants.dart';
import 'package:shop/services/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageHeroScreen extends StatefulWidget {
  const ManageHeroScreen({super.key});

  @override
  State<ManageHeroScreen> createState() => _ManageHeroScreenState();
}

class _ManageHeroScreenState extends State<ManageHeroScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Updated Locations
  String _selectedLocation = 'Home Carousel';
  final List<String> _bannerLocations = [
    'Home Carousel',
    'Home Middle Banner',
    'Home Bottom Banner',
    'Sale Page Header'
  ];
  final Color _bgColor = const Color(0xFFF6EFE3); // Cream/Beige
  final Color _primaryColor = const Color(0xFF0B3323); // Dark Green
  final Color _whiteColor = Colors.white;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error picking image: $e")));
    }
  }

  Future<void> _saveHeroSection() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a banner image")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? uploadedUrl;
      final cloudResponse = await CloudinaryService.uploadImage(
        _selectedImage!,
        folder: 'banners',
        imageType: 'banner',
      );
      uploadedUrl = cloudResponse.secureUrl;

      if (uploadedUrl == null) throw Exception("Image upload failed");

      // Save to Firebase with 'type'
      await FirebaseFirestore.instance.collection('banners').add({
        'imageUrl': uploadedUrl,
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'price': _priceController.text.isNotEmpty ? double.tryParse(_priceController.text) : null,
        'type': _selectedLocation, // <--- Important: Saves the location
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Banner published successfully!"), backgroundColor: successColor),
        );
        setState(() {
          _selectedImage = null;
          _titleController.clear();
          _subtitleController.clear();
          _priceController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Banners", style: TextStyle(color: _whiteColor)),
        backgroundColor: _primaryColor, // ✅ #0b3323
        foregroundColor: _whiteColor, // Makes Back Arrow White
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,color: Colors.white,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview List
            const Text("Active Banners", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 140,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('banners').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  if (snapshot.data!.docs.isEmpty) return const Text("No active banners");

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return Container(
                        width: 180,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(data['imageUrl'] ?? ''),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              bottom: 0, left: 0, right: 0,
                              child: Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.all(4),
                                child: Text(data['type'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                              ),
                            ),
                            Positioned(
                              top: 4, right: 4,
                              child: InkWell(
                                onTap: () => FirebaseFirestore.instance.collection('banners').doc(doc.id).delete(),
                                child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.delete, size: 14, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 40),

            // Upload Form
            const Text("Upload New Banner", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: defaultPadding),

            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null,
                ),
                child: _selectedImage == null
                    ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey), Text("Tap to select")]))
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLocation,
              decoration: const InputDecoration(labelText: "Banner Location", border: OutlineInputBorder()),
              items: _bannerLocations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
              onChanged: (val) => setState(() => _selectedLocation = val!),
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: "Title (Optional)", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextFormField(controller: _subtitleController, decoration: const InputDecoration(labelText: "Subtitle (Optional)", border: OutlineInputBorder())),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveHeroSection,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Publish Banner"),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}