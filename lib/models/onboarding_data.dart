import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/Onboarding/view/LoadingScreen.dart';

// Class to define the structure of a question
class OnboardingQuestion {
  final String heading;
  final IconData icon;
  final String questionText;
  final List<String> options;

  OnboardingQuestion({
    required this.heading,
    required this.icon,
    required this.questionText,
    required this.options,
  });
}

// Holds all the app's state for the onboarding flow
class OnboardingData extends ChangeNotifier {
  final PageController pageController = PageController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // --- CONTROLLERS & STATE ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String? selectedGender;

  File? skinImage;
  File? scalpImage;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  // --- DYNAMIC PAGE COUNT ---
  // 1 (Personal Details) + N (Questions) + 1 (Photo Upload)
  int get totalOnboardingPages => 1 + questions.length + 1;

  // Store answers: {0: "Option A", 1: "Option B"}
  final Map<int, String> _answers = {};
  Map<int, String> get answers => _answers;

  OnboardingData() {
    pageController.addListener(() {
      final newPage = pageController.page?.round() ?? 0;
      if (_currentPage != newPage) {
        _currentPage = newPage;
        notifyListeners();
      }
    });
  }

  // --- ACTIONS ---

  void setGender(String gender) {
    selectedGender = gender;
    notifyListeners();
  }

  void setSkinImage(File image) {
    skinImage = image;
    print("Skin image set: ${image.path}");
    notifyListeners();
  }

  void setScalpImage(File image) {
    scalpImage = image;
    print("Scalp image set: ${image.path}");
    notifyListeners();
  }

  void submitPersonalDetails() {
    if (formKey.currentState!.validate() && selectedGender != null) {
      nextPage();
    }
  }

  void selectAnswer(int questionIndex, String answer) {
    _answers[questionIndex] = answer;

    // Auto-advance
    nextPage();
    notifyListeners();
  }

