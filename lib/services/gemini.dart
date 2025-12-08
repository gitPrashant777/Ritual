// lib/services/gemini_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// Import your models
import '../models/assessment_report.dart';
import '../models/onboarding_data.dart';

class GeminiService {
  // Use the v1beta endpoint to access JSON mode
  static const String baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/";

  // !! WARNING !! You must delete this key and use dotenv
  // This key is visible to everyone.
  final apiKey = "xyz";

  // --- THIS IS THE CORE FUNCTION ---
  Future<AssessmentReport> getAssessmentFromGemini(OnboardingData data) async {
    // 1. Build the Text Prompt
    final prompt = _buildPrompt(data);

    // 2. Prepare Image Data (Base64 Encode)
    final skinImageBytes = await data.skinImage!.readAsBytes();
    final skinBase64 = base64Encode(skinImageBytes);

    final scalpImageBytes = await data.scalpImage!.readAsBytes();
    final scalpBase64 = base64Encode(scalpImageBytes);

    // 3. Build the HTTP Request Body
    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {'mime_type': 'image/jpeg', 'data': skinBase64},
            },
            {
              'inline_data': {'mime_type': 'image/jpeg', 'data': scalpBase64},
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.4, // Increased to 0.4 for more dynamic/specific output
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 8192,
        'responseMimeType': "application/json", // Force JSON output
      },
      // Safety Settings
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
      ],
    };

    // 4. Call the API
    try {
      // KEEPING YOUR EXACT MODEL: gemini-2.0-flash
      final url = Uri.parse(
          baseUrl + "gemini-2.0-flash:generateContent?key=$apiKey");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      // 5. Parse the Response
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final responseData = json.decode(response.body);

        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {

          String jsonString =
              responseData['candidates'][0]['content']['parts'][0]['text'] ?? '{}';

          // 6. Decode the JSON string into a Map
          final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

          // 7. Use the 'fromJson' constructor to create your object
          // The AssessmentReport.fromJson (if updated) will handle isValidImage check
          return AssessmentReport.fromJson(jsonMap);

        } else {
          // Handle cases where API was blocked
          if (responseData['promptFeedback'] != null) {
            final feedback = responseData['promptFeedback'];
            if (feedback['blockReason'] != null) {
              throw Exception('API Blocked: ${feedback['blockReason']}');
            }
          }
          throw Exception('Invalid response format from Gemini API');
        }
      } else {
        // Handle API errors
        final errorData =
        response.body.isNotEmpty ? json.decode(response.body) : {};
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        throw Exception('API Error (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      print("Error in getAssessmentFromGemini: $e");
      rethrow;
    }
  }

  // --- HELPER: Builds the text prompt for the AI ---
  String _buildPrompt(OnboardingData data) {
    // Convert the answers Map into a readable string
    final answersString = data.answers.entries.map((entry) {
      final question = data.questions[entry.key].questionText;
      final answer = entry.value;
      return "Q: $question\nA: $answer";
    }).join("\n\n");

    // Updated Prompt with IMAGE VALIDATION LOGIC
    return """
    You are an expert AI dermatologist and trichologist for a health brand.
    A user has provided their personal details, images, and answers to a health questionnaire.
    
    The user's images (skin and scalp) are provided as image inputs.
    
    The user's details are:
    - Name: ${data.nameController.text}
    - Age: ${data.ageController.text}
    - Gender: ${data.selectedGender}
    
    The user's questionnaire answers are:
    $answersString
    
    ---
    
    **STEP 1: IMAGE VALIDATION (CRITICAL)**
    Analyze the two images provided:
    1. **Image 1 (Skin):** Must be a human face or skin close-up. If it is an object, animal, blurry, or black screen -> INVALID.
    2. **Image 2 (Scalp):** Must be a human scalp, hair parting, or hair close-up. If it is an object, animal, blurry, or black screen -> INVALID.
    
    **IF IMAGES ARE INVALID:**
    Return ONLY this JSON:
    {
      "isValidImage": false,
      "validationError": "We could not detect a clear skin or scalp image. Please upload correct close-up photos and try again."
    }
    
    **IF IMAGES ARE VALID:**
    Proceed to Step 2.
    
    ---
    
    **STEP 2: GENERATE REPORT**
    Analyze the specific visual symptoms in the images combined with the questionnaire.
    - **Diagnosis:** Be specific based on the visual evidence (e.g., "Androgenic Alopecia", "Cystic Acne").
    - **Products:** Recommend 2-3 realistic products for each kit. Do not use placeholders.
    - **Root Causes:** Deduce causes from the answers + visuals.
    
    Return this JSON structure for a SUCCESSFUL analysis:
    {
      "isValidImage": true,
      "validationError": null,
      "hairDiagnosis": "string",
      "hairTimeline": "string",
      "regrowthPossibility": 100,
      "skinDiagnosis": "string",
      "skinTimeline": "string",
      "totalPrice": "string",
      "discountedTotalPrice": "string",
      "hairRootCauses": [
        {
          "name": "string",
          "iconName": "string_from_flutter_icons",
          "description": "string"
        }
      ],
      "recommendedHairKit": [
        {
          "name": "string",
          "tag": "string_or_empty",
          "description": "string",
          "price": "string",
          "discountedPrice": "string",
          "imageUrl": "string_url_or_asset_path"
        }
      ],
      "skinRootCauses": [
        {
          "name": "string",
          "iconName": "string_from_flutter_icons",
          "description": "string"
        }
      ],
      "recommendedSkinKit": [
        {
          "name": "string",
          "tag": "string_or_empty",
          "description": "string",
          "price": "string",
          "discountedPrice": "string",
          "imageUrl": "string_url_or_asset_path"
        }
      ],
      "freeAddOns": [
        {
          "name": "string",
          "tag": "FREE",
          "description": "string",
          "price": "string",
          "discountedPrice": "FREE",
          "imageUrl": "string_url_or_asset_path"
        }
      ]
    }
    
    RULES:
    1. Output ONLY JSON. No markdown formatting.
    2. For "iconName", use valid Flutter Icons names (e.g., "local_fire_department", "opacity").
    """;
  }
}
