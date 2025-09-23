import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  /// Assigns priority to a report (High, Medium, Low)
  static Future<String> getPriority({
    required String imageUrl,
    required String description,
    required String category,
    required String city,
  }) async {
    final apiKey = dotenv.env["GEMINI_API_KEY"];
    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=$apiKey";

    final body = {
      "contents": [
        {
          "parts": [
            {
              "text":
                  "You are an assistant that assigns priority levels to civic issue reports. "
                  "Based on the image, description, category, and city, assign ONLY one of: High, Medium, Low.",
            },
            {"text": "Category: $category"},
            {"text": "Description: $description"},
            {"text": "City: $city"},
            {
              "file_data": {"file_uri": imageUrl},
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
      final text = data["candidates"][0]["content"]["parts"][0]["text"];
      return text.trim();
    } else {
      throw Exception("networkIssue");
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

    final body = {
      "contents": [
        {
          "parts": [
            {
              "text":
                  "You are validating a civic issue report. Check the following:\n"
                  "1. Does the image clearly show the issue?\n"
                  "2. Does the image content match the selected category?\n"
                  "3. Ensure that the image is of the real-world scene and not a photo of another device screen.\n"
                  "Return ONLY 'VALID' if all conditions are met, else 'INVALID'.",
            },
            {"text": "Category: $category"},
            {"text": "Description: $description"},
            {
              "file_data": {"file_uri": imageUrl},
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
