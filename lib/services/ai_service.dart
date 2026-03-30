import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'image_compression_service.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  late GenerativeModel _model;

  void initialize() {
    // IMPORTANT: In a real app, ensure Firebase.initializeApp() is called before this.
    // The model name 'gemini-1.5-flash' is good for speed/multimodal.
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json', // Force JSON output
      ),
    );
  }

  Future<String> generatePrompt(XFile imageFile) async {
    try {
      final rawBytes = await imageFile.readAsBytes();
      final imageBytes = await ImageCompressionService.compressForApi(rawBytes);
      final content = [
        Content.multi([
          TextPart(
            "You are an expert e-commerce photographer and stylist. "
            "Analyze this image. Identify the product (e.g., saree blouse, baby dress, jewelry). "
            "Create 1 high-quality prompt to place this product in a professional e-commerce setting. "
            "The background should be clean, aesthetic, and suitable for listing on platforms like Amazon/Instagram. "
            "Return a JSON object with a key 'prompt' which is a single string.",
          ),
          InlineDataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await _model.generateContent(content);
      debugPrint("Gemini Response: ${response.text}"); // Verification log

      final jsonResponse = jsonDecode(response.text!) as Map<String, dynamic>;
      if (jsonResponse.containsKey('prompt')) {
        return jsonResponse['prompt'] as String;
      } else {
        throw Exception("Invalid JSON structure: missing 'prompt' key");
      }
    } catch (e) {
      debugPrint("AI Service Error: $e");
      final err = e.toString();
      if (err.contains('403') || err.contains('billing')) {
        throw Exception(
          "Vertex AI Error: Please enable Billing (Blaze Plan) in Firebase Console.",
        );
      }
      if (err.contains('429') ||
          err.contains('Quota') ||
          err.contains('quota')) {
        throw Exception(
          "Quota Exceeded: Too many requests. Please wait a moment and try again.",
        );
      }
      rethrow;
    }
  }
}
