import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Your Color Ritual
const Color bgColor = Color(0xFFF6EFE3);
const Color primaryDark = Color(0xFF0B3323);
const Color accentGreen = Color(0xFF81C784); // Light Green
const Color lightGreenBg = Color(0xFFE8F5E9);

class VerifyDoctorsScreen extends StatelessWidget {
  const VerifyDoctorsScreen({super.key});

  Future<void> _updateDoctorStatus(BuildContext context, String uid, bool approve) async {
    try {
      await FirebaseFirestore.instance.collection('consultants').doc(uid).update({
        'isVerified': approve,
        'verificationStatus': approve ? 'approved' : 'rejected',
        'isProfileComplete': approve ? true : false,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Doctor Verified!' : 'Doctor Rejected'),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Verify Doctors", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Added filter directly in the query to make "isEmpty" check accurate
        stream: FirebaseFirestore.instance
            .collection('consultants')
            .where('isProfileComplete', isEqualTo: true)
            .where('isVerified', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryDark));
          }

          // This handles the "No Doctors" UI
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final doctors = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doc = doctors[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: lightGreenBg,
                            backgroundImage: data['profileImageUrl'] != null
                                ? NetworkImage(data['profileImageUrl'])
                                : null,
                            child: data['profileImageUrl'] == null
                                ? const Icon(Icons.person, color: primaryDark)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? 'Dr. Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: primaryDark,
                                  ),
                                ),
                                Text(
                                  "${data['specialty']} • ${data['experienceYears']} Yrs Exp",
                                  style: TextStyle(color: primaryDark.withOpacity(0.7)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30, thickness: 1),

                      _infoRow("License", data['licenseNumber'] ?? 'N/A'),
                      _infoRow("Phone", data['phone'] ?? 'N/A'),
                      _infoRow("Qualification", data['qualification'] ?? 'N/A'),

                      const SizedBox(height: 12),
                      const Text("Certificate Preview",
                          style: TextStyle(fontWeight: FontWeight.bold, color: primaryDark)),
                      const SizedBox(height: 8),

                      if (data['certificateUrl'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            data['certificateUrl'],
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Text("Could not load image")),
                          ),
                        )
                      else
                        const Text("No certificate uploaded", style: TextStyle(color: Colors.redAccent)),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => _updateDoctorStatus(context, doc.id, false),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text("Reject"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateDoctorStatus(context, doc.id, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentGreen,
                                foregroundColor: primaryDark,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Approve Doctor", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Beautiful Empty State UI
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 80, color: primaryDark.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text(
            "All Caught Up!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryDark),
          ),
          const SizedBox(height: 8),
          Text(
            "No pending doctor verifications found.",
            style: TextStyle(color: primaryDark.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
              width: 110,
              child: Text(label, style: TextStyle(color: primaryDark.withOpacity(0.5), fontWeight: FontWeight.w600))
          ),
          Expanded(child: Text(value, style: const TextStyle(color: primaryDark, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}