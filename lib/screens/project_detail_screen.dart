import 'dart:convert'; // for base64Decode
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart' show File;

import '../models/project_model.dart';
import '../services/storage_service.dart';
import '../widgets/full_screen_image_viewer.dart';

class ProjectDetailScreen extends StatelessWidget {
  final ProjectModel project;

  const ProjectDetailScreen({super.key, required this.project});

  Future<void> _deleteProject(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text('This will permanently delete this project and all its images. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService().deleteProject(project.id);
      if (context.mounted) {
        Navigator.pop(context, true); // return true to signal deletion
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        actions: [
          IconButton(
            onPressed: () => _deleteProject(context),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete project',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Generated Variations
            Text('Variations', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: kIsWeb
                  ? (project.generatedImageBase64s?.length ?? 0)
                  : project.generatedImagePaths.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImage(context, index, isGenerated: true),
                );
              },
            ),
            const SizedBox(height: 32),

            // Prompts
            Text('Prompt Used', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: project.prompts.isNotEmpty
                  ? SelectableText(
                      project.prompts.join('\n\n'),
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    )
                  : const Text(
                      'No prompt info',
                      style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black54),
                    ),
            ),
            const SizedBox(height: 32),

            // Input Images
            Text('Input Images', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kIsWeb
                    ? (project.inputImageBase64s?.length ?? 0)
                    : project.inputImagePaths.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: _buildImage(context, index, isGenerated: false),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(
    BuildContext context,
    int index, {
    required bool isGenerated,
  }) {
    if (kIsWeb) {
      final list = isGenerated
          ? project.generatedImageBase64s
          : project.inputImageBase64s;
      if (list != null && index < list.length) {
        final b64 = list[index];
        final bytes = base64Decode(b64);
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenImageViewer(base64Image: b64),
            ),
          ),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
          ),
        );
      }
    } else {
      final list = isGenerated
          ? project.generatedImagePaths
          : project.inputImagePaths;
      if (index < list.length) {
        final path = list[index];
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenImageViewer(imagePath: path),
            ),
          ),
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
          ),
        );
      }
    }
    return const Icon(Icons.image_not_supported);
  }
}
