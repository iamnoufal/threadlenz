import 'package:image_picker/image_picker.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class ImageGenerationService {
  // This service now uses the Gemini Developer API via firebase_ai
  // to perform image editing (Prompt + Image -> Edited Image).

  Future<List<Uint8List>> generateEditedImages(
    List<String> prompts,
    List<XFile> originalImages,
  ) async {
    try {
      if (prompts.isEmpty || originalImages.isEmpty) {
        throw Exception("Missing prompts or images");
      }

      // Ensure Firebase is initialized
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash-image',
        generationConfig: GenerationConfig(
          responseModalities: [
            ResponseModalities.text,
            ResponseModalities.image,
          ],
        ),
      );

      // Execute 4 requests in parallel.
      // We distribute the input images and prompts across these 4 requests.
      final futures = List.generate(4, (index) async {
        // Round-robin selection of prompt and image
        // e.g. if we have 2 images: req0->img0, req1->img1, req2->img0, req3->img1
        final prompt = prompts[index % prompts.length];
        final image = originalImages[index % originalImages.length];

        final imageBytes = await image.readAsBytes();

        // Add specific instructions to enforce diversity based on the variation index
        String diversityInstruction = "";
        switch (index) {
          case 0:
            diversityInstruction = "Ensure the lighting is soft and natural.";
            break;
          case 1:
            diversityInstruction =
                "Use dramatic, high-contrast studio lighting.";
            break;
          case 2:
            diversityInstruction = "Focus on a clean, minimalist composition.";
            break;
          case 3:
            diversityInstruction =
                "Include subtle lifestyle elements in the background.";
            break;
        }

        final fullPrompt = "$prompt. $diversityInstruction";

        final imagePart = InlineDataPart('image/jpeg', imageBytes);
        final textPart = TextPart(fullPrompt);
        final content = Content.multi([textPart, imagePart]);

        return model.generateContent([content]);
      });

      final responses = await Future.wait(futures);

      final allImages = <Uint8List>[];

      for (final response in responses) {
        // Check inline parts
        if (response.inlineDataParts.isNotEmpty) {
          allImages.addAll(response.inlineDataParts.map((p) => p.bytes));
        }

        // Check candidates
        if (response.candidates.isNotEmpty) {
          for (final candidate in response.candidates) {
            for (final part in candidate.content.parts) {
              if (part is InlineDataPart) {
                bool alreadyAdded = allImages.any(
                  (img) => listEquals(img, part.bytes),
                );
                if (!alreadyAdded) {
                  allImages.add(part.bytes);
                }
              }
            }
          }
        }
      }

      if (allImages.isNotEmpty) {
        return allImages;
      } else {
        debugPrint(
          'Gemini Image Edit: No images were generated from any request.',
        );
        throw Exception('No images returned by the model.');
      }
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
}
