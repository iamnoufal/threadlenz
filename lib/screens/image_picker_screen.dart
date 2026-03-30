import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/image_upload_card.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
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

  Future<void> _pickMultipleImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        // Fill empty slots first, then overwrite from the beginning
        int slotIndex = _images.indexWhere((img) => img == null);
        if (slotIndex == -1) slotIndex = 0;

        for (final image in images) {
          if (slotIndex >= 4) break;
          _images[slotIndex] = image;
          slotIndex++;
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images[index] = null;
    });
  }

  bool get _canProceed => _images.any((img) => img != null);

  Future<void> _onGenerateTapped() async {
    try {
      final selectedImages = _images.whereType<XFile>().toList();
      if (selectedImages.isEmpty) return;

      // Pre-flight token balance check
      final uid = AuthService().currentUser?.uid;
      if (uid != null) {
        final balance = await FirestoreService().getTokenBalance(uid);
        if (balance == 0) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('No Tokens Remaining'),
              content: const Text(
                'You need tokens to generate images. '
                'Please purchase more to continue.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }
        // balance == -1 means Firestore error — allow proceeding,
        // ResultScreen's deductToken will handle it
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            generatedPrompts: const [],
            originalImages: selectedImages,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

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
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickMultipleImages,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Select Multiple Photos'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.emeraldPrimary,
                      side: const BorderSide(color: AppTheme.emeraldPrimary),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                onPressed: _canProceed ? _onGenerateTapped : null,
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
