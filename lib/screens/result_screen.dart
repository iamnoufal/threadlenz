import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import '../theme/app_theme.dart';
import '../services/image_generation_service.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import 'package:gal/gal.dart';
import '../widgets/full_screen_image_viewer.dart';

class ResultScreen extends StatefulWidget {
  final List<String> generatedPrompts;
  final List<XFile> originalImages; // Changed to List

  const ResultScreen({
    super.key,
    required this.generatedPrompts,
    required this.originalImages,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  String _loadingMessage = 'Initializing...';
  List<Uint8List> _generatedImages = [];

  @override
  void initState() {
    super.initState();
    // If we have prompts, it means we are viewing history or pre-calculated data
    if (widget.generatedPrompts.isNotEmpty && widget.originalImages.isEmpty) {
      // TODO: Handle viewing history (images would need to be loaded from paths)
      // For now, if we have prompts but no images (or images are passed differently logic might differ)
      // But per new flow, we enter with images and NO prompts.
      _isLoading = false;
    } else {
      _startFullWorkflow();
    }
  }

  Future<void> _startFullWorkflow() async {
    try {
      final aiService = AiService();
      aiService.initialize();

      // STEP 1: ANALYSIS
      if (mounted) setState(() => _loadingMessage = 'Analyzing your images...');

      // We use the first image for analysis, or could combine.
      // Assuming we need to analyze to get prompts
      final prompts = await aiService.generatePrompts(
        widget.originalImages.first,
      );

      // STEP 2: GENERATION
      if (mounted)
        setState(() => _loadingMessage = 'Generating your images...');

      final service = ImageGenerationService();
      List<Uint8List> images = await service.generateEditedImages(
        prompts,
        widget.originalImages,
      );

      // STEP 3: SAVE TO HISTORY
      if (mounted) setState(() => _loadingMessage = 'Saving to history...');

      // Convert XFiles to Files for storage - NO, pass XFiles directly now
      // List<File> inputFiles = widget.originalImages
      //    .map((x) => File(x.path))
      //    .toList();

      await StorageService().saveProject(
        prompts: prompts,
        inputImages: widget.originalImages, // Pass XFiles directly
        generatedImageBytes: images,
      );

      if (mounted) {
        setState(() {
          _generatedImages = images;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Workflow Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Masterpieces')),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppTheme.emeraldPrimary,
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  Text(
                    _loadingMessage,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take a few moments',
                    style: TextStyle(
                      color: AppTheme.emeraldPrimary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _generatedImages.length,
              itemBuilder: (context, index) {
                return _buildResultCard(index);
              },
            ),
    );
  }

  Widget _buildResultCard(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImageViewer(
                          imageBytes: _generatedImages[index],
                        ),
                      ),
                    );
                  },
                  child: Image.memory(
                    _generatedImages[index],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Variation ${index + 1}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => _saveImage(index),
                  icon: Icon(
                    Icons.download_rounded,
                    color: AppTheme.emeraldPrimary,
                    size: 24,
                  ),
                  tooltip: 'Save to Gallery',
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (200 * index).ms).slideY(begin: 0.1, end: 0);
  }

  Future<void> _saveImage(int index) async {
    try {
      final bytes = _generatedImages[index];
      if (kIsWeb) {
        // Web Download logic
        // We can't use Gal on web easily without extra setup or checking support
        // Simplest web download: Anchor element
        // But since we can't import universal_html easily without adding dependency
        // We will try Gal, if it fails, we show message.
        // Actually Gal 2.3.0+ supports Web download!
        await Gal.putImageBytes(bytes);
      } else {
        await Gal.putImageBytes(bytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved!'),
            backgroundColor: AppTheme.emeraldPrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
