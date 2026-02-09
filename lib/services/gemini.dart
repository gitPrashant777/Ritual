import 'dart:convert';
import 'package:http/http.dart' as http;

// Import your models
import '../models/assessment_report.dart';
import '../models/onboarding_data.dart';

class GeminiService {
  // Use the v1beta endpoint to access JSON mode
  static const String baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/";

  // REPLACE WITH YOUR ACTUAL API KEY
  final apiKey = "AIzaSyCBjb6puIrMWSbSaL4aEGO3Ndv-IV_JHbE";

  Future<AssessmentReport> getAssessmentFromGemini(OnboardingData data) async {
    // 1. Build the Ayurvedic + Visual Prompt
    final prompt = _buildPrompt(data);

    // 2. Safety Check: Ensure images exist
    if (data.skinImage == null || data.scalpImage == null) {
      throw Exception("Images are missing. Please go back and upload them.");
    }

    // 3. Prepare Image Data (Base64 Encode)
    final skinImageBytes = await data.skinImage!.readAsBytes();
    final skinBase64 = base64Encode(skinImageBytes);

    final scalpImageBytes = await data.scalpImage!.readAsBytes();
    final scalpBase64 = base64Encode(scalpImageBytes);

    // 4. Build the HTTP Request Body
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
        "temperature": 0.05,
        "topK": 20,
        "topP": 0.85,
        'maxOutputTokens': 8192,
        'responseMimeType': "application/json", // Force JSON output
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
      ],
    };

    try {
      // Using gemini-2.5-flash for speed and JSON reliability
      final url = Uri.parse(
          baseUrl + "gemini-2.5-flash:generateContent?key=$apiKey");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final responseData = json.decode(response.body);

        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null) {

          String jsonString =
              responseData['candidates'][0]['content']['parts'][0]['text'] ?? '{}';

          // Decode JSON and map to AssessmentReport
          final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
          return AssessmentReport.fromJson(jsonMap);

        } else {
          throw Exception('Invalid response format from Gemini API');
        }
      } else {
        final errorData = response.body.isNotEmpty ? json.decode(response.body) : {};
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        throw Exception('API Error (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      print("Error in getAssessmentFromGemini: $e");
      rethrow;
    }
  }

  // --- HELPER: Builds the specialized Ayurvedic Prompt ---
  String _buildPrompt(OnboardingData data) {
    // 1. Format Answers
    final answersBuffer = StringBuffer();
    data.answers.forEach((index, answer) {
      if (index < data.questions.length) {
        final question = data.questions[index];
        answersBuffer.writeln("- [${question.heading}] ${question.questionText}");
        answersBuffer.writeln("  User Answer: $answer");
      }
    });

    // 2. Construct Prompt
    return """
    You are an expert Ayurvedic Dermatologist and Trichologist. 
    You are analyzing a patient to determine their **Prakruti (Dosha Profile)** and specific skin/hair conditions.

    **PATIENT DETAILS:**
    - Name: ${data.nameController.text}
    - Age: ${data.ageController.text}
    - Gender: ${data.selectedGender}

    **QUESTIONNAIRE ANSWERS (Look for Vata/Pitta/Kapha patterns):**
    ${answersBuffer.toString()}

    ---
    **TASK 1: IMAGE VALIDATION (CRITICAL)**
    Analyze the two attached images:
    1. **Image 1 (Skin):** Must be a clear human face/skin close-up. If it is an object, animal, dark, or blurry -> INVALID.
    2. **Image 2 (Scalp):** Must be a clear human scalp/hair close-up. If it is an object, animal, dark, or blurry -> INVALID.
    
    If images are invalid, return ONLY: `{"isValidImage": false, "validationError": "We could not detect a clear skin or scalp image."}`

    ---
    **TASK 2: DOSHA & VISUAL DIAGNOSIS**
    1. **Calculate Dominant Dosha:** Scan the "User Answer" text above. Count occurrences of "(Vata)", "(Pitta)", and "(Kapha)". Identify the dominant one.
    2. **Visual Cross-Reference:** Compare the Dosha with the photos.
       - *Vata:* Dryness, thinning, dullness.
       - *Pitta:* Redness, inflammation, receding hairline, sensitivity.
       - *Kapha:* Oiliness, cystic acne, thick/greasy scalp.
    3. **Diagnosis:** - Hair: Specific diagnosis (e.g., "Pitta-Type Premature Thinning", "Telogen Effluvium").
       - Skin: Specific diagnosis (e.g., "Kapha-Type Cystic Acne", "Vata-Type Dry Eczema").

    ---
    **TASK 3: ROOT CAUSES & PRODUCTS**
    1. **Root Causes:** Identify 2-3 root causes from the survey (e.g., "High Stress", "Spicy Diet", "Sleep Deprivation").
    2. **Products:** Recommend generic product types (e.g., "Bhringraj Oil", "Salicylic Acid Face Wash"). Do NOT use fake brand names.

    ---
    **OUTPUT FORMAT (STRICT JSON):**
    {
      "isValidImage": true,
      "validationError": null,
      "hairDiagnosis": "string",
      "hairTimeline": "string (e.g., '3-6 months')",
      "regrowthPossibility": 85,
      "skinDiagnosis": "string",
      "skinTimeline": "string",
      "hairRootCauses": [
        {
          "name": "string (Cause Name)",
          "iconName": "string (Choose one: local_fire_department, water_drop, psychology, bedtime, restaurant, spa)", 
          "description": "string (Short Ayurvedic explanation)"
        }
      ],
      "skinRootCauses": [
        {
          "name": "string",
          "iconName": "string (Choose one: local_fire_department, water_drop, psychology, healing, wb_sunny)",
          "description": "string"
        }
      ],
      "freeAddOns": [
        {
          "name": "Ayurvedic Diet Plan",
          "tag": "FREE",
          "description": "Customized diet to balance your Dosha.",
          "price": "1999",
          "discountedPrice": "FREE",
          "imageUrl": ""
        }
      ]
    }
    """;
  }
}