import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/home/views/home_screen.dart';

import '../../../models/onboarding_data.dart';
import '../../../route/route_constants.dart';
import 'PersonalDetailsScreen.dart';
import 'combined_photo_upload_screen.dart';
import 'onboarding_question_screen.dart';

class OnboardingFlowManager extends StatefulWidget {
  const OnboardingFlowManager({super.key});

  @override
  State<OnboardingFlowManager> createState() => _OnboardingFlowManagerState();
}

class _OnboardingFlowManagerState extends State<OnboardingFlowManager> {
  // --- COLOR RITUAL ---
  static const brandPrimary = Color(0xFF0b3323); // Deep Green
  static const creamColor = Color(0xFFf6efe3);   // Cream BG
  static const lightGreen = Color(0xFF81C784);   // Light Green Accent
  Future<bool> _onWillPop(BuildContext context, OnboardingData data) async {
    if (data.currentPage == 0) {

      Navigator.pushNamedAndRemoveUntil(context, entryPointScreenRoute, (route) => false);
      return false;
    } else {
      data.previousPage();
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Theme Variables
    final backgroundColor = isDark ? const Color(0xFF0A0A0A) : creamColor;
    final iconColor = isDark ? Colors.white : brandPrimary;

    // Container background for back/close buttons
    final buttonBgColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.6); // White on Cream looks clean

    return ChangeNotifierProvider(
      create: (context) => OnboardingData(),
      child: Consumer<OnboardingData>(
        builder: (context, data, child) {
          return PopScope(
            canPop: data.currentPage == 0,
            onPopInvoked: (didPop) async {
              if (!didPop && data.currentPage > 0) {
                data.previousPage();
              }
            },
            child: Scaffold(
              backgroundColor: backgroundColor,
              appBar: AppBar(
                backgroundColor: backgroundColor,
                elevation: 0,
                toolbarHeight: isTablet ? 70 : 60,
                leading: Container(
                  margin: EdgeInsets.all(isTablet ? 12 : 8),
                  decoration: BoxDecoration(
                    color: buttonBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: iconColor,
                      size: isTablet ? 26 : 24,
                    ),
                    onPressed: () {
                      if (data.currentPage == 0) {
                        Navigator.of(context).pop();
                      } else {
                        data.previousPage();
                      }
                    },
                  ),
                ),
                centerTitle: true,
                title: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 18 : 14,
                    vertical: isTablet ? 10 : 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [brandPrimary, Color(0xFF1B5E20)], // Green Gradient
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Step ${data.currentPage + 1}/${data.totalOnboardingPages}',
                    style: TextStyle(
                      color: creamColor, // Text color on the pill
                      fontSize: isTablet ? 15 : 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                actions: [
                  Container(
                    margin: EdgeInsets.all(isTablet ? 12 : 8),
                    decoration: BoxDecoration(
                      color: buttonBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: iconColor,
                        size: isTablet ? 26 : 24,
                      ),
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          entryPointScreenRoute, // Replace with your actual Home/Dashboard route constant
                              (route) => false,
                        );
                      },
                    ),
                  ),
                ],
                bottom: data.currentPage > 0
                    ? PreferredSize(
                  preferredSize: Size.fromHeight(isTablet ? 12 : 10),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24 : 16,
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: data.progress,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.1)
                                : brandPrimary.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              brandPrimary,
                            ),
                            minHeight: isTablet ? 6 : 5,
                          ),
                        ),
                        SizedBox(height: isTablet ? 6 : 4),
                      ],
                    ),
                  ),
                )
                    : PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: Container(height: 4),
                ),
              ),
              body: PageView.builder(
                controller: data.pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.totalOnboardingPages,
                onPageChanged: (index) {
                  HapticFeedback.lightImpact();
                },
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const PersonalDetailsScreen();
                  }

                  if (index > 0 && index <= data.questions.length) {
                    return OnboardingQuestionScreen(
                      questionIndex: index - 1,
                    );
                  }

                  if (index == data.totalOnboardingPages - 1) {
                    return const CombinedPhotoUploadScreen();
                  }

                  return Container(
                    color: backgroundColor,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: brandPrimary,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}