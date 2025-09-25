import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  /// Assigns priority to a report (High, Medium, Low)
  static Future<String> getPriority({
    required String imageUrl, // <-- remote Appwrite URL
    required String description,
    required String category,
    required String city,
    required String address,
  }) async {
    final apiKey = dotenv.env["GEMINI_API_KEY"];
    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=$apiKey";

    try {
      // Step 1: Download image from the given URL
      final imageResponse = await http.get(Uri.parse(imageUrl));
      if (imageResponse.statusCode != 200) {
        throw Exception(
          "Failed to fetch image from URL: ${imageResponse.statusCode}",
        );
      }

      // Step 2: Convert image bytes to base64
      final base64Image = base64Encode(imageResponse.bodyBytes);

      // Step 3: Prepare Gemini request body
      final body = {
        "contents": [
          {
            "parts": [
              {
                "text":
                    "You are an assistant that assigns priority levels to civic issue reports. "
                    "Based on the image, description, category, location, and city, assign ONLY one of: High, Medium, Low. Be strict when setting priorities, if the image is indistinguishable or the description seems like it does not describe the issue, you may set it to Low.",
              },
              {"text": "Category: $category"},
              {"text": "Address: $address"},
              {"text": "Description: $description"},
              {"text": "City: $city"},
              {
                "inline_data": {"mime_type": "image/jpeg", "data": base64Image},
              },
            ],
          },
        ],
      };

      // Step 4: Call Gemini API
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String text =
            data["candidates"][0]["content"]["parts"][0]["text"];
        return text.trim().split(" ")[0];
      } else {
        print("Gemini API Error: ${response.body}");
        return "Medium"; // fallback priority
      }
    } catch (e) {
      print("AI Priority Error: $e");
      return "Medium"; // fallback if error occurs
    }
  }

  /// Validates if the image matches the category and is clear enough
  static Future<bool> validateReport({
    required String imageUrl,
    required String category,
    required String description,
  }) async {
    final apiKey = dotenv.env["GEMINI_API_KEY"];
    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=$apiKey";
    final imageResponse = await http.get(Uri.parse(imageUrl));
    if (imageResponse.statusCode != 200) {
      throw Exception(
        "Failed to fetch image from URL: ${imageResponse.statusCode}",
      );
    }

    final base64Image = base64Encode(imageResponse.bodyBytes);
    final body = {
      "contents": [
        {
          "parts": [
            {
              "text":
                  "You are validating a civic issue report. Don't be lenient and check the following:\n"
                  "1. Does the image mostly show the issue?\n"
                  "2. Does the image content roughly match the selected category?\n"
                  "Return 'VALID' if it reasonably matches, else 'INVALID'. "
                  "Do not be overly strict if the image is slightly unclear or partially obstructed.",
            },
            {"text": "Category: $category"},
            {"text": "Description: $description"},
            {
              "inline_data": {"mime_type": "image/jpeg", "data": base64Image},
            },
          ],
        },
      ],
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data["candidates"][0]["content"]["parts"][0]["text"]
          .toUpperCase();
      return text.contains("VALID");
    } else {
      throw Exception('validationErr');
    }
  }
}
