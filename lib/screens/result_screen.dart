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
  final List<XFile> originalImages;

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
  bool _isGeneratingMore = false;
  String _loadingMessage = 'Initializing...';
  String? _errorMessage;
  final List<Uint8List> _generatedImages = [];
  String _basePrompt = '';
  late ImageGenerationService _imageService;
  final TextEditingController _feedbackController = TextEditingController();
  String _accumulatedFeedback = '';
  final List<String> _usedStyles = [];
  String? _projectId;

  int get _generationCount => _generatedImages.length;
  bool get _canGenerateMore =>
      _generationCount < ImageGenerationService.maxGenerations;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _imageService = ImageGenerationService();
    if (widget.generatedPrompts.isNotEmpty && widget.originalImages.isEmpty) {
      _isLoading = false;
    } else {
      _startInitialWorkflow();
    }
  }

  Future<void> _startInitialWorkflow() async {
    try {
      final aiService = AiService();
      aiService.initialize();

      // STEP 1: ANALYSIS
      if (mounted) setState(() => _loadingMessage = 'Analyzing your images...');

      _basePrompt = await aiService.generatePrompt(
        widget.originalImages.first,
      );

      // STEP 2: GENERATE FIRST IMAGE
      if (mounted) {
        setState(() => _loadingMessage = 'Generating your image...');
      }

      final image = await _imageService.generateSingleImage(
        prompt: _basePrompt,
        originalImages: widget.originalImages,
        variationIndex: 0,
        previousStyles: [],
      );

      _generatedImages.add(image);
      _usedStyles.add(ImageGenerationService.getDiversityLabel(0));

      // STEP 3: SAVE TO HISTORY
      if (mounted) setState(() => _loadingMessage = 'Saving to history...');

      try {
        final project = await StorageService().saveProject(
          prompts: [_basePrompt],
          inputImages: widget.originalImages,
          generatedImageBytes: _generatedImages,
        );
        _projectId = project.id;
      } catch (e) {
        debugPrint("Failed to save to history: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Note: Could not save to history (Storage might be full)',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Workflow Failed: $e')));
      }
    }
  }

  Future<void> _generateMore() async {
    if (!_canGenerateMore || _isGeneratingMore) return;

    // Capture and accumulate feedback before generation
    final currentFeedback = _feedbackController.text.trim();
    if (currentFeedback.isNotEmpty) {
      _accumulatedFeedback = _accumulatedFeedback.isEmpty
          ? currentFeedback
          : '$_accumulatedFeedback. $currentFeedback';
      _feedbackController.clear();
    }

    setState(() => _isGeneratingMore = true);

    try {
      final nextIndex = _generationCount;
      var prompt = _basePrompt;

      // Append accumulated feedback to the prompt
      if (_accumulatedFeedback.isNotEmpty) {
        prompt = '$prompt. User feedback to incorporate: $_accumulatedFeedback';
      }

      final image = await _imageService.generateSingleImage(
        prompt: prompt,
        originalImages: widget.originalImages,
        variationIndex: nextIndex,
        previousStyles: _usedStyles,
      );

      _usedStyles.add(ImageGenerationService.getDiversityLabel(nextIndex));

      if (mounted) {
        setState(() {
          _generatedImages.add(image);
          _isGeneratingMore = false;
        });

        // Add new image to existing project
        if (_projectId != null) {
          try {
            await StorageService().addGeneratedImage(
              projectId: _projectId!,
              imageBytes: image,
            );
          } catch (e) {
            debugPrint("Failed to update history: $e");
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingMore = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Generation failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Masterpieces')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.emeraldPrimary),
            const SizedBox(height: 16),
            Text(
              _loadingMessage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few moments',
              style: TextStyle(color: AppTheme.emeraldPrimary.withValues(alpha:0.6)),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _startInitialWorkflow();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_generatedImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No images generated.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
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
        ),
        if (_canGenerateMore) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: TextField(
              controller: _feedbackController,
              decoration: InputDecoration(
                hintText: 'e.g. "Make the background brighter" or "Less shadow"',
                labelText: 'Feedback for next generation (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.emeraldPrimary),
                ),
                prefixIcon: const Icon(Icons.feedback_outlined),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 2,
              minLines: 1,
              textInputAction: TextInputAction.done,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingMore ? null : _generateMore,
                icon: _isGeneratingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isGeneratingMore
                      ? 'Generating...'
                      : 'Generate More ($_generationCount/${ImageGenerationService.maxGenerations})',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldPrimary,
                ),
              ),
            ),
          ),
        ],
        Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, _canGenerateMore ? 12 : 24),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isGeneratingMore ? null : () => Navigator.of(context).popUntil((route) => route.isFirst),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to Home'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.emeraldPrimary,
                side: const BorderSide(color: AppTheme.emeraldPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
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
      await Gal.putImageBytes(bytes);

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