  void nextPage() {
    if (_currentPage < totalOnboardingPages - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> submitPhotosAndAnalyze(BuildContext context) async {
    if (skinImage == null || scalpImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload both photos before continuing.")),
      );
      return;
    }

    print("All data collected. Navigating to Loading Screen.");
    // Pass the existing provider value to the new route
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: this,
          child: const LoadingScreen(),
        ),
      ),
    );
  }

  double get progress {
    // Return a value between 0.0 and 1.0 based on current page
    return (_currentPage + 1) / totalOnboardingPages;
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    pageController.dispose();
    super.dispose();
  }

  // --- THE FULL 41 QUESTION DATASET ---
  final List<OnboardingQuestion> questions = [
    // --- SECTION A: SKIN CHARACTERISTICS ---
    OnboardingQuestion(
      heading: "SKIN CHARACTERISTICS",
      icon: Icons.face_retouching_natural,
      questionText: "Your skin usually feels:",
      options: [
        "Dry, rough, flaky (Vata)",
        "Soft, oily, smooth (Pitta/Kapha)",
        "Thick, firm, oily (Kapha)",
      ],
    ),
    OnboardingQuestion(
      heading: "SKIN CHARACTERISTICS",
      icon: Icons.thermostat,
      questionText: "Skin temperature generally:",
      options: [
        "Cool to touch (Vata/Kapha)",
        "Warm/hot to touch (Pitta)",
      ],
    ),
    OnboardingQuestion(
      heading: "SKIN CHARACTERISTICS",
      icon: Icons.grain,
      questionText: "Size of pores:",
      options: [
        "Small / invisible (Vata)",
        "Medium / visible (Pitta)",
        "Large / prominent (Kapha)",
      ],
    ),
    OnboardingQuestion(
      heading: "SKIN CHARACTERISTICS",
      icon: Icons.water_drop,
      questionText: "Your skin becomes oily:",
      options: [
        "Rarely (Vata)",
        "Mostly T-zone or during heat (Pitta)",
        "Entire face often oily (Kapha)",
      ],
    ),
    OnboardingQuestion(
      heading: "SKIN CHARACTERISTICS",
      icon: Icons.wb_sunny,
      questionText: "Your skin reacts (redness/burning) easily to products or sunlight:",
      options: [
        "Yes, very often (Pitta)",
        "Sometimes (Vata)",
        "Rarely (Kapha)",
      ],
    ),

    // --- SECTION C: COMMON SKIN SYMPTOMS ---
    OnboardingQuestion(
      heading: "SKIN SYMPTOMS",
      icon: Icons.healing,
      questionText: "Your acne usually is:",
      options: [
        "Small, dry, blackheads/whiteheads (Vata)",
        "Red, inflamed, pus-filled (Pitta)",
        "Big, deep, cystic, slow-healing (Kapha)",
      ],
    ),
    OnboardingQuestion(
      heading: "SKIN SYMPTOMS",
      icon: Icons.blur_on,
      questionText: "Your pigmentation is:",
      options: [
        "Patchy, uneven, dry pigmented spots (Vata)",
        "Reddish-brown, heat-triggered melasma (Pitta)",
        "Dull, grayish, persistent pigmentation (Kapha)",
      ],
    ),
    OnboardingQuestion(
      heading: "SKIN SYMPTOMS",
      icon: Icons.warning_amber_rounded,
      questionText: "What type of allergy do you get?",
      options: [
        "Dry eczema, itching (Vata)",
        "Burning, redness, rashes (Pitta)",
        "Fungal, moist, sticky areas (Kapha)",
      ],
    ),
    OnboardingQuestion(
      heading: "SKIN SYMPTOMS",
      icon: Icons.visibility,
      questionText: "Under-eye issues:",
      options: [
        "Dry, wrinkled, hollow (Vata)",
        "Redness/heat (Pitta)",
        "Puffiness (Kapha)",
      ],
    ),

    // --- SECTION D: LIFESTYLE INFLUENCES ---
    OnboardingQuestion(
      heading: "LIFESTYLE",
      icon: Icons.restaurant,
      questionText: "You mostly prefer:",
      options: [
        "Dry, light, crispy foods (Vata)",
        "Spicy, sour, salty foods (Pitta)",
        "Sweet, oily, dairy foods (Kapha)",
      ],
    ),
    OnboardingQuestion(
      heading: "LIFESTYLE",
      icon: Icons.local_drink,
      questionText: "Daily water intake:",
      options: [
        "Very low (Vata)",
        "Moderate (Pitta)",
        "High (Kapha)",
      ],
    ),
    OnboardingQuestion(
      heading: "LIFESTYLE",
      icon: Icons.bedtime,
      questionText: "Sleep nature:",
      options: [
        "Disturbed, light, irregular (Vata)",
        "Moderate, occasionally disturbed (Pitta)",
        "Deep and long (Kapha)",
      ],
    ),
    OnboardingQuestion(
      heading: "LIFESTYLE",
      icon: Icons.psychology_alt,
      questionText: "Under stress, your skin:",
      options: [
        "Becomes dry or flaky (Vata)",
        "Breaks out or reddens (Pitta)",
        "Looks dull or oily (Kapha)",
      ],
    ),

    // --- PRAKRUTI QUESTIONS: BODY / PHYSICAL ---
    OnboardingQuestion(
      heading: "BODY / PHYSICAL",
      icon: Icons.accessibility_new,
      questionText: "Body size:",
      options: [
        "Vata – Slim",
        "Pitta – Medium",
        "Kapha – Large",
      ],
    ),
    OnboardingQuestion(
      heading: "BODY / PHYSICAL",
      icon: Icons.monitor_weight,
      questionText: "Body weight tendency:",
      options: [
        "Vata – Low",
        "Pitta – Medium",
        "Kapha – Overweight",
      ],
    ),
    OnboardingQuestion(
      heading: "BODY / PHYSICAL",
      icon: Icons.face,
      questionText: "General skin nature:",
      options: [
        "Vata – Thin, dry, cold, rough, darker",
        "Pitta – Smooth, slightly oily, warm, rosy/reddish",
        "Kapha – Thick, oily, cool, pale/whitish",
      ],
    ),
    OnboardingQuestion(
      heading: "BODY / PHYSICAL",
      icon: Icons.content_cut,
      questionText: "Hair texture:",
      options: [
        "Vata – Dry, brown/black, thin, brittle, knotted",
        "Pitta – Straight, oily, often light/brown/red",
        "Kapha – Thick, curly/wavy, oily, luxuriant",
      ],
    ),
    OnboardingQuestion(
      heading: "BODY / PHYSICAL",
      icon: Icons.sentiment_satisfied,
      questionText: "Teeth & gums:",
      options: [
        "Vata – Big, protruding teeth, thin gums, spaced",
        "Pitta – Medium, soft, tender gums",
        "Kapha – Strong, well-formed teeth, healthy firm gums",
      ],
    ),
    OnboardingQuestion(
      heading: "BODY / PHYSICAL",
      icon: Icons.filter_hdr,
      questionText: "Nose shape:",
      options: [
        "Vata – Uneven shape, deviated septum",
        "Pitta – Long, pointed, reddish nose-tip",
        "Kapha – Short, rounded, “button” nose",
      ],
    ),
    OnboardingQuestion(
      heading: "BODY / PHYSICAL",
      icon: Icons.remove_red_eye,
      questionText: "Eyes:",
      options: [
        "Vata – Small, sunken, dry, active, dark",
        "Pitta – Sharp, bright, sensitive to light",
        "Kapha – Big, beautiful, calm, blue/black or dark, moist",
      ],
    ),
    OnboardingQuestion(
      heading: "BODY / PHYSICAL",
      icon: Icons.pan_tool,
      questionText: "Nails:",
      options: [
        "Vata – Dry, rough, brittle, break easily",
        "Pitta – Sharp, flexible, pink, lustrous",
        "Kapha – Thick, oily, smooth, polished",
      ],
    ),
    OnboardingQuestion(
      heading: "BODY / PHYSICAL",
      icon: Icons.mood,
      questionText: "Lips:",
      options: [
        "Vata – Dry, cracked, often dark/blackish tinge",
        "Pitta – Red, inflamed, yellowish tinge",
        "Kapha – Smooth, oily, pale or whitish",
      ],
    ),
    OnboardingQuestion(
      heading: "BODY / PHYSICAL",
      icon: Icons.person,
      questionText: "Chin:",
      options: [
        "Vata – Thin, angular",
        "Pitta – Tapering",
        "Kapha – Rounded, double",
      ],
    ),
    OnboardingQuestion(
      heading: "BODY / PHYSICAL",
      icon: Icons.face_3,
      questionText: "Cheeks:",
      options: [
        "Vata – Wrinkled, sunken",
        "Pitta – Smooth, flat",
        "Kapha – Rounded, plump",
      ],
    ),
    OnboardingQuestion(
      heading: "BODY / PHYSICAL",
      icon: Icons.emoji_people,
      questionText: "Neck:",
      options: [
        "Vata – Thin, tall",
        "Pitta – Medium",
        "Kapha – Big, thick, folded",
      ],
    ),
    OnboardingQuestion(
      heading: "BODY / PHYSICAL",
      icon: Icons.fitness_center,
      questionText: "Chest:",
      options: [
        "Vata – Flat, sunken",
        "Pitta – Moderate",
        "Kapha – Broad, expanded, rounded",
      ],
    ),
    OnboardingQuestion(
      heading: "BODY / PHYSICAL",
      icon: Icons.crop_square,
      questionText: "Belly / Abdomen:",
      options: [
        "Vata – Thin, flat, sunken",
        "Pitta – Moderate",
        "Kapha – Big, pot-bellied",
      ],
    ),
    OnboardingQuestion(
      heading: "BODY / PHYSICAL",
      icon: Icons.radio_button_checked,
      questionText: "Navel:",
      options: [
        "Vata – Small, irregular, sometimes herniated",
        "Pitta – Oval, superficial",
        "Kapha – Big, deep, round, stretched",
      ],
    ),
    OnboardingQuestion(
      heading: "BODY / PHYSICAL",
      icon: Icons.accessibility,
      questionText: "Hips:",
      options: [
        "Vata – Slender, thin",
        "Pitta – Moderate",
        "Kapha – Heavy, big",
      ],
    ),
    OnboardingQuestion(
      heading: "BODY / PHYSICAL",
      icon: Icons.directions_walk,
      questionText: "Joints:",
      options: [
        "Vata – Cold, cracking sounds",
        "Pitta – Moderate, normal",
        "Kapha – Large, well-lubricated",
      ],
    ),
    OnboardingQuestion(
      heading: "BODY / PHYSICAL",
      icon: Icons.restaurant_menu,
      questionText: "Appetite:",
      options: [
        "Vata – Irregular, scanty, sometimes forget to eat",
        "Pitta – Strong appetite, gets irritable if skips food",
        "Kapha – Slow but steady, can easily skip meals",
      ],
    ),

    // --- PRAKRUTI QUESTIONS: FUNCTIONAL / MENTAL ---
    OnboardingQuestion(
      heading: "FUNCTIONAL / MENTAL",
      icon: Icons.spa,
      questionText: "Digestion:",
      options: [
        "Vata – Irregular, forms gas, bloating",
        "Pitta – Quick, strong, may cause burning",
        "Kapha – Slow, heavy, tendency to form mucus",
      ],
    ),
    OnboardingQuestion(
      heading: "FUNCTIONAL / MENTAL",
      icon: Icons.soup_kitchen,
      questionText: "Usual taste preference:",
      options: [
        "Vata – Sweet, sour, salty",
        "Pitta – Sweet, bitter, astringent",
        "Kapha – Bitter, pungent, astringent",
      ],
    ),
    OnboardingQuestion(
      heading: "FUNCTIONAL / MENTAL",
      icon: Icons.water_drop_outlined,
      questionText: "Thirst:",
      options: [
        "Vata – Variable, sometimes forgets to drink",
        "Pitta – Strong, frequent thirst (surplus)",
        "Kapha – Low thirst, drinks little water",
      ],
    ),
    OnboardingQuestion(
      heading: "FUNCTIONAL / MENTAL",
      icon: Icons.delete_outline,
      questionText: "Bowel habit:",
      options: [
        "Vata – Dry, hard, constipated, irregular",
        "Pitta – Loose, sometimes burning",
        "Kapha – Thick, oily, sluggish",
      ],
    ),
    OnboardingQuestion(
      heading: "FUNCTIONAL / MENTAL",
      icon: Icons.run_circle,
      questionText: "Physical activity pattern:",
      options: [
        "Vata – Hyperactive, restless, fidgety",
        "Pitta – Moderate, purposeful, likes achievement",
        "Kapha – Sedentary, moves slowly, resists exercise",
      ],
    ),
    OnboardingQuestion(
      heading: "FUNCTIONAL / MENTAL",
      icon: Icons.psychology,
      questionText: "Mental activity:",
      options: [
        "Vata – Always active, too many thoughts",
        "Pitta – Focused, moderate activity",
        "Kapha – Dull, slow, lethargic mind",
      ],
    ),
    OnboardingQuestion(
      heading: "FUNCTIONAL / MENTAL",
      icon: Icons.mood_bad,
      questionText: "Dominant emotions:",
      options: [
        "Vata – Anxiety, fear, uncertainty",
        "Pitta – Anger, hate, jealousy, strong determination",
        "Kapha – Calm, loving, attached, possessive",
      ],
    ),
    OnboardingQuestion(
      heading: "FUNCTIONAL / MENTAL",
      icon: Icons.self_improvement,
      questionText: "Faith / belief style:",
      options: [
        "Vata – Variable, changes ideas often",
        "Pitta – Intense, sometimes extremist",
        "Kapha – Consistent, deep, steady faith",
      ],
    ),
    OnboardingQuestion(
      heading: "FUNCTIONAL / MENTAL",
      icon: Icons.lightbulb,
      questionText: "Intellect style:",
      options: [
        "Vata – Quick grasp but forgets/makes mistakes",
        "Pitta – Sharp, accurate, logical response",
        "Kapha – Slow but thorough and exact",
      ],
    ),
    OnboardingQuestion(
      heading: "FUNCTIONAL / MENTAL",
      icon: Icons.history_edu,
      questionText: "Memory:",
      options: [
        "Vata – Remembers recent things, forgets old events",
        "Pitta – Distinct, clear memory",
        "Kapha – Slow to learn but retains for long time",
      ],
    ),
  ];
}