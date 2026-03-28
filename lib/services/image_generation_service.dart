import 'package:image_picker/image_picker.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class ImageGenerationService {
  static const int maxGenerations = 6;

  static const List<String> _diversityInstructions = [
    "Use soft, diffused natural window lighting. Place the product on a clean white surface with minimal props.",
    "Use dramatic, high-contrast studio lighting with deep shadows. Place the product against a dark, moody backdrop.",
    "Use a clean, minimalist flat-lay composition shot from directly above. Bright, even lighting with a pastel-colored background.",
    "Create a lifestyle scene with the product placed in a realistic in-use context. Warm ambient lighting with complementary decor elements.",
    "Use warm, golden-hour inspired lighting with a cozy, earthy-toned background. Include natural textures like wood or linen.",
    "Create a bold, editorial-style composition with vibrant, saturated colors. Use geometric props or colorful backdrops for a striking look.",
  ];

  Future<Uint8List> generateSingleImage({
    required String prompt,
    required List<XFile> originalImages,
    required int variationIndex,
    List<String> previousStyles = const [],
  }) async {
    try {
      if (originalImages.isEmpty) {
        throw Exception("Missing images");
      }
      if (variationIndex < 0 || variationIndex >= maxGenerations) {
        throw Exception("Invalid variation index");
      }

      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash-image',
        generationConfig: GenerationConfig(
          responseModalities: [
            ResponseModalities.text,
            ResponseModalities.image,
          ],
        ),
      );

      final image = originalImages[variationIndex % originalImages.length];
      final imageBytes = await image.readAsBytes();

      final diversityInstruction = _diversityInstructions[variationIndex];

      // Build an avoidance clause from previous styles
      String avoidClause = '';
      if (previousStyles.isNotEmpty) {
        avoidClause =
            " IMPORTANT: This image must look completely different from previous variations. "
            "Avoid these styles already used: ${previousStyles.join('; ')}. "
            "Use a distinctly different background, lighting, color palette, and composition.";
      }

      final fullPrompt = "$prompt. $diversityInstruction$avoidClause";

      debugPrint("=== Image Generation Request [Variation $variationIndex] ===");
      debugPrint("Full Prompt: $fullPrompt");

      final imagePart = InlineDataPart('image/jpeg', imageBytes);
      final textPart = TextPart(fullPrompt);
      final content = Content.multi([textPart, imagePart]);

      final response = await model.generateContent([content]);

      // Extract image from response
      if (response.inlineDataParts.isNotEmpty) {
        return response.inlineDataParts.first.bytes;
      }

      if (response.candidates.isNotEmpty) {
        for (final candidate in response.candidates) {
          for (final part in candidate.content.parts) {
            if (part is InlineDataPart) {
              return part.bytes;
            }
          }
        }
      }

      throw Exception('No image returned by the model.');
    } catch (e) {
      debugPrint("ImageGenerationService Error: $e");
      final err = e.toString();
      if (err.contains('429') ||
          err.contains('Quota') ||
          err.contains('quota')) {
        throw Exception(
          "Quota Exceeded (Image Model): The AI model is busy. Please wait 60s and try again.",
        );
      }
      rethrow;
    }
  }

  /// Returns the diversity instruction for a given index (used for tracking).
  static String getDiversityLabel(int index) => _diversityInstructions[index];
}
