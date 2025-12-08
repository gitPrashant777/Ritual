import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shop/models/user_session.dart';
import '../../../constants.dart'; // Ensure constants.dart is imported
import '../../../entry_point.dart';
import '../../../models/onboarding_data.dart';
// import '../Components/gender_selection_card.dart'; // Integrated directly below

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    try {
      final data = Provider.of<OnboardingData>(context, listen: false);
      final session = await UserSession.getUserSession();

      if (session != null && session['userData'] != null) {
        final userName = session['userData']['name'] as String?;

        if (userName != null && userName.isNotEmpty) {
          data.nameController.text = userName;
          data.notifyListeners();
        }
      }
    } catch (e) {
      print("Error loading user data for onboarding: $e");
    }
  }

  void _navigateToDashboard(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const EntryPoint()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<OnboardingData>(context);
    // Validation logic
    final bool isContinueEnabled = data.nameController.text.isNotEmpty &&
        data.ageController.text.isNotEmpty &&
        data.selectedGender != null;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _navigateToDashboard(context);
      },
      child: Scaffold(
        // RITUAL THEME: Beige Background
        backgroundColor: kRitualBeige,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: data.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Header
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // RITUAL THEME: Accent Line (Dark Green)
                          Container(
                            width: 60,
                            height: 4,
                            decoration: BoxDecoration(
                              color: kPrimaryColor, // Dark Green
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 15),
                          // RITUAL THEME: Serif Heading
                          const Text(
                            "Let's get started",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFamily: kSerifFont, // Playfair Display
                              color: kPrimaryColor, // Dark Green
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // RITUAL THEME: Sans Serif Body
                          const Text(
                            "We need a few details to kickstart your personalized beauty journey",
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: kSansSerifFont, // Montserrat
                              color: blackColor60, // Muted Green-Grey
                              height: 1.5,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Full Name Field
                      _buildFieldLabel("Full Name"),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: data.nameController,
                        hint: "Enter your full name",
                        icon: Icons.person_outline_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your name";
                          }
                          return null;
                        },
                        onChanged: (_) => data.notifyListeners(),
                      ),

                      const SizedBox(height: 24),

                      // Age Field
                      _buildFieldLabel("Age"),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: data.ageController,
                        hint: "Enter your age",
                        icon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                        helperText: "Age must be between 18 to 80 years",
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "Please enter your age";
                          final age = int.tryParse(value);
                          if (age == null) return "Please enter a valid number";
                          if (age < 18 || age > 80)
                            return "Age must be between 18 and 80";
                          return null;
                        },
                        onChanged: (_) => data.notifyListeners(),
                      ),

                      const SizedBox(height: 32),

                      // Gender Selection
                      _buildFieldLabel("Select your gender"),
                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: _buildModernGenderCard(
                              label: "Male",
                              icon: Icons.male_rounded,
                              isSelected: data.selectedGender == "Male",
                              onTap: () => data.setGender("Male"),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildModernGenderCard(
                              label: "Female",
                              icon: Icons.female_rounded,
                              isSelected: data.selectedGender == "Female",
                              onTap: () => data.setGender("Female"),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 50),

                      // Continue Button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          // RITUAL THEME: Solid Dark Green for primary action
                          color: isContinueEnabled
                              ? kPrimaryColor
                              : kLightGreen, // Disabled state is Light Green
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isContinueEnabled
                              ? [
                            BoxShadow(
                              color: kPrimaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ]
                              : [],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isContinueEnabled
                                ? data.submitPersonalDetails
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "CONTINUE",
                                    style: TextStyle(
                                      color: isContinueEnabled
                                          ? kRitualBeige
                                          : kPrimaryColor.withOpacity(0.5),
                                      fontWeight: FontWeight.bold,
                                      fontFamily: kSansSerifFont,
                                      fontSize: 16,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  if (isContinueEnabled) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: kRitualBeige,
                                      size: 20,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Privacy note
                      const Center(
                        child: Text(
                          "Your data is secure and private",
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: kSansSerifFont,
                            color: blackColor40,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: kSansSerifFont,
        color: kPrimaryColor, // Dark Green
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? helperText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 16,
        color: kPrimaryColor, // Dark Green Text
        fontFamily: kSansSerifFont,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: kPrimaryColor,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: blackColor40,
          fontFamily: kSansSerifFont,
          fontSize: 15,
        ),
        helperText: helperText,
        helperStyle: const TextStyle(
          color: blackColor60,
          fontSize: 12,
        ),
        // RITUAL THEME: Light Green Icon Background
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kLightGreen, // Soft Sage
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: kPrimaryColor, // Dark Green Icon
            size: 20,
          ),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        filled: true,
        fillColor: Colors.white, // White cards on Beige BG look clean
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none, // Clean look
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.transparent, // Cleaner on beige
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: kPrimaryColor, // Dark Green Highlight
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildModernGenderCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              // RITUAL THEME: Dark Green for Selected, White for unselected
              color: isSelected ? kPrimaryColor : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : Colors.transparent, // Removed grey borders for cleaner look
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: kPrimaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
                  : [
                BoxShadow(
                  color: kPrimaryColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // RITUAL THEME: Icon BG logic
                    color: isSelected
                        ? Colors.white.withOpacity(0.1) // Subtle on dark
                        : kLightGreen, // Sage on light
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    // RITUAL THEME: Icon Color
                    color: isSelected ? kRitualBeige : kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: kSansSerifFont,
                    color: isSelected
                        ? kRitualBeige
                        : kPrimaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isSelected ? 24 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: kRitualBeige,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}