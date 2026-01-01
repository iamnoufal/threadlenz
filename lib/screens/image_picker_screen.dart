import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/image_upload_card.dart';
import 'result_screen.dart';

class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile?> _images = List.generate(
    4,
    (index) => null,
  ); // Slots for 4 images

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _images[index] = image;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images[index] = null;
    });
  }

  bool get _canProceed => _images.any((img) => img != null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Project')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload Photos',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.emeraldPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add a few angles of your product. The more details, the better the result.',
                  ),
                  const SizedBox(height: 32),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return ImageUploadCard(
                        imageFile: _images[index],
                        label: 'Angle ${index + 1}',
                        onTap: () => _pickImage(index),
                        onRemove: () => _removeImage(index),
                      ).animate().fadeIn(delay: (100 * index).ms).scale();
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canProceed
                    ? () async {
                        setState(() {
                          // Show loading state if needed
                        });

                        try {
                          // Filter out null images
                          final selectedImages = _images
                              .whereType<XFile>()
                              .toList();

                          if (selectedImages.isEmpty) {
                            return; // Should likely be covered by _canProceed
                          }

                          // Initialize Logic
                          // Navigate IMMEDIATELY to ResultScreen with the images.
                          // ResultScreen will handle the analysis and generation.

                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResultScreen(
                                  // No prompts yet, just images
                                  generatedPrompts: const [],
                                  originalImages: selectedImages,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canProceed
                      ? AppTheme.emeraldPrimary
                      : Colors.grey,
                ),
                child: const Text('Generate Magic ✨'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
